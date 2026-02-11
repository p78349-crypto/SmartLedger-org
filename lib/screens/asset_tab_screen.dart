import 'dart:async';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
// intl not required here; use DateFormatter where needed
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
import '_verify_current_user_password_dialog.dart';
import '_verify_current_user_pin_dialog.dart';
import 'asset_allocation_screen.dart';
import 'asset_dashboard_screen.dart';
import 'asset_input_screen.dart';
import 'asset_simple_input_screen.dart';
import '../services/asset_service.dart';
import '../services/auth_service.dart';
import '../services/root_pin_service.dart';
import '../services/user_password_service.dart';
import '../services/user_pin_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/pref_keys.dart';
import '../utils/utils.dart';
import '../widgets/smart_input_field.dart';

enum _AssetSubview { none, expenses, savings }

enum _AssetAuthChoice { biometric, pin, password, exit }

class _AssetAuthChoiceDialog extends StatelessWidget {
  const _AssetAuthChoiceDialog({
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
      title: const Text('자산 보호 인증'),
      content: const Text('사용할 인증 방법을 선택하세요.'),
      actions: [
        if (canBiometric)
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_AssetAuthChoice.biometric),
            icon: const Icon(IconCatalog.fingerprint),
            label: const Text('지문'),
          ),
        if (canPin)
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(_AssetAuthChoice.pin),
            icon: const Icon(IconCatalog.lockOutline),
            label: const Text('PIN'),
          ),
        if (canPassword)
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_AssetAuthChoice.password),
            icon: const Icon(IconCatalog.passwordOutlined),
            label: const Text('비번'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_AssetAuthChoice.exit),
          child: const Text('취소'),
        ),
      ],
    );
  }
}

class AssetTabScreen extends StatefulWidget {
  final String accountName;
  final bool showAccountHeading;
  const AssetTabScreen({
    super.key,
    required this.accountName,
    this.showAccountHeading = true,
  });

  @override
  State<AssetTabScreen> createState() => _AssetTabScreenState();
}

class _AssetTabScreenState extends State<AssetTabScreen> {
  bool _loading = true;
  List<Asset> _assets = const [];
  // No savings plans list
  _AssetSubview _activeSubview = _AssetSubview.none;

  // 생체 인증 관련
  bool _isAuthenticated = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isDeviceSupported = false;
  bool _biometricAuthEnabled = false; // 기본값: 비활성화 (사용자가 설정에서 켤 때까지 노출되지 않음)

  final AuthService _authService = AuthService();
  final UserPinService _userPinService = UserPinService();
  final UserPasswordService _userPasswordService = UserPasswordService();

  bool _rootAuthEnabled = true;
  String _rootAuthMode = 'integrated';

  bool _rootPinEnabled = false;
  bool _rootPinConfigured = false;
  final RootPinService _rootPinService = RootPinService();

  static const Duration _autoLockIdleTimeout = Duration(minutes: 1);
  Timer? _autoLockTimer;

  @override
  void initState() {
    super.initState();
    _loadAssets();
    _checkDeviceAuthSupport();
    _loadBiometricSettings();
    _loadRootAuthEnabled();
    _loadRootAuthMode();
    _loadRootPinState();
  }

  @override
  void dispose() {
    _autoLockTimer?.cancel();
    super.dispose();
  }

