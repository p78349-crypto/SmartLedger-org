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

    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _rootSecurityMode = securityMode;
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

    final mode = _rootSecurityMode;
    
    if (mode == null || mode.isEmpty) {
      // Fallback: legacy password
      await _authenticatePassword(prefs);
      return;
    }

    switch (mode) {
      case 'pin':
        await _authenticatePin(prefs);
        break;
      case 'biometric':
        await _authenticateBiometric(prefs);
        break;
      case 'password':
        await _authenticatePassword(prefs);
        break;
      default:
        await _authenticatePassword(prefs);
    }
  }

  Future<void> _authenticatePin(SharedPreferences prefs) async {
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
              if (pin.length != 6) {
                SnackbarUtils.showWarning(dialogContext, 'PIN은 6자리여야 합니다');
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

    if (result == true) {
      if (!mounted) return;
      setState(() => _authorized = true);
    }
  }

  Future<void> _authenticateBiometric(SharedPreferences prefs) async {
    final result = await _authService.authenticateDevice(
      reason: 'ROOT 접근을 위해 인증이 필요합니다',
    );

    if (result.ok) {
      if (!mounted) return;
      setState(() => _authorized = true);
    } else if (result.status == AuthStatus.unavailable) {
      await _authenticatePassword(prefs);
    } else {
      if (!mounted) return;
      SnackbarUtils.showError(context, '생체인식 실패');
    }
  }

  Future<void> _authenticatePassword(SharedPreferences prefs) async {
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

              // Use RootPinService because RootSecuritySetupScreen stores ROOT password there.
              final verifyResult = await _rootPinService.verifyPinWithPolicy(
                prefs,
                pin: password,
              );

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

    if (result == true) {
      if (!mounted) return;
      setState(() => _authorized = true);
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
