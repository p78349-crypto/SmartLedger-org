import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/account.dart';
import 'package:smart_ledger/models/asset.dart';
import 'package:smart_ledger/models/asset_move.dart';
import 'package:smart_ledger/models/category_hint.dart';
import 'package:smart_ledger/models/emergency_transaction.dart';
import 'package:smart_ledger/models/fixed_cost.dart';
import 'package:smart_ledger/models/savings_plan.dart';
import 'package:smart_ledger/models/shopping_cart_history_entry.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/models/shopping_template_item.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/models/trash_entry.dart';
import 'package:smart_ledger/services/account_option_service.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/services/asset_move_service.dart';
import 'package:smart_ledger/services/asset_service.dart';
import 'package:smart_ledger/services/budget_service.dart';
import 'package:smart_ledger/services/emergency_fund_service.dart';
import 'package:smart_ledger/services/fixed_cost_service.dart';
import 'package:smart_ledger/services/income_split_service.dart';
import 'package:smart_ledger/services/recent_input_service.dart';
import 'package:smart_ledger/services/savings_plan_service.dart';
import 'package:smart_ledger/services/secure_storage_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/services/trash_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/backup_crypto.dart';
import 'package:smart_ledger/utils/constants.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

enum AutoBackupResult { performed, notNeeded, skippedEncryptionEnabled }

class BackupPreview {
  const BackupPreview({
    required this.sourceAccountName,
    required this.exportedAt,
    required this.lastBackupDate,
    required this.transactionCount,
    required this.assetCount,
    required this.fixedCostCount,
    required this.shoppingCartItemCount,
    required this.savingsPlanCount,
  });

  final String? sourceAccountName;
  final DateTime? exportedAt;
  final DateTime? lastBackupDate;

