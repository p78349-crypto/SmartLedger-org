library user_account_auth_gate;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/user_password_service.dart';
import '../services/user_pin_service.dart';
import '../utils/dev_overrides.dart';
import '../utils/icon_catalog.dart';
import '../utils/pref_keys.dart';
import '../utils/snackbar_utils.dart';

part 'user_account_auth_gate_dialogs.dart';

/// 사용자 계정 보안 게이트 (ROOT 보안 디자인 복제 – 단일/2중 인증 지원)
class UserAccountAuthGate extends StatefulWidget {
  const UserAccountAuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<UserAccountAuthGate> createState() => _UserAccountAuthGateState();
}

class _UserAccountAuthGateState extends State<UserAccountAuthGate> {
  final AuthService _authService = AuthService();
  final UserPinService _pinService = UserPinService();
  final UserPasswordService _passwordService = UserPasswordService();

  bool _checking = true;
  bool _enabled = false;
  bool _authorized = false;
  String? _securityMode;
  String _securityLevel = 'single'; // 'single' or 'dual'

  // 활성화된 보안 방식들
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  bool _passwordEnabled = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();

    // Dev bypass: compile-time flag
    if (kDevBypassSecurity) {
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _checking = false;
        _authorized = true;
      });
      return;
    }

    // Developer/testing bypass (debug only)
    if (!kReleaseMode &&
        prefs.getBool(PrefKeys.bypassSecurityForTesting) == true) {
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _checking = false;
        _authorized = true;
      });
      return;
    }

    final enabled = prefs.getBool(PrefKeys.userAuthEnabled) ?? false;
    final securityMode = prefs.getString(PrefKeys.userSecurityMode);
    final securityLevel =
        prefs.getString(PrefKeys.userSecurityLevel) ?? 'single';

    final pinEnabled = prefs.getBool(PrefKeys.userPinEnabled) ?? false;
    final biometricEnabled =
        prefs.getBool(PrefKeys.userBiometricEnabled) ?? false;
    final passwordEnabled =
        prefs.getBool(PrefKeys.userPasswordEnabled) ?? false;

    // 설정되었지만 실제 자격 증명이 없는 경우 비활성화
    final pinConfigured = _pinService.isPinConfigured(prefs);
    final passwordConfigured = _passwordService.isPasswordConfigured(prefs);

    final effectivePinEnabled = pinEnabled && pinConfigured;
    final effectivePasswordEnabled = passwordEnabled && passwordConfigured;
    final effectiveBiometricEnabled = biometricEnabled;

    final anyMethodEnabled =
        effectivePinEnabled ||
        effectivePasswordEnabled ||
        effectiveBiometricEnabled;

    if (!mounted) return;
    setState(() {
      _enabled = enabled && anyMethodEnabled;
      _securityMode = securityMode;
      _securityLevel = securityLevel;
      _pinEnabled = effectivePinEnabled;
      _biometricEnabled = effectiveBiometricEnabled;
      _passwordEnabled = effectivePasswordEnabled;
      _checking = false;
      _authorized = !(enabled && anyMethodEnabled);
    });

    if (_enabled && !_authorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptAuthentication(prefs);
      });
    }
  }

  // ──── 인증 흐름 (ROOT 패턴 복제) ────

  Future<void> _promptAuthentication(SharedPreferences prefs) async {
    if (!mounted || _authorized) return;

    final isDualAuth = _securityLevel == 'dual';

    if (isDualAuth) {
      await _authenticateDual(prefs);
    } else {
      await _authenticateSingle(prefs);
    }
  }

  Future<void> _authenticateSingle(SharedPreferences prefs) async {
    final methods = _enabledMethods();

    if (methods.isEmpty) {
      // 레거시: securityMode로 폴백
      final mode = _securityMode ?? 'password';
      final ok = await _runAuth(mode, prefs);
      if (ok) _setAuthorized();
      return;
    }

    if (methods.length == 1) {
      final ok = await _runAuth(methods.first, prefs);
      if (ok) _setAuthorized();
      return;
    }

    // 여러 개 중 선택
    final selected = await _showMethodSelectionDialog(methods);
    if (selected == null) return;
    final ok = await _runAuth(selected, prefs);
    if (ok) _setAuthorized();
  }

  Future<void> _authenticateDual(SharedPreferences prefs) async {
    final methods = _enabledMethods();

    if (methods.length != 2) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '2중 인증 설정이 올바르지 않습니다');
      return;
    }

    // 1차 인증
    final firstOk = await _runAuth(methods[0], prefs);
    if (!firstOk) return;

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('1차 인증 통과'),
        content: Text('2차 인증 (${_methodLabel(methods[1])})을 진행합니다.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('계속'),
          ),
        ],
      ),
    );

    // 2차 인증
    final secondOk = await _runAuth(methods[1], prefs);
    if (secondOk) {
      _setAuthorized();
      if (mounted) SnackbarUtils.showSuccess(context, '2중 인증 완료');
    }
  }

  Future<String?> _showMethodSelectionDialog(List<String> methods) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('인증 방식 선택'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: methods.map((method) {
            final String label;
            final IconData icon;
            switch (method) {
              case 'pin':
                label = 'PIN';
                icon = Icons.dialpad;
              case 'biometric':
                label = '지문/생체인식';
                icon = Icons.fingerprint;
              case 'password':
                label = '비밀번호';
                icon = Icons.password;
              default:
                label = method;
                icon = Icons.lock;
            }

            return Card(
              child: ListTile(
                leading: Icon(icon),
                title: Text(label),
                onTap: () => Navigator.of(context).pop(method),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  // ──── 유틸 ────

  List<String> _enabledMethods() {
    final methods = <String>[];
    if (_pinEnabled) methods.add('pin');
    if (_biometricEnabled) methods.add('biometric');
    if (_passwordEnabled) methods.add('password');
    return methods;
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'pin':
        return 'PIN';
      case 'biometric':
        return '지문/생체인식';
      case 'password':
        return '비밀번호';
      default:
        return method;
    }
  }

  void _setAuthorized() {
    if (!mounted) return;
    setState(() => _authorized = true);
  }

  // ──── 개별 인증 실행기 ────

  Future<bool> _authenticatePinWithResult(SharedPreferences prefs) async {
    if (!mounted) return false;
    return (await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return _UserPinDialog(prefs: prefs, service: _pinService);
          },
        )) ==
        true;
  }

  Future<bool> _authenticateBiometricWithResult(
    SharedPreferences prefs,
  ) async {
    final result = await _authService.authenticateDevice(
      reason: '사용자 계정에 접근하려면 인증이 필요합니다',
    );

    if (result.ok) return true;

    if (result.status == AuthStatus.unavailable) {
      // 생체인식 불가 시 대체 방식
      if (_passwordEnabled) return _authenticatePasswordWithResult(prefs);
      if (_pinEnabled) return _authenticatePinWithResult(prefs);
      return false;
    }

    if (!mounted) return false;
    SnackbarUtils.showError(context, '생체인식 실패');
    return false;
  }

  Future<bool> _authenticatePasswordWithResult(
    SharedPreferences prefs,
  ) async {
    if (!mounted) return false;
    return (await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return _UserPasswordDialog(
              prefs: prefs,
              service: _passwordService,
            );
          },
        )) ==
        true;
  }

  // ──── 통합 인증 실행기 ────

  Future<bool> _runAuth(String method, SharedPreferences prefs) async {
    switch (method) {
      case 'pin':
        return _authenticatePinWithResult(prefs);
      case 'biometric':
        return _authenticateBiometricWithResult(prefs);
      case 'password':
        return _authenticatePasswordWithResult(prefs);
      default:
        return _authenticatePasswordWithResult(prefs);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_enabled || _authorized) {
      return widget.child;
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('사용자 보안 잠금'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                IconCatalog.lockOutline,
                size: 64,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(height: 24),
              Text(
                '사용자 기능 보호',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '이 항목에 접근하려면 인증이 필요합니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await _promptAuthentication(prefs);
                },
                icon: const Icon(Icons.lock_open),
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
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('닫기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
