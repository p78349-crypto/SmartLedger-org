import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../screens/_verify_current_user_password_dialog.dart';
import '../screens/_verify_current_user_pin_dialog.dart';
import '../services/auth_service.dart';
import '../services/user_password_service.dart';
import '../services/user_pin_service.dart';
import '../utils/dev_overrides.dart';
import '../utils/pref_keys.dart';

/// A lightweight gate for asset-related standalone routes.
///
/// - Respects the asset security toggle [PrefKeys.biometricAuthEnabled].
/// - Uses the unified user auth methods (password / PIN / device auth).
/// - Writes the asset session marker [PrefKeys.assetAuthSessionUntilMs] on
///   success.
class AssetRouteAuthGate extends StatefulWidget {
  const AssetRouteAuthGate({
    super.key,
    required this.child,
    this.reason = '자산 정보에 접근하려면 인증이 필요합니다',
  });

  final Widget child;
  final String reason;

  @override
  State<AssetRouteAuthGate> createState() => _AssetRouteAuthGateState();
}

class _AssetRouteAuthGateState extends State<AssetRouteAuthGate> {
  final AuthService _authService = AuthService();
  final UserPinService _userPinService = UserPinService();
  final UserPasswordService _userPasswordService = UserPasswordService();

  bool _ready = false;
  bool _authorized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();

    // Dev override: compile-time flag to bypass security during prototype.
    // This precedes any persisted pref and is intended for temporary use.
    // See: lib/utils/dev_overrides.dart (uses --dart-define)
    // See: lib/utils/dev_overrides.dart
    if (kDevBypassSecurity) {
      if (!mounted) return;
      setState(() {
        _ready = true;
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
        _ready = true;
        _authorized = true;
      });
      return;
    }

    final enabled = prefs.getBool(PrefKeys.biometricAuthEnabled) ?? false;
    final sessionActive = _authService.isSessionActive(
      prefs.getInt(PrefKeys.assetAuthSessionUntilMs),
    );

    if (!mounted) return;
    setState(() {
      _ready = true;
      _authorized = !enabled || sessionActive;
    });

    if (!enabled || sessionActive) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptAndAuthorize(prefs);
    });
  }

  Future<void> _promptAndAuthorize(SharedPreferences prefs) async {
    if (!mounted) return;

    try {
      await _authenticateForAssetProtection(
        prefs: prefs,
        reason: widget.reason,
      );

      if (!mounted) return;
      setState(() => _authorized = true);
    } catch (_) {
      // Do not pop automatically. Let the user see the "Locked" state
      // with a manual unlock button.
    }
  }

  Future<void> _authenticateForAssetProtection({
    required SharedPreferences prefs,
    required String reason,
  }) async {
    final pinEnabled = prefs.getBool(PrefKeys.userPinEnabled) ?? false;
    final passwordEnabled =
        prefs.getBool(PrefKeys.userPasswordEnabled) ?? false;
    final biometricEnabled =
        prefs.getBool(PrefKeys.userBiometricEnabled) ?? false;

    final pinConfigured = _userPinService.isPinConfigured(prefs);
    final passwordConfigured = _userPasswordService.isPasswordConfigured(prefs);

    // Only offer biometric option when device actually supports it.
    final deviceSupportsAuth = await _authService.canUseDeviceAuth();

    final canPin = pinEnabled && pinConfigured;
    final canPassword = passwordEnabled && passwordConfigured;
    final canBiometric = biometricEnabled && deviceSupportsAuth;

    final any = canPin || canPassword || canBiometric;

    if (!any) {
      final result = await _authService.authenticateDevice(reason: reason);

      // If device auth is not available (e.g., emulator/no biometrics),
      // allow access as a pragmatic fallback but set the session marker so
      // the UX continues to behave like an authorized session.
      if (result.status == AuthStatus.unavailable) {
        await prefs.setInt(
          PrefKeys.assetAuthSessionUntilMs,
          DateTime.now()
              .add(AuthService.assetSessionTimeout)
              .millisecondsSinceEpoch,
        );
        return;
      }

      if (!result.ok) {
        throw Exception(result.message ?? '인증이 취소되었습니다');
      }

      await prefs.setInt(
        PrefKeys.assetAuthSessionUntilMs,
        DateTime.now()
            .add(AuthService.assetSessionTimeout)
            .millisecondsSinceEpoch,
      );
      return;
    }

    if (!mounted) return;
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

    if (!mounted) return;
    if (choice == null || choice == _AssetAuthChoice.exit) {
      throw Exception('인증이 취소되었습니다');
    }

    switch (choice) {
      case _AssetAuthChoice.biometric:
        final result = await _authService.authenticateDevice(reason: reason);
        if (!result.ok) {
          throw Exception(result.message ?? '인증이 취소되었습니다');
        }
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
        if (ok != true) throw Exception('PIN 인증이 취소되었습니다');
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
        if (ok != true) throw Exception('비밀번호 인증이 취소되었습니다');
        break;
      case _AssetAuthChoice.exit:
        throw Exception('인증이 취소되었습니다');
    }

    await prefs.setInt(
      PrefKeys.assetAuthSessionUntilMs,
      DateTime.now()
          .add(AuthService.assetSessionTimeout)
          .millisecondsSinceEpoch,
    );
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
                  Icons.lock_outline,
                  size: 64,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(height: 24),
                Text(
                  '자산 정보 보호',
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
                    _promptAndAuthorize(prefs);
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
            icon: const Icon(Icons.fingerprint),
            label: const Text('지문'),
          ),
        if (canPin)
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(_AssetAuthChoice.pin),
            icon: const Icon(Icons.lock_outline),
            label: const Text('PIN'),
          ),
        if (canPassword)
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).pop(_AssetAuthChoice.password),
            icon: const Icon(Icons.password_outlined),
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
