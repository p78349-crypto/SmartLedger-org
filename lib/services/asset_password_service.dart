import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/pref_keys.dart';

enum AssetPasswordPolicyStatus { success, failed, locked }

enum AssetPasswordLockType { cooldown, longLock }

class AssetPasswordPolicyResult {
  const AssetPasswordPolicyResult._(
    this.status, {
    this.failedAttempts,
    this.showWarning,
    this.lockType,
    this.lockRemaining,
  });

  final AssetPasswordPolicyStatus status;
  final int? failedAttempts;
  final bool? showWarning;
  final AssetPasswordLockType? lockType;
  final Duration? lockRemaining;

  static AssetPasswordPolicyResult success() =>
      const AssetPasswordPolicyResult._(AssetPasswordPolicyStatus.success);

  static AssetPasswordPolicyResult failed({
    required int failedAttempts,
    required bool showWarning,
  }) => AssetPasswordPolicyResult._(
    AssetPasswordPolicyStatus.failed,
    failedAttempts: failedAttempts,
    showWarning: showWarning,
  );

  static AssetPasswordPolicyResult locked({
    required AssetPasswordLockType lockType,
    required Duration lockRemaining,
    int? failedAttempts,
  }) => AssetPasswordPolicyResult._(
    AssetPasswordPolicyStatus.locked,
    lockType: lockType,
    lockRemaining: lockRemaining,
    failedAttempts: failedAttempts,
  );
}

class AssetPasswordService {
  AssetPasswordService({Random? random}) : _random = random ?? Random.secure();

  // See UserPasswordService.defaultIterations for PBKDF2 rationale.
  static const int defaultIterations = 150000;
  static const int saltLengthBytes = 16;
  static const int derivedKeyBits = 256;

  static const int warnThreshold = 3;
  static const int cooldownThreshold = 5;
  static const Duration cooldownDuration = Duration(minutes: 1);
  static const int longLockThreshold = 10;
  static const Duration longLockDuration = Duration(minutes: 15);

  static Future<void> _policyQueue = Future<void>.value();

  final Random _random;

  bool isPasswordConfigured(SharedPreferences prefs) {
    final saltB64 = prefs.getString(PrefKeys.assetPasswordSaltB64);
    final hashB64 = prefs.getString(PrefKeys.assetPasswordHashB64);
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
    return _runPolicySerialized(() async {
      if (password.trim().isEmpty) {
        throw ArgumentError('비밀번호가 비어 있습니다');
      }

      final salt = _randomBytes(_random, saltLengthBytes);
      final hash = await _derive(password, salt: salt, iterations: iterations);

      await prefs.setString(PrefKeys.assetPasswordSaltB64, base64Encode(salt));
      await prefs.setString(PrefKeys.assetPasswordHashB64, base64Encode(hash));
      await prefs.setInt(PrefKeys.assetPasswordIterations, iterations);
    });
  }

  Future<bool> verifyPassword(
    SharedPreferences prefs, {
    required String password,
  }) async {
    final saltB64 = prefs.getString(PrefKeys.assetPasswordSaltB64);
    final hashB64 = prefs.getString(PrefKeys.assetPasswordHashB64);
    if (saltB64 == null || hashB64 == null) return false;

    final salt = base64Decode(saltB64);
    final expected = base64Decode(hashB64);
    final iterations =
        prefs.getInt(PrefKeys.assetPasswordIterations) ?? defaultIterations;

    final actual = await _derive(password, salt: salt, iterations: iterations);
    return _constantTimeEquals(expected, actual);
  }

  Duration? lockRemaining(SharedPreferences prefs) {
    final untilMs = prefs.getInt(PrefKeys.assetPasswordLockedUntilMs);
    if (untilMs == null) return null;
    final remainingMs = untilMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) return null;
    return Duration(milliseconds: remainingMs);
  }

  Future<void> clearLockIfExpired(SharedPreferences prefs) async {
    final untilMs = prefs.getInt(PrefKeys.assetPasswordLockedUntilMs);
    if (untilMs == null) return;
    if (DateTime.now().millisecondsSinceEpoch >= untilMs) {
      await prefs.remove(PrefKeys.assetPasswordLockedUntilMs);
    }
  }

  Future<AssetPasswordPolicyResult> verifyPasswordWithPolicy(
    SharedPreferences prefs, {
    required String password,
  }) async {
    return _runPolicySerialized(() async {
      final remaining = lockRemaining(prefs);
      if (remaining != null) {
        final type = remaining.inMinutes >= 5
            ? AssetPasswordLockType.longLock
            : AssetPasswordLockType.cooldown;
        final failedAttempts = prefs.getInt(
          PrefKeys.assetPasswordFailedAttempts,
        );
        return AssetPasswordPolicyResult.locked(
          lockType: type,
          lockRemaining: remaining,
          failedAttempts: failedAttempts,
        );
      }

      await clearLockIfExpired(prefs);

      final ok = await verifyPassword(prefs, password: password);
      if (ok) {
        await prefs.remove(PrefKeys.assetPasswordFailedAttempts);
        await prefs.remove(PrefKeys.assetPasswordLockedUntilMs);
        return AssetPasswordPolicyResult.success();
      }

      final current = prefs.getInt(PrefKeys.assetPasswordFailedAttempts) ?? 0;
      final next = current + 1;
      await prefs.setInt(PrefKeys.assetPasswordFailedAttempts, next);

      if (next == cooldownThreshold) {
        await prefs.setInt(
          PrefKeys.assetPasswordLockedUntilMs,
          DateTime.now().add(cooldownDuration).millisecondsSinceEpoch,
        );
        return AssetPasswordPolicyResult.locked(
          lockType: AssetPasswordLockType.cooldown,
          lockRemaining: cooldownDuration,
          failedAttempts: next,
        );
      }

      if (next >= longLockThreshold) {
        await prefs.setInt(
          PrefKeys.assetPasswordLockedUntilMs,
          DateTime.now().add(longLockDuration).millisecondsSinceEpoch,
        );
        await prefs.remove(PrefKeys.assetPasswordFailedAttempts);
        return AssetPasswordPolicyResult.locked(
          lockType: AssetPasswordLockType.longLock,
          lockRemaining: longLockDuration,
          failedAttempts: next,
        );
      }

      return AssetPasswordPolicyResult.failed(
        failedAttempts: next,
        showWarning: next >= warnThreshold,
      );
    });
  }

  Future<T> _runPolicySerialized<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _policyQueue = _policyQueue.then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Future<void> clearPassword(SharedPreferences prefs) async {
    return _runPolicySerialized(() async {
      await prefs.remove(PrefKeys.assetPasswordSaltB64);
      await prefs.remove(PrefKeys.assetPasswordHashB64);
      await prefs.remove(PrefKeys.assetPasswordIterations);
      await prefs.remove(PrefKeys.assetPasswordFailedAttempts);
      await prefs.remove(PrefKeys.assetPasswordLockedUntilMs);
    });
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
