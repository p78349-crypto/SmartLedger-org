library user_account_auth_gate;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/user_password_service.dart';
import '../services/user_pin_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/pref_keys.dart';

part 'user_account_auth_gate_dialogs.dart';

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
        // Stop the automatic prompt loop, but don't pop.
        // The user can re-trigger it via the "Unlock" button.
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
      final theme = Theme.of(context);
      return Scaffold(
        appBar: AppBar(
          title: const Text('보안 잠금'),
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
                  '기능 보호',
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
                    final pinEnabled = prefs.getBool(PrefKeys.userPinEnabled) ?? false;
                    final passwordEnabled =
                        prefs.getBool(PrefKeys.userPasswordEnabled) ?? false;
                    final biometricEnabled =
                        prefs.getBool(PrefKeys.userBiometricEnabled) ?? false;

                    _promptUntilAuthorized(
                      prefs,
                      pinEnabled: pinEnabled && _pinService.isPinConfigured(prefs),
                      passwordEnabled: passwordEnabled && _passwordService.isPasswordConfigured(prefs),
                      biometricEnabled: biometricEnabled,
                    );
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

    return widget.child;
  }
}

enum _UserAuthChoiceResult { biometric, pin, password, exit }
