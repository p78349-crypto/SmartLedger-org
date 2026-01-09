import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'root_pin_service.dart';
import '../utils/pref_keys.dart';

enum AuthScope { asset, root, backupRestore, screenSaverExit }

enum AuthStatus { success, canceled, locked, unavailable, failed }

class AuthResult {
  const AuthResult._(this.status, {this.message, this.remaining});

  final AuthStatus status;
  final String? message;
  final Duration? remaining;

  bool get ok => status == AuthStatus.success;

  static const AuthResult success = AuthResult._(AuthStatus.success);

  static AuthResult canceled([String? message]) {
    return AuthResult._(AuthStatus.canceled, message: message);
  }

  static AuthResult unavailable([String? message]) {
    return AuthResult._(AuthStatus.unavailable, message: message);
  }

  static AuthResult failed([String? message]) {
    return AuthResult._(AuthStatus.failed, message: message);
  }

  static AuthResult locked(Duration remaining, [String? message]) {
    return AuthResult._(
      AuthStatus.locked,
      message: message,
      remaining: remaining,
    );
  }
}

typedef PromptPin = Future<bool> Function(SharedPreferences prefs);

typedef GetNowMs = int Function();

class AuthService {
  AuthService._internal({LocalAuthentication? localAuth, GetNowMs? nowMs})
    : _localAuth = localAuth ?? LocalAuthentication(),
      _nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  final LocalAuthentication _localAuth;
  final RootPinService _rootPinService = RootPinService();
  final GetNowMs _nowMs;

  static const Duration rootSessionTimeout = Duration(minutes: 1);
  static const Duration assetSessionTimeout = Duration(minutes: 1);

  static const int screenSaverExitMaxFailedAttempts = 5;
  static const Duration screenSaverExitLockDuration = Duration(minutes: 10);

  bool isSessionActive(int? untilMs) {
    if (untilMs == null) return false;
    return _nowMs() < untilMs;
  }

  Future<bool> canUseDeviceAuth() async {
    return (await _localAuth.canCheckBiometrics) ||
        (await _localAuth.isDeviceSupported());
  }

  Future<AuthResult> authenticateDevice({required String reason}) async {
    final canAuth = await canUseDeviceAuth();
    if (!canAuth) {
      return AuthResult.unavailable('이 기기에서 기기 인증을 사용할 수 없습니다');
    }

    final ok = await _localAuth.authenticate(localizedReason: reason);

    if (!ok) {
      return AuthResult.canceled('인증이 취소되었습니다');
    }
    return AuthResult.success;
  }

  Future<AuthResult> authenticateScreenSaverExit({
    required SharedPreferences prefs,
  }) async {
    final lockedUntilMs = prefs.getInt(
      PrefKeys.screenSaverExitAuthLockedUntilMs,
    );
    if (lockedUntilMs != null) {
      final remainingMs = lockedUntilMs - _nowMs();
      if (remainingMs > 0) {
        final remaining = Duration(milliseconds: remainingMs);
        return AuthResult.locked(remaining, '보호기 종료 인증이 잠금 상태입니다');
      }

      await prefs.remove(PrefKeys.screenSaverExitAuthLockedUntilMs);
      await prefs.remove(PrefKeys.screenSaverExitAuthFailedAttempts);
    }

    final canAuth = await canUseDeviceAuth();
    if (!canAuth) {
      return AuthResult.success;
    }

    final result = await authenticateDevice(reason: '화면 보호기를 종료하려면 인증이 필요합니다');

    if (result.ok) {
      await prefs.remove(PrefKeys.screenSaverExitAuthFailedAttempts);
      await prefs.remove(PrefKeys.screenSaverExitAuthLockedUntilMs);
      return AuthResult.success;
    }

    final current =
        prefs.getInt(PrefKeys.screenSaverExitAuthFailedAttempts) ?? 0;
    final next = current + 1;
    if (next >= screenSaverExitMaxFailedAttempts) {
      await prefs.setInt(
        PrefKeys.screenSaverExitAuthLockedUntilMs,
        DateTime.now().add(screenSaverExitLockDuration).millisecondsSinceEpoch,
      );
      await prefs.remove(PrefKeys.screenSaverExitAuthFailedAttempts);
      return AuthResult.locked(
        screenSaverExitLockDuration,
        '보호기 종료 인증이 잠금 처리되었습니다',
      );
    }

    await prefs.setInt(PrefKeys.screenSaverExitAuthFailedAttempts, next);
    return AuthResult.failed();
  }

