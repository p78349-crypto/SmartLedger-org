import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/root_pin_service.dart';
import '../utils/dev_overrides.dart';
import '../utils/icon_catalog.dart';
import '../utils/pref_keys.dart';
import '../utils/snackbar_utils.dart';

class RootAuthGate extends StatefulWidget {
  const RootAuthGate({super.key, required this.child});

  final Widget child;

  @override
  State<RootAuthGate> createState() => _RootAuthGateState();
}

class _RootAuthGateState extends State<RootAuthGate> {
  bool _checking = true;
  bool _enabled = false;
  bool _authorized = false;
  String? _rootSecurityMode;
  String? _rootSecurityLevel; // 'single' or 'dual'

  // 활성화된 보안 방식들
  bool _pinEnabled = false;
  bool _biometricEnabled = false;
  bool _passwordEnabled = false;

  final AuthService _authService = AuthService();
  final RootPinService _rootPinService = RootPinService();

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    // Dev override: compile-time flag to bypass security during prototype.
    // See: lib/utils/dev_overrides.dart
    if (kDevBypassSecurity) {
      if (!mounted) return;
      setState(() {
        _enabled = false;
        _checking = false;
        _authorized = true;
      });
      return;
    }

    // Developer/testing bypass via SharedPreferences key.
    // Disabled in release builds.
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

    final enabled = prefs.getBool(PrefKeys.rootAuthEnabled) ?? false;
    final securityMode = prefs.getString(PrefKeys.rootSecurityMode);
    final securityLevel =
        prefs.getString(PrefKeys.rootSecurityLevel) ?? 'single';

    final pinEnabled = prefs.getBool(PrefKeys.rootPinEnabled) ?? false;
    final biometricEnabled =
        prefs.getBool(PrefKeys.rootBiometricEnabled) ?? false;
    final passwordEnabled =
        prefs.getBool(PrefKeys.rootPasswordEnabled) ?? false;

    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _rootSecurityMode = securityMode;
      _rootSecurityLevel = securityLevel;
      _pinEnabled = pinEnabled;
      _biometricEnabled = biometricEnabled;
      _passwordEnabled = passwordEnabled;
      _checking = false;
      _authorized = !enabled;
    });

    if (enabled && !_authorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _promptAuthentication(prefs);
      });
    }
  }

  Future<void> _promptAuthentication(SharedPreferences prefs) async {
    if (!mounted || _authorized) return;

    // 2중 인증 모드인지 확인
    final isDualAuth = _rootSecurityLevel == 'dual';

    if (isDualAuth) {
      // 2중 인증: 활성화된 2개 방식을 모두 통과해야 함
      await _authenticateDual(prefs);
    } else {
      // 단일 인증: 활성화된 방식 중 하나만 통과하면 됨
      await _authenticateSingle(prefs);
    }
  }

  Future<void> _authenticateSingle(SharedPreferences prefs) async {
    final methods = _enabledMethods();

    if (methods.isEmpty) {
      // 레거시: rootSecurityMode로 폴백
      final mode = _rootSecurityMode ?? 'password';
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
                break;
              case 'biometric':
                label = '지문/생체인식';
                icon = Icons.fingerprint;
                break;
              case 'password':
                label = '비밀번호';
                icon = Icons.password;
                break;
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

  // 기존 _authenticatePin, _authenticateBiometric, _authenticatePassword는
  // 내부적으로 성공 시 _authorized = true로 설정하므로
  // 결과를 반환하는 버전을 추가

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

  Future<bool> _authenticatePinWithResult(SharedPreferences prefs) async {
    final pinController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ROOT PIN 입력'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ROOT 접근을 위해 PIN을 입력하세요.'),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              decoration: const InputDecoration(
                labelText: 'PIN (6자리)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pin = pinController.text.trim();
              if (pin.length != 6 || !RegExp(r'^\d{6}$').hasMatch(pin)) {
                SnackbarUtils.showWarning(dialogContext, 'PIN은 6자리 숫자여야 합니다');
                return;
              }

              final verifyResult = await _rootPinService.verifyPinWithPolicy(
                prefs,
                pin: pin,
              );

              if (verifyResult.status == RootPinPolicyStatus.success) {
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              } else if (verifyResult.status == RootPinPolicyStatus.locked) {
                if (!dialogContext.mounted) return;
                final remaining = verifyResult.lockRemaining?.inSeconds ?? 0;
                SnackbarUtils.showError(
                  dialogContext,
                  'PIN 입력이 일시 잠금되었습니다. $remaining초 후 재시도하세요.',
                );
              } else {
                if (!dialogContext.mounted) return;
                SnackbarUtils.showError(dialogContext, 'PIN이 일치하지 않습니다.');
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    pinController.dispose();
    return result == true;
  }

  Future<bool> _authenticateBiometricWithResult(SharedPreferences prefs) async {
    final result = await _authService.authenticateDevice(
      reason: 'ROOT 접근을 위해 인증이 필요합니다',
    );

    if (result.ok) {
      return true;
    } else if (result.status == AuthStatus.unavailable) {
      // 생체인식 사용 불가 시 다른 방식으로 대체
      if (_passwordEnabled) {
        return _authenticatePasswordWithResult(prefs);
      } else if (_pinEnabled) {
        return _authenticatePinWithResult(prefs);
      }
      return _authenticatePasswordWithResult(prefs);
    } else {
      if (!mounted) return false;
      SnackbarUtils.showError(context, '생체인식 실패');
      return false;
    }
  }

  Future<bool> _authenticatePasswordWithResult(SharedPreferences prefs) async {
    final passwordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ROOT 비밀번호 입력'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ROOT 접근을 위해 비밀번호를 입력하세요.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final password = passwordController.text.trim();
              if (password.isEmpty) {
                SnackbarUtils.showWarning(dialogContext, '비밀번호를 입력하세요');
                return;
              }

              // 별도 비밀번호 저장소에서 검증 (레거시 호환: PIN 저장소 폴백)
              final RootPinPolicyResult verifyResult;
              if (_rootPinService.isPasswordConfigured(prefs)) {
                verifyResult = await _rootPinService.verifyPasswordWithPolicy(
                  prefs,
                  password: password,
                );
              } else {
                verifyResult = await _rootPinService.verifyPinWithPolicy(
                  prefs,
                  pin: password,
                );
              }

              if (verifyResult.status == RootPinPolicyStatus.success) {
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              } else if (verifyResult.status == RootPinPolicyStatus.locked) {
                if (!dialogContext.mounted) return;
                final remaining = verifyResult.lockRemaining?.inSeconds ?? 0;
                SnackbarUtils.showError(
                  dialogContext,
                  '비밀번호 입력이 일시 잠금되었습니다. $remaining초 후 재시도하세요.',
                );
              } else {
                if (!dialogContext.mounted) return;
                SnackbarUtils.showError(dialogContext, '비밀번호가 일치하지 않습니다.');
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );

    passwordController.dispose();
    return result == true;
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
        title: const Text('ROOT 보안 잠금'),
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
                'ROOT 기능 보호',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'ROOT 기능에 접근하려면 인증이 필요합니다.',
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