  final int transactionCount;
  final int assetCount;
  final int fixedCostCount;
  final int shoppingCartItemCount;
  final int savingsPlanCount;
}

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  static const int _backupFormatVersion = 1;

  static const String _secureKeyBackupEncryptionPassword =
      'vccode1_backup_encryption_password_v1';

  bool _autoBackupSkippedByEncryptionNoticeShown = false;
  bool _backupPasswordSetupNoticeShown = false;

  /// Returns true once per app session.
  ///
  /// Used by UI to avoid spamming a repeated message when auto-backup is
  /// skipped due to encryption being enabled.
  bool consumeAutoBackupSkippedByEncryptionNoticeToken() {
    if (_autoBackupSkippedByEncryptionNoticeShown) return false;
    _autoBackupSkippedByEncryptionNoticeShown = true;
    return true;
  }

  /// Returns true once per app session.
  ///
  /// Used by UI to avoid repeatedly prompting for setting a stored backup
  /// password when encryption is enabled.
  bool consumeBackupPasswordSetupNoticeToken() {
    if (_backupPasswordSetupNoticeShown) return false;
    _backupPasswordSetupNoticeShown = true;
    return true;
  }

  Future<String?> getStoredBackupEncryptionPassword() async {
    return SecureStorageService().readString(
      _secureKeyBackupEncryptionPassword,
    );
  }

  Future<void> setStoredBackupEncryptionPassword(String password) async {
    await SecureStorageService().writeString(
      _secureKeyBackupEncryptionPassword,
      password,
    );
  }

  Future<void> clearStoredBackupEncryptionPassword() async {
    await SecureStorageService().delete(_secureKeyBackupEncryptionPassword);
  }

  bool isEncryptedBackupText(String text) {
    return BackupCrypto.isEncryptedEnvelopeText(text);
  }

  BackupPreview parseBackupPreview(String jsonStr) {
    final root = _decodeBackupRootOrThrow(jsonStr);
    _validateBackupShapeOrThrow(root, requireAccountName: false);

    String? sourceAccountName;
    final account = root['account'];
    if (account is Map) {
      final name = account['name'];
      if (name is String && name.trim().isNotEmpty) {
        sourceAccountName = name.trim();
      }
    }

    DateTime? exportedAt;
    DateTime? lastBackupDate;
    final backupMeta = root['backupMeta'];
    if (backupMeta is Map) {
      final rawExportedAt = backupMeta['exportedAt'];
      final rawLastBackupDate = backupMeta['lastBackupDate'];
      if (rawExportedAt is String) {
        exportedAt = DateTime.tryParse(rawExportedAt);
      }
      if (rawLastBackupDate is String) {
        lastBackupDate = DateTime.tryParse(rawLastBackupDate);
      }
    }

    int countList(String key) {
      final value = root[key];
      return value is List ? value.length : 0;
    }

    return BackupPreview(
      sourceAccountName: sourceAccountName,
      exportedAt: exportedAt,
      lastBackupDate: lastBackupDate,
      transactionCount: countList('transactions'),
      assetCount: countList('assets'),
      fixedCostCount: countList('fixedCosts'),
      shoppingCartItemCount: countList('shoppingCartItems'),
      savingsPlanCount: countList('savingsPlans'),
    );
  }

  Map<String, dynamic> _decodeBackupRootOrThrow(String jsonStr) {
    dynamic decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } catch (e) {
      throw Exception('백업 파일이 JSON 형식이 아닙니다: $e');
    }
    if (decoded is! Map) {
      throw Exception('백업 파일 형식이 올바르지 않습니다(최상위가 객체가 아님)');
    }
    return Map<String, dynamic>.from(decoded);
  }

  void _validateBackupShapeOrThrow(
    Map<String, dynamic> data, {
    required bool requireAccountName,
  }) {
    bool isValidListOrAbsent(String key) {
      if (!data.containsKey(key)) return true;
      final value = data[key];
      return value == null || value is List;
    }

    bool isValidMapOrAbsent(String key) {
      if (!data.containsKey(key)) return true;
      final value = data[key];
      return value == null || value is Map;
    }

    // Keys we read as lists.
    const listKeys = <String>[
      'transactions',
      'assets',
      'assetMoves',
      'fixedCosts',
      'emergencyFundTransactions',
      'savingsPlans',
      'trashEntries',
      'shoppingCartItems',
      'shoppingCartHistory',
      'shoppingGroceryTemplateItems',
      'mainPageUiPrefs',
    ];
    for (final key in listKeys) {
      if (!isValidListOrAbsent(key)) {
        throw Exception('백업 파일 형식이 올바르지 않습니다: $key');
      }
    }

    // Keys we read as maps.
    const mapKeys = <String>[
      'account',
      'monthEnd',
      'incomeSplit',
      'backupMeta',
      'globalSettings',
      'favorites',
      'recentInputs',
      'uiState',
      'shoppingCategoryHints',
      'accountOptions',
    ];
    for (final key in mapKeys) {
      if (!isValidMapOrAbsent(key)) {
        throw Exception('백업 파일 형식이 올바르지 않습니다: $key');
      }
    }

    // Ensure this looks like *our* backup, not random JSON.
    final hasAnySignature =
        data.containsKey('transactions') ||
        data.containsKey('assets') ||
        data.containsKey('fixedCosts') ||
        data.containsKey('backupMeta') ||
        data.containsKey('shoppingCartItems');
    if (!hasAnySignature) {
      throw Exception('이 파일은 백업 파일이 아닐 수 있습니다(필수 섹션 누락)');
    }

    if (requireAccountName) {
      final account = data['account'];
      if (account is! Map) {
        throw Exception('백업 파일에 account 정보가 없습니다');
      }
      final name = account['name'];
      if (name is! String || name.trim().isEmpty) {
        throw Exception('백업 파일에 account.name 정보가 없습니다');
      }
    }
  }

  /// Result of attempting an automatic backup.
  ///
  /// Note: when encryption is enabled but no stored password exists,
  /// auto-backup proceeds as a plaintext backup.

  // 계정별 마지막 백업 날짜 저장 (SharedPreferences 사용)
  Future<DateTime?> getLastBackupDate(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    final key = PrefKeys.accountKey(accountName, 'lastBackup');
    final millis = prefs.getInt(key);
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastBackupDate(String accountName, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final key = PrefKeys.accountKey(accountName, 'lastBackup');
    await prefs.setInt(key, date.millisecondsSinceEpoch);
  }

  // 자동 백업 트리거 (앱 시작 시 호출)
  Future<AutoBackupResult> autoBackupIfNeeded(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    final encryptionEnabled =
        prefs.getBool(PrefKeys.backupEncryptionEnabled) ?? false;
    String? encryptionPassword;
    if (encryptionEnabled) {
      // If encryption is enabled, encrypt only when a stored password exists.
      // Otherwise proceed with plaintext backup.
      encryptionPassword = await getStoredBackupEncryptionPassword();
      if (encryptionPassword != null && encryptionPassword.trim().isEmpty) {
        encryptionPassword = null;
      }
    }

    await AccountService().loadAccounts();
    await TransactionService().loadTransactions();
    await AssetService().loadAssets();
    await FixedCostService().loadFixedCosts();
    final now = DateTime.now();
    final last = await getLastBackupDate(accountName);
    final isFirstDay = now.day == 1;
    final needWeekly = last == null || now.difference(last).inDays >= 7;
    final needMonthly =
        last == null ||
        (isFirstDay && (last.month != now.month || last.year != now.year));
    if (needWeekly || needMonthly) {
      final year = now.year.toString();
      final month = now.month.toString().padLeft(2, '0');
      final day = now.day.toString().padLeft(2, '0');
      final dateStr = '$year$month$day';
      final fileName = '${accountName}_${dateStr}_auto.json';
      // Use a safe file name and delegate to file saving
      await saveBackupToFile(
        accountName,
        fileName,
        encryptionPassword: encryptionPassword,
      );
      return AutoBackupResult.performed;
    }

    return AutoBackupResult.notNeeded;
  }

  Future<File?> pickBackupFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    return File(result.files.single.path!);
  }

  Future<String> readBackupFileAsJson({
    required File file,
    String? password,
  }) async {
    // ignore: avoid_slow_async_io
    final text = await file.readAsString();
    if (!BackupCrypto.isEncryptedEnvelopeText(text)) {
      return text;
    }
    if (password == null || password.trim().isEmpty) {
      throw Exception('암호화 백업입니다. 백업 암호가 필요합니다.');
    }
    return BackupCrypto.decryptJsonEnvelope(
      encryptedEnvelopeJson: text,
      password: password,
    );
  }

  Future<String> exportAccountData(String accountName) async {
    await AccountService().loadAccounts();
    await TransactionService().loadTransactions();
    await AssetService().loadAssets();
    await AssetMoveService().loadMoves();
    await FixedCostService().loadFixedCosts();
    await BudgetService().loadBudgets();
    await EmergencyFundService().ensureLoaded();
    await IncomeSplitService().loadSplits();
    await SavingsPlanService().loadPlans();
    await TrashService().loadEntries();
    final account = AccountService().getAccountByName(accountName);
    final transactions = TransactionService().getTransactions(accountName);
    final assets = AssetService().getAssets(accountName);
    final assetMoves = AssetMoveService().getMoves(accountName);
    final fixedCosts = FixedCostService().getFixedCosts(accountName);
    final budget = BudgetService().getBudget(accountName);
    final emergencyTransactions = EmergencyFundService().getTransactions(
      accountName,
    );
    final incomeSplit = IncomeSplitService().getSplit(accountName);
    final savingsPlans = SavingsPlanService().getPlans(accountName);
    final trashEntries = TrashService().getEntries(accountName: accountName);
    final shoppingCartItems = await UserPrefService.getShoppingCartItems(
      accountName: accountName,
    );
    final shoppingCartHistory = await UserPrefService.getShoppingCartHistory(
      accountName: accountName,
    );
    final shoppingGroceryTemplateItems =
        await UserPrefService.getShoppingGroceryTemplateItems(
          accountName: accountName,
        );
    final shoppingCategoryHints =
        await UserPrefService.getShoppingCategoryHints(
          accountName: accountName,
        );
    final mainPageUiPrefs = await UserPrefService.exportMainPageUiPrefsSnapshot(
      accountName: accountName,
    );
    final accountOptions = await AccountOptionService.exportOptions(
      accountName,
    );
    final recentMemos = await RecentInputService.loadMemos();
    final recentPaymentMethods = await RecentInputService.loadPaymentMethods();
    final recentCategories = await RecentInputService.loadCategories();
    final lastAccountName = await UserPrefService.getLastAccountName();
    final lastBackupDate = await getLastBackupDate(accountName);

    final prefs = await SharedPreferences.getInstance();
    final favorites = _exportFavoritesSnapshot(prefs, accountName);
    final globalSettings = <String, dynamic>{};
    for (final key in PrefKeys.settingKeys) {
      if (!prefs.containsKey(key)) continue;
      final stringValue = prefs.getString(key);
      if (stringValue != null) {
        globalSettings[key] = stringValue;
        continue;
      }
      final boolValue = prefs.getBool(key);
      if (boolValue != null) {
        globalSettings[key] = boolValue;
        continue;
      }
      final intValue = prefs.getInt(key);
      if (intValue != null) {
        globalSettings[key] = intValue;
        continue;
      }
      final doubleValue = prefs.getDouble(key);
      if (doubleValue != null) {
        globalSettings[key] = doubleValue;
        continue;
      }
      final stringListValue = prefs.getStringList(key);
      if (stringListValue != null) {
        globalSettings[key] = stringListValue;
        continue;
      }
    }

    final now = DateTime.now();
    final data = {
      'account': {
        'name': account?.name,
        'createdAt': account?.createdAt.toIso8601String(),
      },
      'monthEnd': <String, dynamic>{
        'carryoverAmount': account?.carryoverAmount ?? 0,
        'overdraftAmount': account?.overdraftAmount ?? 0,
        'lastCarryoverDate': account?.lastCarryoverDate?.toIso8601String(),
      },
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'assets': assets.map((a) => a.toJson()).toList(),
      'assetMoves': assetMoves.map((m) => m.toJson()).toList(),
      'fixedCosts': fixedCosts.map((c) => c.toJson()).toList(),
      'budget': budget,
      'emergencyFundTransactions': emergencyTransactions
          .map((t) => t.toJson())
          .toList(),
      'incomeSplit': incomeSplit?.toJson(),
      'savingsPlans': savingsPlans.map((p) => p.toJson()).toList(),
      'trashEntries': trashEntries.map((e) => e.toJson()).toList(),
      'shoppingCartItems': shoppingCartItems
          .map((i) => i.toJson())
          .toList(growable: false),
      'shoppingCartHistory': shoppingCartHistory
          .map((e) => e.toJson())
          .toList(growable: false),
      'shoppingGroceryTemplateItems': shoppingGroceryTemplateItems
          .map((i) => i.toJson())
          .toList(growable: false),
      'shoppingCategoryHints': <String, dynamic>{
        for (final e in shoppingCategoryHints.entries) e.key: e.value.toJson(),
      },
      'mainPageUiPrefs': mainPageUiPrefs,
      'accountOptions': accountOptions,
      'recentInputs': <String, dynamic>{
        'memos': recentMemos,
        'paymentMethods': recentPaymentMethods,
        'categories': recentCategories,
      },
      'favorites': favorites,
      'uiState': <String, dynamic>{'lastAccountName': lastAccountName},
      'backupMeta': <String, dynamic>{
        'lastBackupDate': lastBackupDate?.toIso8601String(),
        'exportedAt': now.toIso8601String(),
        'backupFormatVersion': _backupFormatVersion,
      },
      'globalSettings': globalSettings,
    };
    return jsonEncode(data);
  }

  Future<void> _writeFileAtomically(File destination, String content) async {
    await destination.parent.create(recursive: true);
    final tmp = File(
      '${destination.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );

    // ignore: avoid_slow_async_io
    await tmp.writeAsString(content, flush: true);

    // ignore: avoid_slow_async_io
    if (await destination.exists()) {
      // ignore: avoid_slow_async_io
      await destination.delete();
    }

    // ignore: avoid_slow_async_io
    await tmp.rename(destination.path);
  }

  /// Downloads 폴더에 백업 저장
  Future<String> saveBackupToDownloads(
    String accountName, {
    String? encryptionPassword,
  }) async {
    // Android 버전별 권한 요청
    bool hasPermission = false;

    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();

      if (androidInfo >= 33) {
        // Android 13+ (API 33+): 특정 권한 불필요, 직접 접근 가능
        hasPermission = true;
      } else if (androidInfo >= 30) {
        // Android 11-12 (API 30-32): MANAGE_EXTERNAL_STORAGE 또는 일반 저장소 권한
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        hasPermission = status.isGranted;
      } else {
        // Android 10 이하: 일반 저장소 권한
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        hasPermission = status.isGranted;
      }
    } else {
      hasPermission = true; // iOS는 권한 불필요
    }

    var json = await exportAccountData(accountName);
    if (encryptionPassword != null && encryptionPassword.trim().isNotEmpty) {
      json = await BackupCrypto.encryptJsonPayload(
        plainJson: json,
        password: encryptionPassword,
      );
    }
    final now = DateTime.now();
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final ss = now.second.toString().padLeft(2, '0');
    final fileName = '${accountName}_$y$m${d}_$hh$mm$ss.json';

    // Attempt Downloads first on Android when permission is available.
    // Fallback: app documents folder (always works, but removed on uninstall).
    // ignore: avoid_slow_async_io
    final appDir = await getApplicationDocumentsDirectory();
    final safeDir = Directory(
      '${appDir.path}/${AppConstants.backupDownloadsFolderName}',
    );

    Directory? primaryDir;
    if (Platform.isAndroid && hasPermission) {
      primaryDir = Directory(
        '/storage/emulated/0/Download/'
        '${AppConstants.backupDownloadsFolderName}',
      );
    }

    Future<String> writeTo(Directory dir) async {
      final file = File('${dir.path}/$fileName');
      await _writeFileAtomically(file, json);
      await setLastBackupDate(accountName, DateTime.now());
      return file.path;
    }

    if (primaryDir != null) {
      try {
        return await writeTo(primaryDir);
      } catch (_) {
        // Fall through to safe dir.
      }
    }

    return writeTo(safeDir);
  }

  /// 긴급용: Downloads 폴더에 "최신 1개"로 덮어쓰는 백업 저장
  Future<String> saveEmergencyBackupToDownloads(
    String accountName, {
    String? encryptionPassword,
  }) async {
    // 권한/저장 위치 정책은 일반 Downloads 저장과 동일하게 유지
    bool hasPermission = false;

    if (Platform.isAndroid) {
      final androidInfo = await _getAndroidVersion();

      if (androidInfo >= 33) {
        hasPermission = true;
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        hasPermission = status.isGranted;
      }
    } else {
      hasPermission = true;
    }

    var json = await exportAccountData(accountName);
    if (encryptionPassword != null && encryptionPassword.trim().isNotEmpty) {
      json = await BackupCrypto.encryptJsonPayload(
        plainJson: json,
        password: encryptionPassword,
      );
    }
    const suffix = '_latest.json';
    final fileName = '$accountName$suffix';

    // ignore: avoid_slow_async_io
    final appDir = await getApplicationDocumentsDirectory();
    final safeDir = Directory(
      '${appDir.path}/${AppConstants.backupDownloadsFolderName}',
    );

    Directory? primaryDir;
    if (Platform.isAndroid && hasPermission) {
      primaryDir = Directory(
        '/storage/emulated/0/Download/'
        '${AppConstants.backupDownloadsFolderName}',
      );
    }

    Future<String> writeTo(Directory dir) async {
      final file = File('${dir.path}/$fileName');
      await _writeFileAtomically(file, json);
      await setLastBackupDate(accountName, DateTime.now());
      return file.path;
    }

    if (primaryDir != null) {
      try {
        return await writeTo(primaryDir);
      } catch (_) {
        // Fall through to safe dir.
      }
    }

    return writeTo(safeDir);
  }

  Future<int> _getAndroidVersion() async {
    if (!Platform.isAndroid) return 0;

    try {
      // Android SDK 버전 확인 (간단한 방법)
      final androidInfo = await Permission.storage.status;
      // Android 13+에서는 storage 권한이 deprecated되어 denied 상태
      if (androidInfo.isDenied || androidInfo.isPermanentlyDenied) {
        return 33; // Android 13+로 가정
      }
      return 30; // Android 11-12로 가정
    } catch (e) {
      return 33; // 오류 시 최신 버전으로 가정
    }
  }

  /// 이메일로 백업 공유
  /// 이메일로 백업 공유
  Future<void> shareBackupViaEmail(
    String accountName, {
    String? encryptionPassword,
  }) async {
    final filePath = await saveBackupToDownloads(
      accountName,
      encryptionPassword: encryptionPassword,
    );
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: '$accountName 백업 파일',
      text: 'SmartLedger 백업 파일입니다.',
    );
  }

  /// 외부 스토리지로 백업 공유 (Google Drive 등)
  Future<void> shareBackupToCloud(
    String accountName, {
    String? encryptionPassword,
  }) async {
    final filePath = await saveBackupToDownloads(
      accountName,
      encryptionPassword: encryptionPassword,
    );
    await Share.shareXFiles([XFile(filePath)], subject: '$accountName 백업 파일');
  }

  /// 범용 공유/내보내기: 설치된 앱(Drive/네이버클라우드/메일/메신저 등)에서 선택
  Future<void> shareBackup(
    String accountName, {
    String? encryptionPassword,
  }) async {
    final filePath = await saveBackupToDownloads(
      accountName,
      encryptionPassword: encryptionPassword,
    );
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: '$accountName 백업 파일',
      text: 'SmartLedger 백업 파일입니다.',
    );
  }

  /// 이메일 작성 화면을 직접 열어 전송(수신자 자동 입력 가능)
  Future<void> composeEmailWithBackup(
    String accountName, {
    String? encryptionPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final to = prefs.getString(PrefKeys.backupRegisteredEmail);
    // Keep a local backup file as well (timestamped) for safety.
    final filePath = await saveBackupToDownloads(
      accountName,
      encryptionPassword: encryptionPassword,
    );

    final email = Email(
      subject: '$accountName 백업 파일',
      body: 'SmartLedger 백업 파일입니다.',
      recipients: (to == null || to.trim().isEmpty) ? [] : [to.trim()],
      attachmentPaths: [filePath],
      isHTML: false,
    );

    await FlutterEmailSender.send(email);
  }

  Future<String> saveBackupToFile(
    String accountName,
    String fileNameOrPath, {
    String? encryptionPassword,
  }) async {
    var json = await exportAccountData(accountName);
    if (encryptionPassword != null && encryptionPassword.trim().isNotEmpty) {
      json = await BackupCrypto.encryptJsonPayload(
        plainJson: json,
        password: encryptionPassword,
      );
    }
    final file = await _resolveBackupFile(fileNameOrPath);
    await _writeFileAtomically(file, json);
    await setLastBackupDate(accountName, DateTime.now());
    return file.path;
  }

  /// 파일 선택하여 복원 (새 계정 생성)
  Future<String?> restoreFromFile(String newAccountName) async {
    try {
      final file = await pickBackupFile();
      if (file == null) return null;

      // This path is kept for backward compatibility with older callers.
      // Encrypted backups require a password prompt in UI, so they must be
      // handled by BackupScreen.
      // ignore: avoid_slow_async_io
      final jsonStr = await file.readAsString();

      await importAccountDataAsNew(jsonStr, newAccountName);
      return newAccountName;
    } catch (e) {
      throw Exception('복원 실패: $e');
    }
  }

  /// 새 계정으로 데이터 복원 (기존 데이터 보존)
  Future<void> importAccountDataAsNew(
    String jsonStr,
    String newAccountName,
  ) async {
    await AccountService().loadAccounts();
    await TransactionService().loadTransactions();
    await AssetService().loadAssets();
    await AssetMoveService().loadMoves();
    await FixedCostService().loadFixedCosts();
    await BudgetService().loadBudgets();
    await EmergencyFundService().ensureLoaded();
    await IncomeSplitService().loadSplits();
    await SavingsPlanService().loadPlans();
    await TrashService().loadEntries();

    final root = _decodeBackupRootOrThrow(jsonStr);
    _validateBackupShapeOrThrow(root, requireAccountName: false);
    final data = root;

    // 새 계정 생성
    DateTime? createdAt;
    final accountJson = data['account'];
    if (accountJson is Map) {
      final rawCreatedAt = accountJson['createdAt'];
      if (rawCreatedAt is String) {
        createdAt = DateTime.tryParse(rawCreatedAt);
      }
    }

    final account = Account(name: newAccountName, createdAt: createdAt);
    final existing = AccountService().getAccountByName(newAccountName);
    if (existing != null) {
      throw Exception('이미 존재하는 계정명입니다');
    }
    await AccountService().addAccount(account);

    // Ensure the newly restored account is selected.
    await UserPrefService.setLastAccountName(newAccountName);

    // Restore backup metadata (optional).
    final backupMeta = data['backupMeta'];
    if (backupMeta is Map) {
      final rawDate = backupMeta['lastBackupDate'];
      final parsed = rawDate is String ? DateTime.tryParse(rawDate) : null;
      if (parsed != null) {
        await setLastBackupDate(newAccountName, parsed);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(PrefKeys.accountKey(newAccountName, 'lastBackup'));
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(PrefKeys.accountKey(newAccountName, 'lastBackup'));
    }

    final monthEnd = data['monthEnd'];
    if (monthEnd is Map) {
      final carryoverAmount =
          (monthEnd['carryoverAmount'] as num?)?.toDouble() ?? 0;
      final overdraftAmount =
          (monthEnd['overdraftAmount'] as num?)?.toDouble() ?? 0;
      final rawDate = monthEnd['lastCarryoverDate'];
      final lastCarryoverDate = rawDate is String
          ? DateTime.tryParse(rawDate)
          : null;
      await AccountService().restoreMonthEndSnapshot(
        newAccountName,
        carryoverAmount: carryoverAmount,
        overdraftAmount: overdraftAmount,
        lastCarryoverDate: lastCarryoverDate,
      );
    } else {
      await AccountService().clearMonthEndSnapshot(newAccountName);
    }

    // 거래 내역 복원
    final txList = (data['transactions'] as List<dynamic>? ?? [])
        .map((t) => Transaction.fromJson(t as Map<String, dynamic>))
        .toList();
    for (final t in txList) {
      await TransactionService().addTransaction(newAccountName, t);
    }

    // 자산 복원
    final assetList = (data['assets'] as List<dynamic>? ?? [])
        .map((a) => Asset.fromJson(a as Map<String, dynamic>))
        .toList();
    await AssetService().replaceAssets(newAccountName, assetList);

    // 자산 이동(타임라인) 복원 (하위 호환: 키가 없으면 빈 리스트)
    final assetMoveList = (data['assetMoves'] as List<dynamic>? ?? [])
        .map((m) => AssetMove.fromJson(m as Map<String, dynamic>))
        .toList();
    await AssetMoveService().replaceMoves(newAccountName, assetMoveList);

    // 고정비 복원
    final fixedCostList = (data['fixedCosts'] as List<dynamic>? ?? [])
        .map((c) => FixedCost.fromJson(c as Map<String, dynamic>))
        .toList();
    await FixedCostService().replaceFixedCosts(newAccountName, fixedCostList);

    // 예산 복원
    final budgetValue = (data['budget'] as num?)?.toDouble() ?? 0;
    if (budgetValue > 0) {
      await BudgetService().setBudget(newAccountName, budgetValue);
    }

    // 비상금 복원 (하위 호환: 키가 없으면 빈 리스트)
    final emergencyList =
        (data['emergencyFundTransactions'] as List<dynamic>? ?? [])
            .map(
              (t) => EmergencyTransaction.fromJson(t as Map<String, dynamic>),
            )
            .toList();
    await EmergencyFundService().replaceTransactions(
      newAccountName,
      emergencyList,
    );

    final incomeSplitJson = data['incomeSplit'];
    final incomeSplit = incomeSplitJson is Map<String, dynamic>
        ? IncomeSplit.fromJson(incomeSplitJson)
        : null;
    await IncomeSplitService().replaceSplit(newAccountName, incomeSplit);

    // 예금계획 복원 (하위 호환: 키가 없으면 빈 리스트)
    final savingsPlanList = (data['savingsPlans'] as List<dynamic>? ?? [])
        .map((p) => SavingsPlan.fromJson(p as Map<String, dynamic>))
        .toList();
    await SavingsPlanService().replacePlans(newAccountName, savingsPlanList);

    // 휴지통 복원 (하위 호환: 키가 없으면 빈 리스트)
    final trashList = (data['trashEntries'] as List<dynamic>? ?? [])
        .map((e) => TrashEntry.fromJson(e as Map<String, dynamic>))
        .map((entry) {
          final updatedPayload = Map<String, dynamic>.from(entry.payload);
          if (updatedPayload.containsKey('accountName')) {
            updatedPayload['accountName'] = newAccountName;
          }
          return TrashEntry.forPayload(
            id: entry.id,
            entityId: entry.entityId,
            accountName: newAccountName,
            entityType: entry.entityType,
            payload: updatedPayload,
            deletedAt: entry.deletedAt,
          );
        })
        .toList();
    await TrashService().replaceAccountEntries(newAccountName, trashList);

    final cartItems = (data['shoppingCartItems'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ShoppingCartItem.fromJson)
        .toList(growable: false);
    await UserPrefService.setShoppingCartItems(
      accountName: newAccountName,
      items: cartItems,
    );

    final cartHistory = (data['shoppingCartHistory'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ShoppingCartHistoryEntry.fromJson)
        .toList(growable: false);
    await UserPrefService.setShoppingCartHistory(
      accountName: newAccountName,
      entries: cartHistory,
    );

    final groceryTemplateItems =
        (data['shoppingGroceryTemplateItems'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(ShoppingTemplateItem.fromJson)
            .toList(growable: false);
    await UserPrefService.setShoppingGroceryTemplateItems(
      accountName: newAccountName,
      items: groceryTemplateItems,
    );

    final hintsRaw = data['shoppingCategoryHints'];
    final hints = <String, CategoryHint>{};
    if (hintsRaw is Map) {
      for (final entry in hintsRaw.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || value is! Map) continue;
        hints[key] = CategoryHint.fromJson(Map<String, dynamic>.from(value));
      }
    }
    await UserPrefService.setShoppingCategoryHints(
      accountName: newAccountName,
      hints: hints,
    );

    final mainPageUiPrefsSnapshot =
        data['mainPageUiPrefs'] as List<dynamic>? ?? const [];
    await UserPrefService.importMainPageUiPrefsSnapshot(
      accountName: newAccountName,
      snapshot: mainPageUiPrefsSnapshot,
    );

    final accountOptionsRaw = data['accountOptions'];
    if (accountOptionsRaw is Map) {
      await AccountOptionService.importOptions(
        newAccountName,
        Map<String, dynamic>.from(accountOptionsRaw),
      );
    } else {
      await AccountOptionService.importOptions(newAccountName, const {});
    }

    final recentInputs = data['recentInputs'];
    if (recentInputs is Map) {
      final memos = recentInputs['memos'];
      if (memos is List) {
        await RecentInputService.replaceValues(
          PrefKeys.recentMemos,
          memos.map((e) => e.toString()).toList(growable: false),
        );
      } else {
        await RecentInputService.clearValues(PrefKeys.recentMemos);
      }

      final paymentMethods = recentInputs['paymentMethods'];
      if (paymentMethods is List) {
        await RecentInputService.replaceValues(
          PrefKeys.recentPaymentMethods,
          paymentMethods.map((e) => e.toString()).toList(growable: false),
        );
      } else {
        await RecentInputService.clearValues(PrefKeys.recentPaymentMethods);
      }

      final categories = recentInputs['categories'];
      if (categories is List) {
        await RecentInputService.replaceValues(
          PrefKeys.recentCategories,
          categories.map((e) => e.toString()).toList(growable: false),
        );
      } else {
        await RecentInputService.clearValues(PrefKeys.recentCategories);
      }
    } else {
      await RecentInputService.clearValues(PrefKeys.recentMemos);
      await RecentInputService.clearValues(PrefKeys.recentPaymentMethods);
      await RecentInputService.clearValues(PrefKeys.recentCategories);
    }

    await _importFavoritesSnapshot(
      accountName: newAccountName,
      rawSnapshot: data['favorites'],
    );

    final globalSettings = data['globalSettings'];
    final gs = globalSettings is Map
        ? Map<String, dynamic>.from(globalSettings)
        : null;
    final prefs = await SharedPreferences.getInstance();
    for (final key in PrefKeys.settingKeys) {
      if (gs != null && gs.containsKey(key)) {
        final value = gs[key];
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is List) {
          await prefs.setStringList(
            key,
            value.map((e) => e.toString()).toList(growable: false),
          );
        } else {
          await prefs.remove(key);
        }
      } else {
        await prefs.remove(key);
      }
    }
  }

  Future<File> _resolveBackupFile(String fileNameOrPath) async {
    final candidate = File(fileNameOrPath);
    if (candidate.isAbsolute) {
      return candidate;
    }
    // Rationale: Locating application documents directory requires platform
    // access and is async; we perform it async to avoid main thread blocking.
    // ignore: avoid_slow_async_io
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}${Platform.pathSeparator}$fileNameOrPath');
  }

  Map<String, dynamic> _exportFavoritesSnapshot(
    SharedPreferences prefs,
    String accountName,
  ) {
    final descriptions = <String, List<String>>{};
    final memos = <String, List<String>>{};
    final payments = <String, List<String>>{};

    final legacyDescriptionsKey =
        '${AppConstants.favoriteDescriptionsKeyPrefix}_$accountName';
    final legacyMemosKey =
        '${AppConstants.favoriteMemosKeyPrefix}_$accountName';
    final legacyPaymentsKey =
        '${AppConstants.favoritePaymentsKeyPrefix}_$accountName';

    for (final type in TransactionType.values) {
      final typeName = type.name;

      final descriptionsKey =
          '${AppConstants.favoriteDescriptionsKeyPrefix}_'
          '${accountName}_$typeName';
      descriptions[typeName] = _readFavoritesWithLegacyFallback(
        prefs,
        newKey: descriptionsKey,
        legacyKey: legacyDescriptionsKey,
      );

      final memosKey =
          '${AppConstants.favoriteMemosKeyPrefix}_'
          '${accountName}_$typeName';
      memos[typeName] = _readFavoritesWithLegacyFallback(
        prefs,
        newKey: memosKey,
        legacyKey: legacyMemosKey,
      );

      if (type == TransactionType.savings) {
        payments[typeName] = const <String>[];
        continue;
      }
      final paymentsKey =
          '${AppConstants.favoritePaymentsKeyPrefix}_'
          '${accountName}_$typeName';
      payments[typeName] = _readFavoritesWithLegacyFallback(
        prefs,
        newKey: paymentsKey,
        legacyKey: legacyPaymentsKey,
      );
    }

    return <String, dynamic>{
      'descriptions': descriptions,
      'memos': memos,
      'payments': payments,
    };
  }

  List<String> _readFavoritesWithLegacyFallback(
    SharedPreferences prefs, {
    required String newKey,
    required String legacyKey,
  }) {
    final current = prefs.getStringList(newKey);
    if (current != null && current.isNotEmpty) {
      return List<String>.from(current);
    }
    final legacy = prefs.getStringList(legacyKey);
    if (legacy != null && legacy.isNotEmpty) {
      return List<String>.from(legacy);
    }
    return const <String>[];
  }

  Future<void> _importFavoritesSnapshot({
    required String accountName,
    required dynamic rawSnapshot,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    Future<void> clearAll() async {
      await prefs.remove(
        '${AppConstants.favoriteDescriptionsKeyPrefix}_$accountName',
      );
      await prefs.remove('${AppConstants.favoriteMemosKeyPrefix}_$accountName');
      await prefs.remove(
        '${AppConstants.favoritePaymentsKeyPrefix}_$accountName',
      );

      for (final type in TransactionType.values) {
        final typeName = type.name;

        final descriptionsKey =
            '${AppConstants.favoriteDescriptionsKeyPrefix}_'
            '${accountName}_$typeName';
        final memosKey =
            '${AppConstants.favoriteMemosKeyPrefix}_'
            '${accountName}_$typeName';
        final paymentsKey =
            '${AppConstants.favoritePaymentsKeyPrefix}_'
            '${accountName}_$typeName';

        await prefs.remove(descriptionsKey);
        await prefs.remove(memosKey);
        await prefs.remove(paymentsKey);
      }
    }

    if (rawSnapshot is! Map) {
      await clearAll();
      return;
    }

    final snapshot = Map<String, dynamic>.from(rawSnapshot);
    final rawDescriptions = snapshot['descriptions'];
    final rawMemos = snapshot['memos'];
    final rawPayments = snapshot['payments'];

    List<String> readListFrom(dynamic mapLike, String typeName) {
      if (mapLike is! Map) return const <String>[];
      final value = mapLike[typeName];
      if (value is! List) return const <String>[];
      return value.map((e) => e.toString()).toList(growable: false);
    }

    // Always remove legacy keys; we only restore the per-type keys.
    await prefs.remove(
      '${AppConstants.favoriteDescriptionsKeyPrefix}_$accountName',
    );
    await prefs.remove('${AppConstants.favoriteMemosKeyPrefix}_$accountName');
    await prefs.remove(
      '${AppConstants.favoritePaymentsKeyPrefix}_$accountName',
    );

    for (final type in TransactionType.values) {
      final typeName = type.name;

      final descriptionsKey =
          '${AppConstants.favoriteDescriptionsKeyPrefix}_'
          '${accountName}_$typeName';
      final memosKey =
          '${AppConstants.favoriteMemosKeyPrefix}_'
          '${accountName}_$typeName';
      final paymentsKey =
          '${AppConstants.favoritePaymentsKeyPrefix}_'
          '${accountName}_$typeName';

      final descriptions = readListFrom(rawDescriptions, typeName);
      final memos = readListFrom(rawMemos, typeName);
      final payments = readListFrom(rawPayments, typeName);

      if (descriptions.isEmpty) {
        await prefs.remove(descriptionsKey);
      } else {
        await prefs.setStringList(descriptionsKey, descriptions);
      }

      if (memos.isEmpty) {
        await prefs.remove(memosKey);
      } else {
        await prefs.setStringList(memosKey, memos);
      }

      if (type == TransactionType.savings || payments.isEmpty) {
        await prefs.remove(paymentsKey);
      } else {
        await prefs.setStringList(paymentsKey, payments);
      }
    }
  }
}

