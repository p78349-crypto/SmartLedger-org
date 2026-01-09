import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/pref_keys.dart';

enum UserPinPolicyStatus { success, failed, locked }

enum UserPinLockType { cooldown, longLock }

class UserPinPolicyResult {
  const UserPinPolicyResult._(
    this.status, {
    this.failedAttempts,
    this.showWarning,
    this.lockType,
    this.lockRemaining,
  });

  final UserPinPolicyStatus status;

  /// Cumulative failed attempts since last success (resets on success).
  final int? failedAttempts;

  /// True when the user has reached the warning threshold.
  final bool? showWarning;

  /// When [status] is locked.
  final UserPinLockType? lockType;

  /// When [status] is locked.
  final Duration? lockRemaining;

  static UserPinPolicyResult success() =>
      const UserPinPolicyResult._(UserPinPolicyStatus.success);

  static UserPinPolicyResult failed({
    required int failedAttempts,
    required bool showWarning,
  }) => UserPinPolicyResult._(
    UserPinPolicyStatus.failed,
    failedAttempts: failedAttempts,
    showWarning: showWarning,
  );

  static UserPinPolicyResult locked({
    required UserPinLockType lockType,
    required Duration lockRemaining,
    int? failedAttempts,
  }) => UserPinPolicyResult._(
    UserPinPolicyStatus.locked,
    lockType: lockType,
    lockRemaining: lockRemaining,
    failedAttempts: failedAttempts,
  );
}

class UserPinService {
  UserPinService({Random? random}) : _random = random ?? Random.secure();

  static const int defaultIterations = 150000;
  static const int saltLengthBytes = 16;
  static const int derivedKeyBits = 256;

  static const int warnThreshold = 3;
  static const int cooldownThreshold = 5;
  static const Duration cooldownDuration = Duration(minutes: 1);
  static const int longLockThreshold = 10;
  static const Duration longLockDuration = Duration(minutes: 15);

  final Random _random;

  bool isPinConfigured(SharedPreferences prefs) {
    final saltB64 = prefs.getString(PrefKeys.userPinSaltB64);
    final hashB64 = prefs.getString(PrefKeys.userPinHashB64);
    return saltB64 != null &&
        saltB64.isNotEmpty &&
        hashB64 != null &&
        hashB64.isNotEmpty;
  }

  Future<void> setPin(
    SharedPreferences prefs, {
    required String pin,
    int iterations = defaultIterations,
  }) async {
    if (pin.trim().isEmpty) {
      throw ArgumentError('PIN이 비어 있습니다');
    }

    final salt = _randomBytes(_random, saltLengthBytes);
    final hash = await _derive(pin, salt: salt, iterations: iterations);

    await prefs.setString(PrefKeys.userPinSaltB64, base64Encode(salt));
    await prefs.setString(PrefKeys.userPinHashB64, base64Encode(hash));
    await prefs.setInt(PrefKeys.userPinIterations, iterations);
  }

  Future<bool> verifyPin(SharedPreferences prefs, {required String pin}) async {
    final saltB64 = prefs.getString(PrefKeys.userPinSaltB64);
    final hashB64 = prefs.getString(PrefKeys.userPinHashB64);
    if (saltB64 == null || hashB64 == null) return false;

    final salt = base64Decode(saltB64);
    final expected = base64Decode(hashB64);
    final iterations =
        prefs.getInt(PrefKeys.userPinIterations) ?? defaultIterations;

    final actual = await _derive(pin, salt: salt, iterations: iterations);
    return _constantTimeEquals(expected, actual);
  }

  Duration? lockRemaining(SharedPreferences prefs) {
    final untilMs = prefs.getInt(PrefKeys.userPinLockedUntilMs);
    if (untilMs == null) return null;
    final remainingMs = untilMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) return null;
    return Duration(milliseconds: remainingMs);
  }

  Future<void> clearLockIfExpired(SharedPreferences prefs) async {
    final untilMs = prefs.getInt(PrefKeys.userPinLockedUntilMs);
    if (untilMs == null) return;
    if (DateTime.now().millisecondsSinceEpoch >= untilMs) {
      await prefs.remove(PrefKeys.userPinLockedUntilMs);
    }
  }

  Future<UserPinPolicyResult> verifyPinWithPolicy(
    SharedPreferences prefs, {
    required String pin,
  }) async {
    final remaining = lockRemaining(prefs);
    if (remaining != null) {
      final type = remaining.inMinutes >= 5
          ? UserPinLockType.longLock
          : UserPinLockType.cooldown;
      final failedAttempts = prefs.getInt(PrefKeys.userPinFailedAttempts);
      return UserPinPolicyResult.locked(
        lockType: type,
        lockRemaining: remaining,
        failedAttempts: failedAttempts,
      );
    }

    await clearLockIfExpired(prefs);

    final ok = await verifyPin(prefs, pin: pin);
    if (ok) {
      await prefs.remove(PrefKeys.userPinFailedAttempts);
      await prefs.remove(PrefKeys.userPinLockedUntilMs);
      return UserPinPolicyResult.success();
    }

    final current = prefs.getInt(PrefKeys.userPinFailedAttempts) ?? 0;
    final next = current + 1;
    await prefs.setInt(PrefKeys.userPinFailedAttempts, next);

    if (next == cooldownThreshold) {
      await prefs.setInt(
        PrefKeys.userPinLockedUntilMs,
        DateTime.now().add(cooldownDuration).millisecondsSinceEpoch,
      );
      return UserPinPolicyResult.locked(
        lockType: UserPinLockType.cooldown,
        lockRemaining: cooldownDuration,
        failedAttempts: next,
      );
    }

    if (next >= longLockThreshold) {
      await prefs.setInt(
        PrefKeys.userPinLockedUntilMs,
        DateTime.now().add(longLockDuration).millisecondsSinceEpoch,
      );

      // After a long lock, give a fresh attempt window.
      await prefs.remove(PrefKeys.userPinFailedAttempts);
      return UserPinPolicyResult.locked(
        lockType: UserPinLockType.longLock,
        lockRemaining: longLockDuration,
        failedAttempts: next,
      );
    }

    return UserPinPolicyResult.failed(
      failedAttempts: next,
      showWarning: next >= warnThreshold,
    );
  }

  Future<void> clearPin(SharedPreferences prefs) async {
    await prefs.remove(PrefKeys.userPinSaltB64);
    await prefs.remove(PrefKeys.userPinHashB64);
    await prefs.remove(PrefKeys.userPinIterations);
    await prefs.remove(PrefKeys.userPinFailedAttempts);
    await prefs.remove(PrefKeys.userPinLockedUntilMs);
  }

  Future<Uint8List> _derive(
    String pin, {
    required List<int> salt,
    required int iterations,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: derivedKeyBits,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
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
