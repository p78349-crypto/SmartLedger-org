import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/application_settings_screen.dart';
import 'package:smart_ledger/screens/_verify_current_user_password_dialog.dart';
import 'package:smart_ledger/screens/_verify_current_user_pin_dialog.dart';
import 'package:smart_ledger/services/auth_service.dart';
import 'package:smart_ledger/services/backup_service.dart';
import 'package:smart_ledger/services/user_password_service.dart';
import 'package:smart_ledger/services/user_pin_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/pref_keys.dart';
import 'package:smart_ledger/widgets/background_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _backupEncryptionEnabled = false;
  bool _backupTwoFactorEnabled = false;
  bool _userPinEnabled = false;
  bool _userPinConfigured = false;
  bool _userPasswordEnabled = false;
  bool _userPasswordConfigured = false;
  bool _userBiometricEnabled = false;

  bool _zeroQuickButtonsEnabled = false;
  final UserPinService _userPinService = UserPinService();
  final UserPasswordService _userPasswordService = UserPasswordService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 설정 앱(권한/알림 등)에서 돌아온 경우, 상태를 다시 읽어 UI를 갱신.
      _load();
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final backupEncryptionEnabled =
        prefs.getBool(PrefKeys.backupEncryptionEnabled) ?? false;
    final backupTwoFactorEnabled =
        prefs.getBool(PrefKeys.backupTwoFactorEnabled) ?? false;

    final userPinEnabled = prefs.getBool(PrefKeys.userPinEnabled) ?? false;
    final userPinConfigured = _userPinService.isPinConfigured(prefs);

    final userPasswordEnabled =
        prefs.getBool(PrefKeys.userPasswordEnabled) ?? false;
    final userPasswordConfigured = _userPasswordService.isPasswordConfigured(
      prefs,
    );

    final userBiometricEnabled =
        prefs.getBool(PrefKeys.userBiometricEnabled) ?? false;
    final zeroQuickButtonsEnabled =
        prefs.getBool(PrefKeys.zeroQuickButtonsEnabled) ?? false;

    if (userPinEnabled && !userPinConfigured) {
      await prefs.setBool(PrefKeys.userPinEnabled, false);
    }
    if (userPasswordEnabled && !userPasswordConfigured) {
      await prefs.setBool(PrefKeys.userPasswordEnabled, false);
    }
    if (!mounted) return;
    setState(() {
      _backupEncryptionEnabled = backupEncryptionEnabled;
      _backupTwoFactorEnabled = backupTwoFactorEnabled;
      _userPinEnabled = userPinEnabled && userPinConfigured;
      _userPinConfigured = userPinConfigured;
      _userPasswordEnabled = userPasswordEnabled && userPasswordConfigured;
      _userPasswordConfigured = userPasswordConfigured;
      _userBiometricEnabled = userBiometricEnabled;
      _zeroQuickButtonsEnabled = zeroQuickButtonsEnabled;
      _isLoading = false;
    });
  }

  Future<void> _setZeroQuickButtonsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await UserPrefService.setZeroQuickButtonsEnabled(enabled: enabled);
    await prefs.setBool(PrefKeys.zeroQuickButtonsEnabled, enabled);
    if (!mounted) return;
    setState(() => _zeroQuickButtonsEnabled = enabled);
  }

  Future<void> _setUserBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();

    if (enabled) {
      final can = await _authService.canUseDeviceAuth();
      if (!can) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이 기기에서 지문(기기 인증)을 사용할 수 없습니다')),
        );
        return;
      }
    }

    await prefs.setBool(PrefKeys.userBiometricEnabled, enabled);
    if (!mounted) return;
    setState(() => _userBiometricEnabled = enabled);
  }

  Future<void> _setUserPasswordEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    final configured = _userPasswordService.isPasswordConfigured(prefs);

    if (enabled && !configured) {
      final didSet = await _showSetUserPasswordDialog();
      if (!didSet) {
        if (!mounted) return;
        setState(() {
          _userPasswordEnabled = false;
          _userPasswordConfigured = _userPasswordService.isPasswordConfigured(
            prefs,
          );
        });
        return;
      }
    }

    if (!enabled) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('비밀번호 해지'),
            content: const Text('유저 계정 비밀번호를 해지할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('해지'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        if (!mounted) return;
        setState(() => _userPasswordEnabled = true);
        return;
      }

      await _userPasswordService.clearPassword(prefs);
    }

    await prefs.setBool(PrefKeys.userPasswordEnabled, enabled);
    final configuredNow = _userPasswordService.isPasswordConfigured(prefs);
    if (!mounted) return;
    setState(() {
      _userPasswordEnabled = enabled && configuredNow;
      _userPasswordConfigured = configuredNow;
    });
  }

  Future<bool> _showSetUserPasswordDialog() async {
    final pwController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    if (!mounted) {
      pwController.dispose();
      confirmController.dispose();
      return false;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('유저 계정 비밀번호 설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pwController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '새 비밀번호',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '비밀번호 확인',
                      border: OutlineInputBorder(),
                    ),
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
                    final pw = pwController.text;
                    final confirm = confirmController.text;
                    if (pw.trim().length < 6) {
                      setDialogState(() {
                        error = '비밀번호는 최소 6자 이상이어야 합니다.';
                      });
                      return;
                    }
                    if (pw != confirm) {
                      setDialogState(() {
                        error = '비밀번호가 일치하지 않습니다.';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text('설정'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      pwController.dispose();
      confirmController.dispose();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final password = pwController.text;
    pwController.dispose();
    confirmController.dispose();

    await _userPasswordService.setPassword(prefs, password: password);
    if (!mounted) return true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('유저 계정 비밀번호가 설정되었습니다')));
    return true;
  }

  Future<void> _changeUserPassword() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_userPasswordService.isPasswordConfigured(prefs)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 비밀번호를 설정하세요')));
      return;
    }

    if (!mounted) return;
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
    if (ok != true || !mounted) return;

    final didSet = await _showSetUserPasswordDialog();
    if (!didSet || !mounted) return;

    await prefs.setBool(PrefKeys.userPasswordEnabled, true);
    final configuredNow = _userPasswordService.isPasswordConfigured(prefs);
    setState(() {
      _userPasswordEnabled = configuredNow;
      _userPasswordConfigured = configuredNow;
    });
  }

  Future<void> _setUserPinEnabled(bool enabled) async {
    if (_isLoading) return;

    final prefs = await SharedPreferences.getInstance();
    final configured = _userPinService.isPinConfigured(prefs);

    if (enabled && !configured) {
      final didSet = await _showSetUserPinDialog();
      if (!didSet) {
        if (!mounted) return;
        setState(() {
          _userPinEnabled = false;
          _userPinConfigured = _userPinService.isPinConfigured(prefs);
        });
        return;
      }
    }

    if (!enabled) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('PIN 해지'),
            content: const Text('유저 계정 PIN을 해지할까요?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('취소'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('해지'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        if (!mounted) return;
        setState(() => _userPinEnabled = true);
        return;
      }

      await _userPinService.clearPin(prefs);
    }

    await prefs.setBool(PrefKeys.userPinEnabled, enabled);
    final configuredNow = _userPinService.isPinConfigured(prefs);
    if (!mounted) return;
    setState(() {
      _userPinEnabled = enabled && configuredNow;
      _userPinConfigured = configuredNow;
    });
  }

  Future<bool> _showSetUserPinDialog() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? error;

    if (!mounted) {
      pinController.dispose();
      confirmController.dispose();
      return false;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('유저 계정 PIN 설정'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '새 PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'PIN 확인',
                      border: OutlineInputBorder(),
                    ),
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
                  child: const Text('설정'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) {
      pinController.dispose();
      confirmController.dispose();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final pin = pinController.text.trim();
    pinController.dispose();
    confirmController.dispose();
    await _userPinService.setPin(prefs, pin: pin);
    if (!mounted) return true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('유저 계정 PIN이 설정되었습니다')));
    return true;
  }

  Future<void> _changeUserPin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_userPinService.isPinConfigured(prefs)) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('먼저 PIN을 설정하세요')));
      return;
    }

    if (!mounted) return;
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
    if (ok != true || !mounted) return;

    final didSet = await _showSetUserPinDialog();
    if (!didSet || !mounted) return;

    await prefs.setBool(PrefKeys.userPinEnabled, true);
    final configuredNow = _userPinService.isPinConfigured(prefs);
    setState(() {
      _userPinEnabled = configuredNow;
      _userPinConfigured = configuredNow;
    });
  }

  Future<void> _disableBackupEncryption() async {
    if (_isLoading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('암호화 설정 해지'),
          content: const Text(
            '백업 암호화를 해지할까요?\n'
            '저장된 백업 암호가 삭제되고, 이후 백업은 암호 없이 저장될 수 있습니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('해지'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.backupEncryptionEnabled, false);
    await prefs.setBool(PrefKeys.backupTwoFactorEnabled, false);
    await BackupService().clearStoredBackupEncryptionPassword();
    if (!mounted) return;
    setState(() {
      _backupEncryptionEnabled = false;
      _backupTwoFactorEnabled = false;
      _isLoading = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('백업 암호화 설정을 해지했습니다')));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        BackgroundHelper.colorNotifier,
        BackgroundHelper.typeNotifier,
        BackgroundHelper.imagePathNotifier,
        BackgroundHelper.blurNotifier,
      ]),
      builder: (context, _) {
        final bgColor = BackgroundHelper.colorNotifier.value;
        final bgType = BackgroundHelper.typeNotifier.value;
        final bgImagePath = BackgroundHelper.imagePathNotifier.value;
        final bgBlur = BackgroundHelper.blurNotifier.value;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: const Text('설정'),
            backgroundColor: bgType == 'image' ? Colors.transparent : null,
            elevation: 0,
          ),
          extendBodyBehindAppBar: bgType == 'image',
          body: Stack(
            children: [
              if (bgType == 'image' && bgImagePath != null) ...[
                Positioned.fill(
                  child: Image.file(
                    File(bgImagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        ColoredBox(color: bgColor),
                  ),
                ),
                if (bgBlur > 0)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: bgBlur, sigmaY: bgBlur),
                      child: const ColoredBox(color: Colors.transparent),
                    ),
                  ),
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                ),
              ],
              ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  _buildSectionHeader(context, '애플리케이션'),
                  _buildSettingsCard(
                    context,
                    icon: Icons.tune_outlined,
                    title: '애플리케이션 설정',
                    subtitle: '테마와 배경을 앱 안에서 바로 조정합니다.',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ApplicationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, '보안 및 백업'),
                  _buildSettingsCard(
                    context,
                    icon: Icons.lock_open_outlined,
                    title: '백업 암호화 해지',
                    subtitle:
                        (_backupEncryptionEnabled || _backupTwoFactorEnabled)
                            ? '상태: 사용 중'
                            : '상태: 미사용',
                    enabled: !_isLoading &&
                        (_backupEncryptionEnabled || _backupTwoFactorEnabled),
                    onTap: _disableBackupEncryption,
                  ),
                  const SizedBox(height: 12),
                  _buildSwitchCard(
                    context,
                    icon: Icons.password_outlined,
                    title: '비밀번호 사용',
                    subtitle: _userPasswordConfigured
                        ? (_userPasswordEnabled ? '상태: 사용 중' : '상태: 미사용')
                        : '상태: 미설정',
                    value: _userPasswordEnabled,
                    onChanged: _isLoading ? null : _setUserPasswordEnabled,
                  ),
                  if (_userPasswordEnabled) ...[
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      context,
                      icon: Icons.lock_reset_outlined,
                      title: '비밀번호 변경',
                      subtitle: '기존 비밀번호 확인 후 변경',
                      onTap: _isLoading ? null : _changeUserPassword,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildSwitchCard(
                    context,
                    icon: Icons.lock_outline,
                    title: '사용자 계정 PIN 사용',
                    subtitle: _userPinConfigured
                        ? (_userPinEnabled ? '상태: 사용 중' : '상태: 미사용')
                        : '상태: 미설정',
                    value: _userPinEnabled,
                    onChanged: _isLoading ? null : _setUserPinEnabled,
                  ),
                  if (_userPinEnabled) ...[
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      context,
                      icon: Icons.pin_outlined,
                      title: 'PIN 변경',
                      subtitle: '기존 PIN 확인 후 변경',
                      onTap: _isLoading ? null : _changeUserPin,
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildSwitchCard(
                    context,
                    icon: Icons.fingerprint,
                    title: '기기 인증 사용',
                    subtitle: '지문/잠금화면 등 기기 인증을 사용합니다.',
                    value: _userBiometricEnabled,
                    onChanged: _isLoading ? null : _setUserBiometricEnabled,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, '입력 편의'),
                  _buildSwitchCard(
                    context,
                    icon: IconCatalog.keyboardAltOutlined,
                    title: '숫자 입력 보조',
                    subtitle: '숫자 입력 시 0/00/000 버튼을 표시합니다.',
                    value: _zeroQuickButtonsEnabled,
                    onChanged: _isLoading ? null : _setZeroQuickButtonsEnabled,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, '정보'),
                  _buildSettingsCard(
                    context,
                    icon: Icons.description_outlined,
                    title: '오픈소스 라이선스',
                    subtitle: 'vccode1 라이선스 정보 확인',
                    onTap: () {
                      showLicensePage(
                        context: context,
                        applicationName: 'vccode1',
                        applicationLegalese: 'Copyright (c) 2025 com.example',
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        elevation: 0,
        color: scheme.surfaceContainerLow.withValues(alpha: 0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: scheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  IconCatalog.chevronRight,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
