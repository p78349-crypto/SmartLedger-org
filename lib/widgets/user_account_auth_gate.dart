import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_ledger/services/auth_service.dart';
import 'package:smart_ledger/services/user_password_service.dart';
import 'package:smart_ledger/services/user_pin_service.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

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

  bool _ready = false;
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    final pinEnabled = prefs.getBool(PrefKeys.userPinEnabled) ?? false;
    final passwordEnabled =
        prefs.getBool(PrefKeys.userPasswordEnabled) ?? false;
    final biometricEnabled =
        prefs.getBool(PrefKeys.userBiometricEnabled) ?? false;

    final pinConfigured = _pinService.isPinConfigured(prefs);
    final passwordConfigured = _passwordService.isPasswordConfigured(prefs);

    if (pinEnabled && !pinConfigured) {
      await prefs.setBool(PrefKeys.userPinEnabled, false);
    }
    if (passwordEnabled && !passwordConfigured) {
      await prefs.setBool(PrefKeys.userPasswordEnabled, false);
    }

    final effectivePinEnabled = pinEnabled && pinConfigured;
    final effectivePasswordEnabled = passwordEnabled && passwordConfigured;
    final effectiveBiometricEnabled = biometricEnabled;

    final anyEnabled =
        effectivePinEnabled ||
        effectivePasswordEnabled ||
        effectiveBiometricEnabled;

    if (!mounted) return;
    setState(() {
      _ready = true;
      _authorized = !anyEnabled;
    });

    if (!anyEnabled) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptUntilAuthorized(
        prefs,
        pinEnabled: effectivePinEnabled,
        passwordEnabled: effectivePasswordEnabled,
        biometricEnabled: effectiveBiometricEnabled,
      );
    });
  }

  Future<void> _promptUntilAuthorized(
    SharedPreferences prefs, {
    required bool pinEnabled,
    required bool passwordEnabled,
    required bool biometricEnabled,
  }) async {
    if (!mounted) return;

    while (mounted && !_authorized) {
      final result = await showDialog<_UserAuthChoiceResult>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return _UserAuthChoiceDialog(
            canPin: pinEnabled,
            canPassword: passwordEnabled,
            canBiometric: biometricEnabled,
          );
        },
      );

      if (!mounted) return;
      if (result == null || result == _UserAuthChoiceResult.exit) {
        Navigator.of(context).maybePop();
        return;
      }

      final ok = await _runChoice(prefs, result);
      if (!mounted) return;
      if (ok) {
        setState(() => _authorized = true);
        return;
      }
    }
  }

  Future<bool> _runChoice(
    SharedPreferences prefs,
    _UserAuthChoiceResult choice,
  ) async {
    switch (choice) {
      case _UserAuthChoiceResult.biometric:
        final result = await _authService.authenticateDevice(
          reason: '계정에 접근하려면 인증이 필요합니다',
        );
        return result.ok;
      case _UserAuthChoiceResult.pin:
        return (await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (dialogContext) {
                return _UserPinDialog(prefs: prefs, service: _pinService);
              },
            )) ==
            true;
      case _UserAuthChoiceResult.password:
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
      case _UserAuthChoiceResult.exit:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: SizedBox.shrink());
    }

    if (!_authorized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(IconCatalog.lockOutline, size: 48),
              SizedBox(height: 12),
              Text('인증 중...'),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}

enum _UserAuthChoiceResult { biometric, pin, password, exit }

class _UserAuthChoiceDialog extends StatelessWidget {
  const _UserAuthChoiceDialog({
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
      title: const Text('계정 인증'),
      content: const Text('사용할 인증 방법을 선택하세요.'),
      actions: [
        if (canBiometric)
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_UserAuthChoiceResult.biometric),
            icon: const Icon(IconCatalog.fingerprint),
            label: const Text('지문'),
          ),
        if (canPin)
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_UserAuthChoiceResult.pin),
            icon: const Icon(IconCatalog.lockOutline),
            label: const Text('PIN'),
          ),
        if (canPassword)
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_UserAuthChoiceResult.password),
            icon: const Icon(IconCatalog.passwordOutlined),
            label: const Text('비번'),
          ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_UserAuthChoiceResult.exit),
          child: const Text('나가기'),
        ),
      ],
    );
  }
}

class _UserPinDialog extends StatefulWidget {
  const _UserPinDialog({required this.prefs, required this.service});

  final SharedPreferences prefs;
  final UserPinService service;

  @override
  State<_UserPinDialog> createState() => _UserPinDialogState();
}

class _UserPinDialogState extends State<_UserPinDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;
  String? _message;

  Future<void> _submit() async {
    if (_busy) return;

    final pin = _controller.text.trim();
    if (pin.isEmpty) {
      setState(() => _message = 'PIN을 입력하세요.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    final result = await widget.service.verifyPinWithPolicy(
      widget.prefs,
      pin: pin,
    );

    if (!mounted) return;

    if (result.status == UserPinPolicyStatus.success) {
      Navigator.of(context).pop(true);
      return;
    }

    if (result.status == UserPinPolicyStatus.locked) {
      final seconds = result.lockRemaining?.inSeconds ?? 0;
      setState(() {
        _busy = false;
        _message = '잠금 상태입니다. $seconds초 후 다시 시도하세요.';
      });
      return;
    }

    final attempts = result.failedAttempts ?? 0;
    final warning = (result.showWarning ?? false) ? ' (경고: $attempts회 실패)' : '';
    setState(() {
      _busy = false;
      _message = 'PIN이 올바르지 않습니다.$warning';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('PIN 입력'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'PIN',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('확인'),
        ),
      ],
    );
  }
}

class _UserPasswordDialog extends StatefulWidget {
  const _UserPasswordDialog({required this.prefs, required this.service});

  final SharedPreferences prefs;
  final UserPasswordService service;

  @override
  State<_UserPasswordDialog> createState() => _UserPasswordDialogState();
}

class _UserPasswordDialogState extends State<_UserPasswordDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;
  String? _message;

  Future<void> _submit() async {
    if (_busy) return;

    final password = _controller.text;
    if (password.trim().isEmpty) {
      setState(() => _message = '비밀번호를 입력하세요.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    final result = await widget.service.verifyPasswordWithPolicy(
      widget.prefs,
      password: password,
    );

    if (!mounted) return;

    if (result.status == UserPasswordPolicyStatus.success) {
      Navigator.of(context).pop(true);
      return;
    }

    if (result.status == UserPasswordPolicyStatus.locked) {
      final seconds = result.lockRemaining?.inSeconds ?? 0;
      setState(() {
        _busy = false;
        _message = '잠금 상태입니다. $seconds초 후 다시 시도하세요.';
      });
      return;
    }

    final attempts = result.failedAttempts ?? 0;
    final warning = (result.showWarning ?? false) ? ' (경고: $attempts회 실패)' : '';
    setState(() {
      _busy = false;
      _message = '비밀번호가 올바르지 않습니다.$warning';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('비밀번호 입력'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: '비밀번호',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: const Text('확인'),
        ),
      ],
    );
  }
}

