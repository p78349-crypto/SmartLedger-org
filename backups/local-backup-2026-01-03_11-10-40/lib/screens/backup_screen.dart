import 'dart:io';

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/_verify_current_user_password_dialog.dart';
import 'package:smart_ledger/screens/_verify_current_user_pin_dialog.dart';
import 'package:smart_ledger/services/auth_service.dart';
import 'package:smart_ledger/services/backup_service.dart';
import 'package:smart_ledger/services/user_password_service.dart';
import 'package:smart_ledger/services/user_pin_service.dart';
import 'package:smart_ledger/utils/account_name_language_tag.dart';
import 'package:smart_ledger/utils/constants.dart';
import 'package:smart_ledger/utils/date_formats.dart';
import 'package:smart_ledger/utils/dialog_utils.dart';
import 'package:smart_ledger/utils/pref_keys.dart';
import 'package:smart_ledger/utils/snackbar_utils.dart';
import 'package:smart_ledger/widgets/state_placeholders.dart';

class BackupScreen extends StatefulWidget {
  final String accountName;
  const BackupScreen({super.key, required this.accountName});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupFileInfo {
  const _BackupFileInfo({
    required this.file,
    required this.fileName,
    required this.modified,
    required this.sizeInKb,
  });

  final File file;
  final String fileName;
  final DateTime modified;
  final String sizeInKb;
}

enum _BackupAuthChoice { biometric, pin, password, exit }

class _BackupAuthChoiceDialog extends StatelessWidget {
  const _BackupAuthChoiceDialog({
    required this.canPin,
    required this.canPassword,
    required this.canBiometric,
  });

  final bool canPin;
  final bool canPassword;
  final bool canBiometric;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('백업 보호 인증'),
      content: const Text('사용할 인증 방법을 선택하세요.'),
      actions: [
        if (canBiometric)
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_BackupAuthChoice.biometric),
            icon: const Icon(Icons.fingerprint),
            label: const Text('지문'),
          ),
        if (canPin)
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(_BackupAuthChoice.pin),
            icon: const Icon(Icons.lock_outline),
            label: const Text('PIN'),
          ),
        if (canPassword)
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_BackupAuthChoice.password),
            icon: const Icon(Icons.password_outlined),
            label: const Text('비번'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_BackupAuthChoice.exit),
          child: const Text('취소'),
        ),
      ],
    );
  }
}

class _BackupScreenState extends State<BackupScreen> {
  final AuthService _authService = AuthService();
  final UserPinService _userPinService = UserPinService();
  final UserPasswordService _userPasswordService = UserPasswordService();

  String? _backupStatus;
  bool _isProcessing = false;
  List<_BackupFileInfo> _backupFiles = [];
  String? _backupDirectory;
  bool _isLoading = true;
  String? _registeredEmail;
  bool _backupEncryptionEnabled = false;
  bool _backupTwoFactorEnabled = false;

  Future<void> _authenticateForBackupProtection({
    required String reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final pinEnabled = prefs.getBool(PrefKeys.userPinEnabled) ?? false;
    final passwordEnabled =
        prefs.getBool(PrefKeys.userPasswordEnabled) ?? false;
    final biometricEnabled =
        prefs.getBool(PrefKeys.userBiometricEnabled) ?? false;

    final pinConfigured = _userPinService.isPinConfigured(prefs);
    final passwordConfigured = _userPasswordService.isPasswordConfigured(prefs);

    final canPin = pinEnabled && pinConfigured;
    final canPassword = passwordEnabled && passwordConfigured;
    final canBiometric = biometricEnabled;

    final any = canPin || canPassword || canBiometric;
    if (!any) {
      // Backward-compatible fallback: if user hasn't enabled methods, keep
      // using device auth like the old two-factor behavior.
      await _authenticateDeviceForBackup(reason: reason);
      return;
    }

    if (!mounted) return;
    final choice = await showDialog<_BackupAuthChoice>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _BackupAuthChoiceDialog(
          canPin: canPin,
          canPassword: canPassword,
          canBiometric: canBiometric,
        );
      },
    );

    if (!mounted) return;
    if (choice == null || choice == _BackupAuthChoice.exit) {
      throw Exception('인증이 취소되었습니다');
    }

