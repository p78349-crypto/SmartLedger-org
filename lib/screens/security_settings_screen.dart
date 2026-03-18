import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '_verify_current_user_password_dialog.dart';
import '_verify_current_user_pin_dialog.dart';
import '../services/auth_service.dart';
import '../services/backup_service.dart';
import '../services/user_password_service.dart';
import '../services/user_pin_service.dart';
import '../utils/pref_keys.dart';
import '../utils/icon_catalog.dart';
import '../utils/online_password_key_backup_facade.dart';
import '../services/user_pref_service.dart';
part 'security_settings_screen_logic.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen>
    with WidgetsBindingObserver {
  bool _isLoading = true;

  bool _userPasswordEnabled = false;
  bool _userPasswordConfigured = false;

  bool _userPinEnabled = false;
  bool _userPinConfigured = false;

  bool _userBiometricEnabled = false;

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
      _load();
    }
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    final userPinEnabled = prefs.getBool(PrefKeys.userPinEnabled) ?? false;
    final userPinConfigured = _userPinService.isPinConfigured(prefs);

    final userPasswordEnabled =
        prefs.getBool(PrefKeys.userPasswordEnabled) ?? false;
    final userPasswordConfigured = _userPasswordService.isPasswordConfigured(
      prefs,
    );

    final userBiometricEnabled =
        prefs.getBool(PrefKeys.userBiometricEnabled) ?? false;

    if (userPinEnabled && !userPinConfigured) {
      await prefs.setBool(PrefKeys.userPinEnabled, false);
    }
    if (userPasswordEnabled && !userPasswordConfigured) {
      await prefs.setBool(PrefKeys.userPasswordEnabled, false);
    }

    if (!mounted) return;
    setState(() {
      _userPinEnabled = userPinEnabled && userPinConfigured;
      _userPinConfigured = userPinConfigured;
      _userPasswordEnabled = userPasswordEnabled && userPasswordConfigured;
      _userPasswordConfigured = userPasswordConfigured;
      _userBiometricEnabled = userBiometricEnabled;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(IconCatalog.verifiedUserOutlined),
            SizedBox(width: 8),
            Text('보안설정'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(theme, '사용자 계정 보안'),
          _infoCard(
            icon: Icons.info_outline,
            message: '보안 방식을 2개 이상 설정하면 2중 인증을 사용할 수 있습니다.',
          ),
          const SizedBox(height: 12),
          _switchCard(
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
            _navCard(
              icon: Icons.lock_reset_outlined,
              title: '비밀번호 변경',
              subtitle: '기존 비밀번호 확인 후 변경',
              onTap: _isLoading ? null : _changeUserPassword,
            ),
          ],
          const SizedBox(height: 12),
          _switchCard(
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
            _navCard(
              icon: Icons.pin_outlined,
              title: 'PIN 변경',
              subtitle: '기존 PIN 확인 후 변경',
              onTap: _isLoading ? null : _changeUserPin,
            ),
          ],
          const SizedBox(height: 12),
          _switchCard(
            icon: Icons.fingerprint,
            title: '기기 인증 사용',
            subtitle: '지문/잠금화면 등 기기 인증을 사용합니다.',
            value: _userBiometricEnabled,
            onChanged: _isLoading ? null : _setUserBiometricEnabled,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _navCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: onTap,
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
                      style: theme.textTheme.bodySmall?.copyWith(
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
    );
  }

  Widget _infoCard({required IconData icon, required String message}) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerLow.withValues(alpha: 0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 18, color: scheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchCard({
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
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
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
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