  Future<AuthResult> ensureAuthorizedForRoot({
    required SharedPreferences prefs,
    required PromptPin promptPin,
  }) async {
    final rootAuthEnabled =
        prefs.getBool(PrefKeys.rootAuthEnabled) ??
        (prefs.getBool(PrefKeys.biometricAuthEnabled) ?? true);
    if (!rootAuthEnabled) return AuthResult.success;

    final mode = prefs.getString(PrefKeys.rootAuthMode) ?? 'integrated';

    final rootPinEnabled = prefs.getBool(PrefKeys.rootPinEnabled) ?? false;
    final rootPinConfigured = _rootPinService.isPinConfigured(prefs);
    if (rootPinEnabled && !rootPinConfigured) {
      await prefs.setBool(PrefKeys.rootPinEnabled, false);
    }

    final assetSessionActive = isSessionActive(
      prefs.getInt(PrefKeys.assetAuthSessionUntilMs),
    );
    final rootSessionActive = isSessionActive(
      prefs.getInt(PrefKeys.rootAuthSessionUntilMs),
    );

    if (mode == 'integrated') {
      if (!assetSessionActive) {
        final device = await authenticateDevice(
          reason: 'ROOT 기능에 접근하려면 인증이 필요합니다',
        );
        if (!device.ok) return device;

        await prefs.setInt(
          PrefKeys.assetAuthSessionUntilMs,
          DateTime.now().add(assetSessionTimeout).millisecondsSinceEpoch,
        );
      }

      final shouldRequirePin =
          (prefs.getBool(PrefKeys.rootPinEnabled) ?? false) &&
          _rootPinService.isPinConfigured(prefs);
      if (shouldRequirePin && !rootSessionActive) {
        final ok = await promptPin(prefs);
        if (!ok) return AuthResult.canceled('PIN 입력이 취소되었습니다');

        await prefs.setInt(
          PrefKeys.rootAuthSessionUntilMs,
          DateTime.now().add(rootSessionTimeout).millisecondsSinceEpoch,
        );
      }

      return AuthResult.success;
    }

    // separate
    if (!assetSessionActive) {
      final device = await authenticateDevice(reason: '자산 인증(1단계)을 진행합니다');
      if (!device.ok) return device;

      await prefs.setInt(
        PrefKeys.assetAuthSessionUntilMs,
        DateTime.now().add(assetSessionTimeout).millisecondsSinceEpoch,
      );
    }

    if (!rootSessionActive) {
      final shouldRequirePin =
          (prefs.getBool(PrefKeys.rootPinEnabled) ?? false) &&
          _rootPinService.isPinConfigured(prefs);
      if (shouldRequirePin) {
        final ok = await promptPin(prefs);
        if (!ok) return AuthResult.canceled('PIN 입력이 취소되었습니다');
      } else {
        final device = await authenticateDevice(
          reason: 'ROOT 추가 인증(2단계)을 진행합니다',
        );
        if (!device.ok) return device;
      }

      await prefs.setInt(
        PrefKeys.rootAuthSessionUntilMs,
        DateTime.now().add(rootSessionTimeout).millisecondsSinceEpoch,
      );
    }

    return AuthResult.success;
  }

  Future<AuthResult> maybeAuthenticateBackupRestore({
    required SharedPreferences prefs,
    required String reason,
  }) async {
    final enabled = prefs.getBool(PrefKeys.backupTwoFactorEnabled) ?? false;
    if (!enabled) return AuthResult.success;
    return authenticateDevice(reason: reason);
  }

  Future<AuthResult> ensureAuthorizedForAsset({
    required SharedPreferences prefs,
    required String reason,
  }) async {
    final enabled = prefs.getBool(PrefKeys.biometricAuthEnabled) ?? true;
    if (!enabled) return AuthResult.success;

    final result = await authenticateDevice(reason: reason);
    if (!result.ok) return result;

    await prefs.setInt(
      PrefKeys.assetAuthSessionUntilMs,
      DateTime.now().add(assetSessionTimeout).millisecondsSinceEpoch,
    );

    return AuthResult.success;
  }
}