    switch (choice) {
      case _BackupAuthChoice.biometric:
        final result = await _authService.authenticateDevice(reason: reason);
        if (!result.ok) {
          throw Exception(result.message ?? '인증이 취소되었습니다');
        }
        return;
      case _BackupAuthChoice.pin:
        final ok = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return VerifyCurrentUserPinDialog(
              prefs: prefs,
              service: _userPinService,
            );
          },
        );
        if (ok != true) throw Exception('PIN 인증이 취소되었습니다');
        return;
      case _BackupAuthChoice.password:
        final ok = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return VerifyCurrentUserPasswordDialog(
              prefs: prefs,
              service: _userPasswordService,
            );
          },
        );
        if (ok != true) throw Exception('비밀번호 인증이 취소되었습니다');
        return;
      case _BackupAuthChoice.exit:
        throw Exception('인증이 취소되었습니다');
    }
  }

  String _buildBackupFileName(DateTime timestamp) {
    final date = [
      timestamp.year.toString(),
      timestamp.month.toString().padLeft(2, '0'),
      timestamp.day.toString().padLeft(2, '0'),
    ].join();
    final time = [
      timestamp.hour.toString().padLeft(2, '0'),
      timestamp.minute.toString().padLeft(2, '0'),
      timestamp.second.toString().padLeft(2, '0'),
    ].join();
    return '${widget.accountName}_${date}_$time.json';
  }

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
    _loadRegisteredEmail();
    _loadBackupEncryptionEnabled();
    _loadBackupTwoFactorEnabled();
  }

  Future<void> _loadBackupEncryptionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(PrefKeys.backupEncryptionEnabled) ?? false;
    if (!mounted) return;
    setState(() {
      _backupEncryptionEnabled = enabled;
    });
  }

  Future<void> _setBackupEncryptionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.backupEncryptionEnabled, enabled);
    if (!mounted) return;
    setState(() {
      _backupEncryptionEnabled = enabled;
      if (!enabled) {
        _backupTwoFactorEnabled = false;
      }
    });
    if (!enabled) {
      await prefs.setBool(PrefKeys.backupTwoFactorEnabled, false);
      await BackupService().clearStoredBackupEncryptionPassword();
    }
  }

  Future<void> _loadBackupTwoFactorEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(PrefKeys.backupTwoFactorEnabled) ?? false;

    // Backward-compat: older versions used backupTwoFactorEnabled as the only
    // switch (and implied encryption). If user has it enabled, ensure the new
    // encryption flag is also enabled.
    if (enabled &&
        !(prefs.getBool(PrefKeys.backupEncryptionEnabled) ?? false)) {
      await prefs.setBool(PrefKeys.backupEncryptionEnabled, true);
    }

    if (!mounted) return;
    setState(() {
      _backupTwoFactorEnabled = enabled;
      if (enabled) {
        _backupEncryptionEnabled = true;
      }
    });
  }

  Future<void> _setBackupTwoFactorEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.backupTwoFactorEnabled, enabled);
    if (!mounted) return;
    setState(() {
      _backupTwoFactorEnabled = enabled;
      if (enabled) {
        _backupEncryptionEnabled = true;
      }
    });
  }

  Future<void> _authenticateDeviceForBackup({required String reason}) async {
    final auth = LocalAuthentication();
    final canAuth =
        await auth.canCheckBiometrics || await auth.isDeviceSupported();
    if (!canAuth) {
      throw Exception('이 기기에서 기기 인증을 사용할 수 없습니다');
    }

    final ok = await auth.authenticate(localizedReason: reason);
    if (!ok) {
      throw Exception('인증이 취소되었습니다');
    }
  }

  Future<String?> _promptBackupPassword({
    required String title,
    required String confirmText,
  }) async {
    final controller = TextEditingController();
    try {
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('백업 암호를 입력하세요.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '암호',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(confirmText),
            ),
          ],
        ),
      );

      if (!mounted) return null;
      if (value == null) return null;
      final trimmed = value.trim();
      if (trimmed.length < 4) {
        SnackbarUtils.showError(context, '암호는 4자 이상으로 설정하세요');
        return null;
      }
      return trimmed;
    } finally {
      controller.dispose();
    }
  }

  Future<String?> _promptNewBackupPassword() async {
    final controller1 = TextEditingController();
    final controller2 = TextEditingController();
    try {
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('백업 암호 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('이 암호는 백업 복원에 필요합니다.\n잊어버리면 복원이 불가능합니다.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller1,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '암호',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller2,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: '암호 확인',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final a = controller1.text.trim();
                final b = controller2.text.trim();
                if (a.length < 4) {
                  SnackbarUtils.showError(context, '암호는 4자 이상으로 설정하세요');
                  return;
                }
                if (a != b) {
                  SnackbarUtils.showError(context, '암호가 일치하지 않습니다');
                  return;
                }
                Navigator.pop(context, a);
              },
              child: const Text('설정'),
            ),
          ],
        ),
      );
      if (!mounted) return null;
      return value?.trim();
    } finally {
      controller1.dispose();
      controller2.dispose();
    }
  }

  Future<String?> _prepareBackupEncryptionPassword() async {
    // Per-backup encryption support:
    // - If global encryption is enabled: reuse stored password or offer setup
    //   and persist it.
    // - If global encryption is disabled: still allow a one-off encrypted
    //   backup (password is NOT stored).

    if (_backupTwoFactorEnabled) {
      await _authenticateForBackupProtection(reason: '백업 보호를 위해 인증을 진행합니다.');
    }

    final stored = await BackupService().getStoredBackupEncryptionPassword();
    if (_backupEncryptionEnabled &&
        stored != null &&
        stored.trim().isNotEmpty) {
      return stored;
    }

    if (!mounted) return null;
    final wantsEncrypt = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('암호화 백업'),
        content: Text(
          _backupEncryptionEnabled
              ? '백업 암호를 설정하면 백업 파일이 암호화됩니다.\n'
                    '지금 설정하지 않으면 암호 없이(평문) 백업됩니다.'
              : '이번 백업을 암호화할 수 있습니다.\n'
                    '암호를 설정하지 않으면 암호 없이(평문) 백업됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('암호 없이'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('암호 걸기'),
          ),
        ],
      ),
    );

    if (!mounted) return null;
    if (wantsEncrypt != true) return null;

    final pw = await _promptNewBackupPassword();
    if (pw == null || pw.trim().isEmpty) return null;

    // Persist only when global encryption is enabled.
    if (_backupEncryptionEnabled) {
      await BackupService().setStoredBackupEncryptionPassword(pw);
    }
    return pw;
  }

  Future<String?> _prepareRestorePasswordIfNeeded(File file) async {
    // ignore: avoid_slow_async_io
    final text = await file.readAsString();
    final isEncrypted = BackupService().isEncryptedBackupText(text);
    if (!isEncrypted) return null;

    if (_backupTwoFactorEnabled) {
      await _authenticateForBackupProtection(reason: '복원을 위해 인증을 진행합니다.');
    }

    return _promptBackupPassword(title: '암호화 백업 복원', confirmText: '복원');
  }

  Future<void> _loadRegisteredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(PrefKeys.backupRegisteredEmail);
    if (!mounted) return;
    setState(() {
      _registeredEmail = value;
    });
  }

  Future<void> _showEmailRegistrationDialog() async {
    final controller = TextEditingController(text: _registeredEmail ?? '');
    try {
      final value = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('이메일 등록'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('이메일 주소를 저장합니다.'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ''),
              child: const Text('삭제'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('저장'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (value == null) return;

      final prefs = await SharedPreferences.getInstance();
      if (value.isEmpty) {
        await prefs.remove(PrefKeys.backupRegisteredEmail);
      } else {
        await prefs.setString(PrefKeys.backupRegisteredEmail, value);
      }

      if (!mounted) return;
      setState(() {
        _registeredEmail = value.isEmpty ? null : value;
      });
      SnackbarUtils.showSuccess(context, '저장되었습니다');
    } finally {
      controller.dispose();
    }
  }

  Future<void> _loadBackupFiles() async {
    setState(() {
      _isLoading = true;
      _backupStatus = null;
    });

    try {
      final appDir = await getApplicationDocumentsDirectory();

      // Android Downloads folder (primary user-facing location).
      final downloadsDir = Directory(
        '/storage/emulated/0/Download/'
        '${AppConstants.backupDownloadsFolderName}',
      );

      // Internal app documents (legacy / fallback).
      final internalDir = Directory(appDir.path);
      final internalBackupFolder = Directory(
        '${appDir.path}/${AppConstants.backupDownloadsFolderName}',
      );

      List<_BackupFileInfo> readEntries(Directory dir) {
        if (!dir.existsSync()) return const <_BackupFileInfo>[];
        return dir
            .listSync()
            .whereType<File>()
            .where((file) => file.path.endsWith('.json'))
            .where((file) => file.path.contains(widget.accountName))
            .map((file) {
              final stat = file.statSync();
              return _BackupFileInfo(
                file: file,
                fileName: file.path.split(Platform.pathSeparator).last,
                modified: stat.modified,
                sizeInKb: (stat.size / 1024).toStringAsFixed(1),
              );
            })
            .toList();
      }

      // Merge + de-dup (same file can appear in multiple scanned dirs).
      final byPath = <String, _BackupFileInfo>{};
      for (final entry in [
        ...readEntries(downloadsDir),
        ...readEntries(internalDir),
        ...readEntries(internalBackupFolder),
      ]) {
        byPath[entry.file.path] = entry;
      }

      final entries = byPath.values.toList()
        ..sort((a, b) => b.modified.compareTo(a.modified));

      if (!mounted) return;
      setState(() {
        _backupDirectory = [
          downloadsDir.path,
          internalDir.path,
          internalBackupFolder.path,
        ].join('\n');
        _backupFiles = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backupStatus = '백업 파일 목록 로딩 실패: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showBackupOptions() async {
    final option = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('백업 방법 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('백업 파일을 어디에 저장하시겠습니까?'),
            const SizedBox(height: 16),
            _buildBackupOption(
              icon: Icons.phone_android,
              title: '앱 내부 저장',
              subtitle: '안전 (앱 삭제 시 삭제됨)',
              value: 'internal',
              recommended: true,
            ),
            const Divider(),
            _buildBackupOption(
              icon: Icons.folder,
              title: 'Downloads 폴더',
              subtitle: '⚠️ 다른 앱도 접근 가능',
              value: 'downloads',
            ),
            const Divider(),
            _buildBackupOption(
              icon: Icons.share,
              title: '공유/내보내기',
              subtitle: '클라우드 드라이브/포털 클라우드 등 앱 선택',
              value: 'share',
              recommended: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (option == null) return;

    if (option == 'internal') {
      await _backupToInternal();
    } else if (option == 'downloads') {
      await _backupToDownloads();
    } else if (option == 'share') {
      await _shareExport();
    }
  }

  Widget _buildBackupOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    bool recommended = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: recommended ? Colors.green : null),
      title: Row(
        children: [
          Text(title),
          if (recommended) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '권장',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(subtitle),
      onTap: () => Navigator.pop(context, value),
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _backupToInternal() async {
    setState(() {
      _isProcessing = true;
      _backupStatus = '백업 중...';
    });

    try {
      final now = DateTime.now();
      final fileName = _buildBackupFileName(now);

      final pw = await _prepareBackupEncryptionPassword();

      await BackupService().saveBackupToFile(
        widget.accountName,
        fileName,
        encryptionPassword: pw,
      );

      if (!mounted) return;
      await _loadBackupFiles();

      if (!mounted) return;
      setState(() {
        _backupStatus = '✅ 백업 완료!\n앱 내부에 안전하게 저장되었습니다.';
        _isProcessing = false;
      });

      if (mounted) {
        SnackbarUtils.showSuccess(context, '백업이 완료되었습니다');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backupStatus = '❌ 백업 실패: $e';
        _isProcessing = false;
      });
      SnackbarUtils.showError(context, '백업 실패: $e');
    }
  }

  Future<void> _backupToDownloads() async {
    final encryptionNotice = _backupEncryptionEnabled
        ? (_backupTwoFactorEnabled
              ? '✅ 암호화 저장됩니다.\n(복원 시 암호 + 기기 인증 필요)'
              : '✅ 암호화 저장됩니다.\n(복원 시 암호 필요)')
        : '암호화 없이 저장됩니다.';

    // 경고 메시지 표시
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('보안 경고'),
          ],
        ),
        content: Text(
          'Downloads 폴더에 저장하시겠습니까?\n\n'
          '✅ 앱 삭제 후에도 파일 보존\n'
          '⚠️ 다른 앱에서 접근 가능\n'
          '⚠️ 금융 정보 포함됨\n\n'
          '$encryptionNotice',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('계속'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _backupStatus = '백업 중...';
    });

    try {
      final pw = await _prepareBackupEncryptionPassword();

      final filePath = await BackupService().saveBackupToDownloads(
        widget.accountName,
        encryptionPassword: pw,
      );
      final fileName = filePath.split(Platform.pathSeparator).last;
      final savedDir = File(filePath).parent.path;

      if (!mounted) return;
      setState(() {
        _backupStatus =
            '''
✅ 백업 완료!
위치: $savedDir
파일: $fileName
'''
                .trim();
        _isProcessing = false;
      });

      if (mounted) {
        SnackbarUtils.showSuccess(context, '백업이 완료되었습니다');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backupStatus = '❌ 백업 실패: $e';
        _isProcessing = false;
      });
      SnackbarUtils.showError(context, '백업 실패: $e');
    }
  }

  Future<void> _shareExport() async {
    setState(() {
      _isProcessing = true;
      _backupStatus = '공유/내보내기 준비 중...';
    });

    try {
      final pw = await _prepareBackupEncryptionPassword();

      await BackupService().shareBackup(
        widget.accountName,
        encryptionPassword: pw,
      );

      if (!mounted) return;
      setState(() {
        _backupStatus = null;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backupStatus = '❌ 공유 실패: $e';
        _isProcessing = false;
      });
      SnackbarUtils.showError(context, '공유 실패: $e');
    }
  }

  Future<void> _sendEmailBackup() async {
    setState(() {
      _isProcessing = true;
      _backupStatus = '이메일 준비 중...';
    });

    try {
      final pw = await _prepareBackupEncryptionPassword();

      await BackupService().composeEmailWithBackup(
        widget.accountName,
        encryptionPassword: pw,
      );

      if (!mounted) return;
      setState(() {
        _backupStatus = null;
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backupStatus = '❌ 이메일 열기 실패: $e';
        _isProcessing = false;
      });
      SnackbarUtils.showError(context, '이메일 열기 실패: $e');
    }
  }

  Future<void> _restoreAsNewAccount() async {
    // 새 계정명 입력 받기
    final controller = TextEditingController();
    try {
      final newAccountName = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('새 계정으로 복원'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('복원할 새 계정명을 입력하세요.\n기존 데이터는 보존됩니다.'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '새 계정명',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    final locale = Localizations.localeOf(context);
                    final suffix = AccountNameLanguageTag.suffixForLocale(
                      locale,
                    );
                    final baseName = value.text.trim();
                    final finalName = AccountNameLanguageTag.applyForcedSuffix(
                      baseName,
                      locale,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '언어 태그가 강제 삽입됩니다: $suffix',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12,
                          ),
                        ),
                        if (baseName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '최종 계정명: $finalName',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final locale = Localizations.localeOf(context);
                final baseName = controller.text.trim();
                final finalName = AccountNameLanguageTag.applyForcedSuffix(
                  baseName,
                  locale,
                );
                Navigator.pop(context, finalName);
              },
              child: const Text('복원'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (newAccountName == null || newAccountName.isEmpty) return;

      setState(() {
        _isProcessing = true;
        _backupStatus = '복원 중...';
      });

      try {
        final picked = await BackupService().pickBackupFile();
        if (picked == null) {
          if (!mounted) return;
          setState(() {
            _backupStatus = '복원이 취소되었습니다';
            _isProcessing = false;
          });
          return;
        }

        final password = await _prepareRestorePasswordIfNeeded(picked);
        final jsonStr = await BackupService().readBackupFileAsJson(
          file: picked,
          password: password,
        );

        final preview = BackupService().parseBackupPreview(jsonStr);
        final exportedAtText = preview.exportedAt != null
            ? preview.exportedAt!.toLocal().toString()
            : '알 수 없음';
        final sourceAccountText =
            preview.sourceAccountName?.trim().isNotEmpty == true
            ? preview.sourceAccountName!
            : '알 수 없음';

        if (!mounted) return;

        final ok = await DialogUtils.showConfirmDialog(
          context,
          title: '복원 내용 확인',
          message:
              '이 백업을 "$newAccountName" 계정으로 복원합니다.\n\n'
              '백업 계정: $sourceAccountText\n'
              '내보낸 시각: $exportedAtText\n\n'
              '거래: ${preview.transactionCount}건\n'
              '자산: ${preview.assetCount}개\n'
              '고정비: ${preview.fixedCostCount}개\n'
              '저축계획: ${preview.savingsPlanCount}개\n'
              '장바구니: ${preview.shoppingCartItemCount}개\n\n'
              '계속하시겠습니까?',
          confirmText: '복원',
        );
        if (ok != true) {
          if (!mounted) return;
          setState(() {
            _backupStatus = '복원이 취소되었습니다';
            _isProcessing = false;
          });
          return;
        }

        await BackupService().importAccountDataAsNew(jsonStr, newAccountName);
        final restoredName = newAccountName;

        if (!mounted) return;
        setState(() {
          _backupStatus = '✅ 복원 완료!\n계정: $restoredName';
          _isProcessing = false;
        });

        SnackbarUtils.showSuccess(context, '$restoredName 계정으로 복원되었습니다');
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _backupStatus = '❌ 복원 실패: $e';
          _isProcessing = false;
        });
        SnackbarUtils.showError(context, '복원 실패: $e');
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _restoreFromFile(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    try {
      final password = await _prepareRestorePasswordIfNeeded(file);
      final jsonStr = await BackupService().readBackupFileAsJson(
        file: file,
        password: password,
      );

      final preview = BackupService().parseBackupPreview(jsonStr);
      final exportedAtText = preview.exportedAt != null
          ? preview.exportedAt!.toLocal().toString()
          : '알 수 없음';
      final sourceAccountText =
          preview.sourceAccountName?.trim().isNotEmpty == true
          ? preview.sourceAccountName!
          : '알 수 없음';

      if (!mounted) return;

      final controller = TextEditingController(
        text: preview.sourceAccountName?.trim().isNotEmpty == true
            ? preview.sourceAccountName!
            : '',
      );
      String? newAccountName;
      try {
        newAccountName = await showDialog<String>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('새 계정으로 복원'),
              content: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  final locale = Localizations.localeOf(dialogContext);
                  final suffix = AccountNameLanguageTag.suffixForLocale(locale);
                  final baseName = value.text.trim();
                  final finalName = AccountNameLanguageTag.applyForcedSuffix(
                    baseName,
                    locale,
                  );

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이 백업을 새 계정으로 복원합니다.\n기존 데이터는 보존됩니다.\n\n'
                        '파일: $fileName\n'
                        '백업 계정: $sourceAccountText\n'
                        '내보낸 시각: $exportedAtText\n\n'
                        '거래: ${preview.transactionCount}건\n'
                        '자산: ${preview.assetCount}개\n'
                        '고정비: ${preview.fixedCostCount}개\n'
                        '저축계획: ${preview.savingsPlanCount}개\n'
                        '장바구니: ${preview.shoppingCartItemCount}개',
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          labelText: '새 계정명',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '언어 태그가 강제 삽입됩니다: $suffix',
                        style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12,
                        ),
                      ),
                      if (baseName.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '최종 계정명: $finalName',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    final baseName = controller.text.trim();
                    if (baseName.isEmpty) return;
                    final locale = Localizations.localeOf(dialogContext);
                    final finalName = AccountNameLanguageTag.applyForcedSuffix(
                      baseName,
                      locale,
                    );
                    Navigator.pop(dialogContext, finalName);
                  },
                  child: const Text('복원'),
                ),
              ],
            );
          },
        );
      } finally {
        controller.dispose();
      }

      if (!mounted) return;
      if (newAccountName == null || newAccountName.trim().isEmpty) {
        return;
      }

      setState(() {
        _isProcessing = true;
        _backupStatus = '복원 중...';
      });

      await BackupService().importAccountDataAsNew(jsonStr, newAccountName);

      if (!mounted) return;

      setState(() {
        _backupStatus = '✅ 복원 완료!\n계정: $newAccountName';
        _isProcessing = false;
      });

      SnackbarUtils.showSuccess(context, '$newAccountName 계정으로 복원되었습니다');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _backupStatus = '❌ 복원 실패: $error';
        _isProcessing = false;
      });

      SnackbarUtils.showError(context, '복원 실패: $error');
    }
  }

  Future<void> _deleteBackupFile(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final confirmed = await DialogUtils.showDeleteConfirmDialog(
      context,
      customMessage: '백업 파일을 삭제하시겠습니까?\n\n$fileName',
    );

    if (confirmed != true) return;

    if (!mounted) return;

    try {
      await file.delete();
      if (!mounted) return;
      await _loadBackupFiles();
      if (mounted) {
        SnackbarUtils.showSuccess(context, '삭제되었습니다');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _backupStatus = '❌ 삭제 실패: $e';
      });
      SnackbarUtils.showError(context, '삭제 실패: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.accountName} - 백업/복원'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '목록 새로고침',
            onPressed: _isProcessing ? null : _loadBackupFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          // 백업 버튼들
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('백업 암호화 (암호 필요)'),
                  subtitle: const Text(
                    '켜면 백업 파일이 암호화됩니다.\n'
                    '※ 암호를 잊으면 복원 불가 / 자동백업은 실행되지 않습니다.',
                  ),
                  value: _backupEncryptionEnabled,
                  onChanged: _isProcessing
                      ? null
                      : (value) async {
                          if (value) {
                            final ok = await DialogUtils.showConfirmDialog(
                              context,
                              title: '백업 암호화 사용',
                              message:
                                  '이 옵션을 켜면:\n'
                                  '- 백업 파일은 암호화됩니다\n'
                                  '- 복원 시 암호가 필요합니다\n'
                                  '- 암호를 잊으면 복원이 불가능합니다\n'
                                  '- 자동백업은 실행되지 않습니다\n\n'
                                  '계속하시겠습니까?',
                              confirmText: '사용',
                            );
                            if (ok != true) return;
                          }
                          await _setBackupEncryptionEnabled(value);
                        },
                ),
                if (_backupEncryptionEnabled) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('2단계 보호 (기기 인증 추가)'),
                    subtitle: const Text(
                      '켜면 암호 입력 전 기기 인증을 요구합니다.\n'
                      '※ 암호화 백업에만 적용됩니다.',
                    ),
                    value: _backupTwoFactorEnabled,
                    onChanged: _isProcessing
                        ? null
                        : (value) async {
                            if (value) {
                              final ok = await DialogUtils.showConfirmDialog(
                                context,
                                title: '2단계 보호 사용',
                                message:
                                    '이 옵션을 켜면:\n'
                                    '- 백업 생성 시 기기 인증 + 암호 입력\n'
                                    '- 복원 시 기기 인증 + 암호 입력\n\n'
                                    '계속하시겠습니까?',
                                confirmText: '사용',
                              );
                              if (ok != true) return;
                            }
                            await _setBackupTwoFactorEnabled(value);
                          },
                  ),
                ],
                const SizedBox(height: 8),
                // 백업 버튼
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _showBackupOptions,
                  icon: const Icon(Icons.backup),
                  label: const Text('새 백업 만들기'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
                const SizedBox(height: 8),
                // 복원 버튼
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _restoreAsNewAccount,
                  icon: const Icon(Icons.restore, size: 18),
                  label: const Text('파일에서 복원 (새 계정)'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isProcessing
                      ? null
                      : _showEmailRegistrationDialog,
                  icon: const Icon(Icons.alternate_email, size: 18),
                  label: Text(
                    _registeredEmail == null || _registeredEmail!.isEmpty
                        ? '이메일 등록'
                        : '이메일 등록: $_registeredEmail',
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _sendEmailBackup,
                  icon: const Icon(Icons.email, size: 18),
                  label: const Text('이메일로 보내기'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isProcessing ? null : _shareExport,
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('공유/내보내기'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
                if (_backupStatus != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _backupStatus!,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          // 백업 파일 목록
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: LoadingCardListSkeleton(itemCount: 6, height: 76),
                  );
                }
                if (_backupStatus != null && _backupFiles.isEmpty) {
                  return ErrorState(
                    message: _backupStatus,
                    onRetry: _loadBackupFiles,
                  );
                }
                if (_backupFiles.isEmpty) {
                  return const EmptyState(
                    title: '백업 파일이 없습니다',
                    message: '"새 백업 만들기" 버튼으로 생성하거나 외부 백업을 가져오세요.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _backupFiles.length,
                  itemBuilder: (context, index) {
                    final entry = _backupFiles[index];
                    final file = entry.file;
                    final modifiedDate = DateFormats.yMdHms.format(
                      entry.modified,
                    );

                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file, size: 40),
                        title: Text(
                          entry.fileName,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          '$modifiedDate\n크기: ${entry.sizeInKb} KB',
                          style: theme.textTheme.bodySmall,
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'restore') {
                              await _restoreFromFile(file);
                            } else if (value == 'delete') {
                              await _deleteBackupFile(file);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'restore',
                              child: Row(
                                children: [
                                  Icon(Icons.restore, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('복원'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('삭제'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 백업 경로 표시
          if (_backupDirectory != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Text(
                '백업 경로: $_backupDirectory',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
