import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

enum UserPasswordPolicyStatus { success, failed, locked }

enum UserPasswordLockType { cooldown, longLock }

class UserPasswordPolicyResult {
  const UserPasswordPolicyResult._(
    this.status, {
    this.failedAttempts,
    this.showWarning,
    this.lockType,
    this.lockRemaining,
  });

  final UserPasswordPolicyStatus status;
  final int? failedAttempts;
  final bool? showWarning;
  final UserPasswordLockType? lockType;
  final Duration? lockRemaining;

  static UserPasswordPolicyResult success() =>
      const UserPasswordPolicyResult._(UserPasswordPolicyStatus.success);

  static UserPasswordPolicyResult failed({
    required int failedAttempts,
    required bool showWarning,
  }) => UserPasswordPolicyResult._(
    UserPasswordPolicyStatus.failed,
    failedAttempts: failedAttempts,
    showWarning: showWarning,
  );

  static UserPasswordPolicyResult locked({
    required UserPasswordLockType lockType,
    required Duration lockRemaining,
    int? failedAttempts,
  }) => UserPasswordPolicyResult._(
    UserPasswordPolicyStatus.locked,
    lockType: lockType,
    lockRemaining: lockRemaining,
    failedAttempts: failedAttempts,
  );
}

class UserPasswordService {
  UserPasswordService({Random? random}) : _random = random ?? Random.secure();

  static const int defaultIterations = 150000;
  static const int saltLengthBytes = 16;
  static const int derivedKeyBits = 256;

  static const int warnThreshold = 3;
  static const int cooldownThreshold = 5;
  static const Duration cooldownDuration = Duration(minutes: 1);
  static const int longLockThreshold = 10;
  static const Duration longLockDuration = Duration(minutes: 15);

  final Random _random;

  bool isPasswordConfigured(SharedPreferences prefs) {
    final saltB64 = prefs.getString(PrefKeys.userPasswordSaltB64);
    final hashB64 = prefs.getString(PrefKeys.userPasswordHashB64);
    return saltB64 != null &&
        saltB64.isNotEmpty &&
        hashB64 != null &&
        hashB64.isNotEmpty;
  }

  Future<void> setPassword(
    SharedPreferences prefs, {
    required String password,
    int iterations = defaultIterations,
  }) async {
    if (password.trim().isEmpty) {
      throw ArgumentError('비밀번호가 비어 있습니다');
    }

    final salt = _randomBytes(_random, saltLengthBytes);
    final hash = await _derive(password, salt: salt, iterations: iterations);

    await prefs.setString(PrefKeys.userPasswordSaltB64, base64Encode(salt));
    await prefs.setString(PrefKeys.userPasswordHashB64, base64Encode(hash));
    await prefs.setInt(PrefKeys.userPasswordIterations, iterations);
  }

  Future<bool> verifyPassword(
    SharedPreferences prefs, {
    required String password,
  }) async {
    final saltB64 = prefs.getString(PrefKeys.userPasswordSaltB64);
    final hashB64 = prefs.getString(PrefKeys.userPasswordHashB64);
    if (saltB64 == null || hashB64 == null) return false;

    final salt = base64Decode(saltB64);
    final expected = base64Decode(hashB64);
    final iterations =
        prefs.getInt(PrefKeys.userPasswordIterations) ?? defaultIterations;

    final actual = await _derive(password, salt: salt, iterations: iterations);
    return _constantTimeEquals(expected, actual);
  }

  Duration? lockRemaining(SharedPreferences prefs) {
    final untilMs = prefs.getInt(PrefKeys.userPasswordLockedUntilMs);
    if (untilMs == null) return null;
    final remainingMs = untilMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) return null;
    return Duration(milliseconds: remainingMs);
  }

  Future<void> clearLockIfExpired(SharedPreferences prefs) async {
    final untilMs = prefs.getInt(PrefKeys.userPasswordLockedUntilMs);
    if (untilMs == null) return;
    if (DateTime.now().millisecondsSinceEpoch >= untilMs) {
      await prefs.remove(PrefKeys.userPasswordLockedUntilMs);
    }
  }

  Future<UserPasswordPolicyResult> verifyPasswordWithPolicy(
    SharedPreferences prefs, {
    required String password,
  }) async {
    final remaining = lockRemaining(prefs);
    if (remaining != null) {
      final type = remaining.inMinutes >= 5
          ? UserPasswordLockType.longLock
          : UserPasswordLockType.cooldown;
      final failedAttempts = prefs.getInt(PrefKeys.userPasswordFailedAttempts);
      return UserPasswordPolicyResult.locked(
        lockType: type,
        lockRemaining: remaining,
        failedAttempts: failedAttempts,
      );
    }

    await clearLockIfExpired(prefs);

    final ok = await verifyPassword(prefs, password: password);
    if (ok) {
      await prefs.remove(PrefKeys.userPasswordFailedAttempts);
      await prefs.remove(PrefKeys.userPasswordLockedUntilMs);
      return UserPasswordPolicyResult.success();
    }

    final current = prefs.getInt(PrefKeys.userPasswordFailedAttempts) ?? 0;
    final next = current + 1;
    await prefs.setInt(PrefKeys.userPasswordFailedAttempts, next);

    if (next == cooldownThreshold) {
      await prefs.setInt(
        PrefKeys.userPasswordLockedUntilMs,
        DateTime.now().add(cooldownDuration).millisecondsSinceEpoch,
      );
      return UserPasswordPolicyResult.locked(
        lockType: UserPasswordLockType.cooldown,
        lockRemaining: cooldownDuration,
        failedAttempts: next,
      );
    }

    if (next >= longLockThreshold) {
      await prefs.setInt(
        PrefKeys.userPasswordLockedUntilMs,
        DateTime.now().add(longLockDuration).millisecondsSinceEpoch,
      );
      await prefs.remove(PrefKeys.userPasswordFailedAttempts);
      return UserPasswordPolicyResult.locked(
        lockType: UserPasswordLockType.longLock,
        lockRemaining: longLockDuration,
        failedAttempts: next,
      );
    }

    return UserPasswordPolicyResult.failed(
      failedAttempts: next,
      showWarning: next >= warnThreshold,
    );
  }

  Future<void> clearPassword(SharedPreferences prefs) async {
    await prefs.remove(PrefKeys.userPasswordSaltB64);
    await prefs.remove(PrefKeys.userPasswordHashB64);
    await prefs.remove(PrefKeys.userPasswordIterations);
    await prefs.remove(PrefKeys.userPasswordFailedAttempts);
    await prefs.remove(PrefKeys.userPasswordLockedUntilMs);
  }

  Future<Uint8List> _derive(
    String password, {
    required List<int> salt,
    required int iterations,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: derivedKeyBits,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final bytes = await secretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  List<int> _randomBytes(Random random, int length) {
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}