  void _resetAutoLockTimer() {
    _autoLockTimer?.cancel();
    if (!_biometricAuthEnabled) return;
    if (!_isAuthenticated) return;

    // Persist an "unlocked until" marker so other parts of the app can
    // respect the same lock/unlock window.
    SharedPreferences.getInstance().then((prefs) {
      prefs.setInt(
        PrefKeys.assetAuthSessionUntilMs,
        DateTime.now().add(_autoLockIdleTimeout).millisecondsSinceEpoch,
      );
    });

    _autoLockTimer = Timer(_autoLockIdleTimeout, () {
      if (!mounted) return;
      // Auto-lock after inactivity.
      setState(() {
        _isAuthenticated = false;
      });
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove(PrefKeys.assetAuthSessionUntilMs);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('일정 시간 미사용으로 자동 잠금되었습니다')));
    });
  }

  // 생체 인증 설정 로드
  Future<void> _loadBiometricSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final enabled = prefs.getBool(PrefKeys.biometricAuthEnabled) ?? false;
    setState(() {
      _biometricAuthEnabled = enabled;
      if (!enabled) {
        _isAuthenticated = true;
        _autoLockTimer?.cancel();
        // Security off => clear lock marker.
        prefs.remove(PrefKeys.assetAuthSessionUntilMs);
        prefs.remove(PrefKeys.rootAuthSessionUntilMs);
      }
    });
    _resetAutoLockTimer();
  }

  Future<void> _loadRootAuthEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool(PrefKeys.rootAuthEnabled) ??
        (prefs.getBool(PrefKeys.biometricAuthEnabled) ?? false);
    if (!mounted) return;
    setState(() {
      _rootAuthEnabled = enabled;
    });
  }

  Future<void> _setRootAuthEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.rootAuthEnabled, enabled);
    if (!enabled) {
      // Turning off ROOT lock clears only ROOT session.
      await prefs.remove(PrefKeys.rootAuthSessionUntilMs);
    }
    if (!mounted) return;
    setState(() {
      _rootAuthEnabled = enabled;
    });
  }

  Future<void> _loadRootPinState() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(PrefKeys.rootPinEnabled) ?? false;
    final configured = _rootPinService.isPinConfigured(prefs);
    if (!mounted) return;
    setState(() {
      _rootPinEnabled = enabled && configured;
      _rootPinConfigured = configured;
    });

    if (enabled && !configured) {
      await prefs.setBool(PrefKeys.rootPinEnabled, false);
    }
  }

  Future<void> _setRootPinEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final configured = _rootPinService.isPinConfigured(prefs);

    if (enabled && !configured) {
      final didSet = await _showSetRootPinDialog();
      if (!didSet) return;
    }

    await prefs.setBool(PrefKeys.rootPinEnabled, enabled);
    await prefs.remove(PrefKeys.rootAuthSessionUntilMs);

    final configuredNow = _rootPinService.isPinConfigured(prefs);
    if (!mounted) return;
    setState(() {
      _rootPinEnabled = enabled && configuredNow;
      _rootPinConfigured = configuredNow;
    });
  }

  Future<bool> _showSetRootPinDialog() async {
    if (!mounted) return false;

    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('ROOT PIN 설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SmartInputField(
                    label: '새 PIN',
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  SmartInputField(
                    label: 'PIN 확인',
                    controller: confirmController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () {
                    final pin = pinController.text.trim();
                    final confirm = confirmController.text.trim();
                    if (pin.length < 4) {
                      setDialogState(() {
                        error = 'PIN은 최소 4자리 이상이어야 합니다.';
                      });
                      return;
                    }
                    if (pin != confirm) {
                      setDialogState(() {
                        error = 'PIN이 일치하지 않습니다.';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return false;

    final pin = pinController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    await _rootPinService.setPin(prefs, pin: pin);

    if (!mounted) return true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ROOT PIN이 설정되었습니다')));
    return true;
  }

  Future<void> _loadRootAuthMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(PrefKeys.rootAuthMode) ?? 'integrated';
    if (!mounted) return;
    setState(() {
      _rootAuthMode = mode;
    });
  }

  Future<void> _setRootAuthMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.rootAuthMode, mode);
    if (mode == 'integrated') {
      // Integrated mode uses the asset session only.
      await prefs.remove(PrefKeys.rootAuthSessionUntilMs);
    }
    if (!mounted) return;
    setState(() {
      _rootAuthMode = mode;
    });
  }

  // 생체 인증 설정 저장
  Future<void> _toggleBiometricAuth(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.biometricAuthEnabled, value);
    if (!mounted) return;
    setState(() {
      _biometricAuthEnabled = value;
      if (!value) {
        _isAuthenticated = true; // 인증 끄면 자동으로 접근 허용
        _autoLockTimer?.cancel();
        prefs.remove(PrefKeys.assetAuthSessionUntilMs);
        prefs.remove(PrefKeys.rootAuthSessionUntilMs);
      } else {
        // Turning security on should require re-auth.
        _isAuthenticated = false;
        prefs.remove(PrefKeys.assetAuthSessionUntilMs);
        prefs.remove(PrefKeys.rootAuthSessionUntilMs);
      }
    });
  }

  // 생체 인증 가능 여부 확인
  Future<void> _checkDeviceAuthSupport() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      if (!mounted) return;
      setState(() {
        _canCheckBiometrics = canCheck;
        _isDeviceSupported = supported;
      });
    } catch (e) {
      debugPrint('생체 인증 확인 오류: $e');
    }
  }

  // 생체 인증 실행
  Future<bool> _authenticateForAssetProtection() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final pinEnabled = prefs.getBool(PrefKeys.userPinEnabled) ?? false;
      final passwordEnabled =
          prefs.getBool(PrefKeys.userPasswordEnabled) ?? false;
      final biometricEnabled =
          prefs.getBool(PrefKeys.userBiometricEnabled) ?? false;

      final pinConfigured = _userPinService.isPinConfigured(prefs);
      final passwordConfigured = _userPasswordService.isPasswordConfigured(
        prefs,
      );

      final canPin = pinEnabled && pinConfigured;
      final canPassword = passwordEnabled && passwordConfigured;
      final canBiometric = biometricEnabled;
      final any = canPin || canPassword || canBiometric;

      if (!any) {
        // Backward-compatible fallback: if user hasn't enabled any methods,
        // keep using device auth like the old asset protection.
        final result = await _authService.authenticateDevice(
          reason: '자산 정보에 접근하려면 인증이 필요합니다',
        );

        // If device auth is not available (e.g., emulator/no biometrics),
        // allow access as a pragmatic fallback but set the session marker.
        if (result.status == AuthStatus.unavailable) {
          await prefs.setInt(
            PrefKeys.assetAuthSessionUntilMs,
            DateTime.now()
                .add(AuthService.assetSessionTimeout)
                .millisecondsSinceEpoch,
          );
          if (!mounted) return true;
          setState(() => _isAuthenticated = true);
          _resetAutoLockTimer();
          return true;
        }

        if (!result.ok) return false;

        await prefs.setInt(
          PrefKeys.assetAuthSessionUntilMs,
          DateTime.now()
              .add(AuthService.assetSessionTimeout)
              .millisecondsSinceEpoch,
        );

        if (!mounted) return true;
        setState(() => _isAuthenticated = true);
        _resetAutoLockTimer();
        return true;
      }

      if (!mounted) return false;
      final choice = await showDialog<_AssetAuthChoice>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _AssetAuthChoiceDialog(
            canPin: canPin,
            canPassword: canPassword,
            canBiometric: canBiometric,
          );
        },
      );

      if (!mounted) return false;
      if (choice == null || choice == _AssetAuthChoice.exit) return false;

      switch (choice) {
        case _AssetAuthChoice.biometric:
          final result = await _authService.authenticateDevice(
            reason: '자산 정보에 접근하려면 인증이 필요합니다',
          );
          if (!result.ok) return false;
          break;
        case _AssetAuthChoice.pin:
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
          if (ok != true) return false;
          break;
        case _AssetAuthChoice.password:
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
          if (ok != true) return false;
          break;
        case _AssetAuthChoice.exit:
          return false;
      }

      await prefs.setInt(
        PrefKeys.assetAuthSessionUntilMs,
        DateTime.now()
            .add(AuthService.assetSessionTimeout)
            .millisecondsSinceEpoch,
      );

      if (!mounted) return true;
      setState(() => _isAuthenticated = true);
      _resetAutoLockTimer();
      return true;
    } catch (e) {
      debugPrint('자산 인증 오류: $e');
      return false;
    }
  }

  Future<void> _loadAssets({bool showSpinner = false}) async {
    if (showSpinner && mounted) {
      setState(() => _loading = true);
    }
    await AssetService().loadAssets();
    final loaded = AssetService().getAssets(widget.accountName);
    if (!mounted) return;
    setState(() {
      _assets = loaded;
      _loading = false;
    });
  }

  Future<void> _openSimpleInput() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssetSimpleInputScreen(accountName: widget.accountName),
      ),
    );
    await _loadAssets(showSpinner: true);
  }

  Future<void> _openDetailInput() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AssetInputScreen(accountName: widget.accountName),
      ),
    );
    await _loadAssets(showSpinner: true);
  }

  Future<void> _exportAssets() async {
    try {
      await AssetService().loadAssets();
      final assets = AssetService().getAssets(widget.accountName);
      if (assets.isEmpty) {
        _showMessage('내보낼 자산 데이터가 없습니다.');
        return;
      }

      final headers = ['자산명', '금액'];
      final rows = <List<dynamic>>[
        headers,
        ...assets.map((a) => [a.name, a.amount]),
      ];

      final excel = Excel.createExcel();
      final sheet = excel['Assets'];
      for (final row in rows) {
        sheet.appendRow(
          row
              .map<CellValue>((value) => TextCellValue(value.toString()))
              .toList(),
        );
      }

      // 열 너비를 좁게 설정하여 사각형 모양으로 표시
      sheet.setColumnWidth(0, 12); // 자산명 열
      sheet.setColumnWidth(1, 12); // 금액 열

      final csvData = const ListToCsvConverter().convert(rows);
      final dir = await getDownloadsDirectory();
      if (dir == null) {
        throw Exception('다운로드 폴더를 찾을 수 없습니다.');
      }
      final now = DateTime.now();
      final stamp = _formatExportStamp(now);
      final excelPath = '${dir.path}/assets_$stamp.xlsx';
      final csvPath = '${dir.path}/assets_$stamp.csv';
      final excelBytes = excel.encode();
      if (excelBytes == null) {
        throw Exception('엑셀 파일 생성 실패');
      }
      await File(excelPath).writeAsBytes(excelBytes);
      await File(csvPath).writeAsString(csvData);

      _showMessage('엑셀/CSV 내보내기 완료\n엑셀: $excelPath\nCSV: $csvPath');
    } catch (e) {
      _showMessage('내보내기 실패: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    if (message.contains('실패')) {
      SnackbarUtils.showError(context, message);
    } else {
      SnackbarUtils.showSuccess(context, message);
    }
  }

  void _toggleExpensesView() => _toggleSubview(_AssetSubview.expenses);
  void _toggleSavingsView() => _toggleSubview(_AssetSubview.savings);
  Widget _buildSavingsView(ThemeData theme) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _toggleSavingsView,
                icon: const Icon(IconCatalog.close),
                label: const Text('예금 닫기'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '예금 데이터 출력 기능이 일시 중단되었습니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed savings view toggle

  void _toggleSubview(_AssetSubview target) {
    if (!mounted) return;
    setState(() {
      _activeSubview = _activeSubview == target ? _AssetSubview.none : target;
    });
  }

  Widget _buildExpenseView(ThemeData theme) {
    final expenses = _assets.where((asset) => asset.amount < 0).toList()
      ..sort((a, b) => a.amount.compareTo(b.amount));
    final expenseTotal = expenses.fold<double>(
      0,
      (sum, asset) => sum + asset.amount,
    );

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _toggleExpensesView,
                icon: const Icon(IconCatalog.close),
                label: const Text('통계 > 지출 닫기'),
              ),
            ),
            const SizedBox(height: 12),
            if (expenses.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '지출 내역',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('기록된 지출이 없습니다.', style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              )
            else ...[
              Card(
                color: theme.colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '지출 합계',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(expenseTotal),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...expenses.map(
                (asset) => Card(
                  child: ListTile(
                    leading: const Icon(
                      IconCatalog.paymentsOutlined,
                      color: Colors.redAccent,
                    ),
                    title: Text(asset.name),
                    trailing: Text(
                      CurrencyFormatter.format(asset.amount),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Removed savings view builder

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 보안이 활성화되어 있고 인증되지 않았으면 인증 화면 표시
    // (생체가 없어도 기기 암호(PIN/패턴/비밀번호)로 인증 가능)
    if (_biometricAuthEnabled && !_isAuthenticated) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(IconCatalog.lockOutline, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 24),
              Text(
                '자산 정보 보호',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '개인 자산 정보는 비밀번호/PIN/지문(기기 인증)으로 보호됩니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _authenticateForAssetProtection,
                icon: Icon(
                  _canCheckBiometrics
                      ? IconCatalog.fingerprint
                      : IconCatalog.password,
                ),
                label: const Text('인증하기'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _toggleBiometricAuth(false),
                child: const Text('인증 없이 사용하기'),
              ),
            ],
          ),
        ),
      );
    }

    if (_activeSubview == _AssetSubview.savings) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _resetAutoLockTimer(),
        onPointerMove: (_) => _resetAutoLockTimer(),
        onPointerUp: (_) => _resetAutoLockTimer(),
        child: _buildSavingsView(theme),
      );
    }
    if (_activeSubview == _AssetSubview.expenses) {
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _resetAutoLockTimer(),
        onPointerMove: (_) => _resetAutoLockTimer(),
        onPointerUp: (_) => _resetAutoLockTimer(),
        child: _buildExpenseView(theme),
      );
    }

    final simpleTotal = _assets
        .where((asset) => asset.inputType == AssetInputType.simple)
        .fold<double>(0, (sum, asset) => sum + asset.amount);
    final detailTotal = _assets
        .where((asset) => asset.inputType == AssetInputType.detail)
        .fold<double>(0, (sum, asset) => sum + asset.amount);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetAutoLockTimer(),
      onPointerMove: (_) => _resetAutoLockTimer(),
      onPointerUp: (_) => _resetAutoLockTimer(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🎯 **대시보드 요약** (총 자산, 총 손익, 자산별 카드 뷰)
            AssetDashboardScreen(
              accountName: widget.accountName,
              assets: _assets,
            ),
            const SizedBox(height: 8),
            const Divider(thickness: 2),
            const SizedBox(height: 8),
            // 📌 **기존 자산 입력/관리 메뉴**
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // 보안 토글 (기기 인증이 가능한 경우만)
                      if (_isDeviceSupported)
                        Row(
                          children: [
                            Icon(
                              _biometricAuthEnabled
                                  ? IconCatalog.lock
                                  : IconCatalog.lockOpen,
                              size: 20,
                              color: _biometricAuthEnabled
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '보안',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Switch(
                              value: _biometricAuthEnabled,
                              onChanged: _toggleBiometricAuth,
                              activeTrackColor: Colors.green[200],
                              activeThumbColor: Colors.green,
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: _toggleExpensesView,
                            icon: const Icon(IconCatalog.receiptLongOutlined),
                            label: const Text('통계 > 지출'),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                  if (_isDeviceSupported) ...[
                    const SizedBox(height: 8),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ROOT 보안', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ROOT 잠금',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Switch(
                                  value: _rootAuthEnabled,
                                  onChanged: _setRootAuthEnabled,
                                ),
                              ],
                            ),
                            if (!_rootAuthEnabled)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'OFF 상태에서는 ROOT 인증 없이 접근 가능합니다.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            if (_rootAuthEnabled)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  RadioGroup<String>(
                                    groupValue: _rootAuthMode,
                                    onChanged: (value) {
                                      if (value == null) return;
                                      _setRootAuthMode(value);
                                    },
                                    child: const Column(
                                      children: [
                                        RadioListTile<String>(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          title: Text(
                                            '통합 사용 (자산 인증으로 ROOT 통과)',
                                          ),
                                          value: 'integrated',
                                        ),
                                        RadioListTile<String>(
                                          dense: true,
                                          contentPadding: EdgeInsets.zero,
                                          title: Text('별도 사용 (ROOT 추가 인증)'),
                                          value: 'separate',
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'ROOT PIN 사용',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      Switch(
                                        value: _rootPinEnabled,
                                        onChanged: _setRootPinEnabled,
                                      ),
                                    ],
                                  ),
                                  if (_rootPinEnabled)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '별도 사용 모드에서는 2단계가 PIN으로 진행됩니다.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: _showSetRootPinDialog,
                                      child: Text(
                                        _rootPinConfigured
                                            ? 'ROOT PIN 변경'
                                            : 'ROOT PIN 설정',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Card(
                    child: InkWell(
                      onTap: _openSimpleInput,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              IconCatalog.accountBalanceWallet,
                              color: theme.colorScheme.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '간단 입력',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(simpleTotal),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              IconCatalog.chevronRight,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: InkWell(
                      onTap: _openDetailInput,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              IconCatalog.inventory2,
                              color: theme.colorScheme.secondary,
                              size: 32,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '상세 입력',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(detailTotal),
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              IconCatalog.chevronRight,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AssetAllocationScreen(
                            accountName: widget.accountName,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(IconCatalog.pieChart),
                    label: const Text('📊 자산 배분 분석'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _exportAssets,
                    icon: const Icon(IconCatalog.download),
                    label: const Text('엑셀/CSV 내보내기'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatExportStamp(DateTime date) {
  return DateFormatter.fileNameDateTime.format(date);
}
