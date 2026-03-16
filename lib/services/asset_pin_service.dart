import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/pref_keys.dart';

enum AssetPinPolicyStatus { success, failed, locked }

enum AssetPinLockType { cooldown, longLock }

class AssetPinPolicyResult {
  const AssetPinPolicyResult._(
    this.status, {
    this.failedAttempts,
    this.showWarning,
    this.lockType,
    this.lockRemaining,
  });

  final AssetPinPolicyStatus status;
  final int? failedAttempts;
  final bool? showWarning;
  final AssetPinLockType? lockType;
  final Duration? lockRemaining;

  static AssetPinPolicyResult success() =>
      const AssetPinPolicyResult._(AssetPinPolicyStatus.success);

  static AssetPinPolicyResult failed({
    required int failedAttempts,
    required bool showWarning,
  }) => AssetPinPolicyResult._(
    AssetPinPolicyStatus.failed,
    failedAttempts: failedAttempts,
    showWarning: showWarning,
  );

  static AssetPinPolicyResult locked({
    required AssetPinLockType lockType,
    required Duration lockRemaining,
    int? failedAttempts,
  }) => AssetPinPolicyResult._(
    AssetPinPolicyStatus.locked,
    lockType: lockType,
    lockRemaining: lockRemaining,
    failedAttempts: failedAttempts,
  );
}

class AssetPinService {
  AssetPinService({Random? random}) : _random = random ?? Random.secure();

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

  bool isPinConfigured(SharedPreferences prefs) {
    final saltB64 = prefs.getString(PrefKeys.assetPinSaltB64);
    final hashB64 = prefs.getString(PrefKeys.assetPinHashB64);
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
    return _runPolicySerialized(() async {
      if (pin.trim().isEmpty) {
        throw ArgumentError('PIN이 비어 있습니다');
      }

      final salt = _randomBytes(_random, saltLengthBytes);
      final hash = await _derive(pin, salt: salt, iterations: iterations);

      await prefs.setString(PrefKeys.assetPinSaltB64, base64Encode(salt));
      await prefs.setString(PrefKeys.assetPinHashB64, base64Encode(hash));
      await prefs.setInt(PrefKeys.assetPinIterations, iterations);
    });
  }

  Future<bool> verifyPin(SharedPreferences prefs, {required String pin}) async {
    final saltB64 = prefs.getString(PrefKeys.assetPinSaltB64);
    final hashB64 = prefs.getString(PrefKeys.assetPinHashB64);
    if (saltB64 == null || hashB64 == null) return false;

    final salt = base64Decode(saltB64);
    final expected = base64Decode(hashB64);
    final iterations =
        prefs.getInt(PrefKeys.assetPinIterations) ?? defaultIterations;

    final actual = await _derive(pin, salt: salt, iterations: iterations);
    return _constantTimeEquals(expected, actual);
  }

  Duration? lockRemaining(SharedPreferences prefs) {
    final untilMs = prefs.getInt(PrefKeys.assetPinLockedUntilMs);
    if (untilMs == null) return null;
    final remainingMs = untilMs - DateTime.now().millisecondsSinceEpoch;
    if (remainingMs <= 0) return null;
    return Duration(milliseconds: remainingMs);
  }

  Future<void> clearLockIfExpired(SharedPreferences prefs) async {
    final untilMs = prefs.getInt(PrefKeys.assetPinLockedUntilMs);
    if (untilMs == null) return;
    if (DateTime.now().millisecondsSinceEpoch >= untilMs) {
      await prefs.remove(PrefKeys.assetPinLockedUntilMs);
    }
  }

  Future<AssetPinPolicyResult> verifyPinWithPolicy(
    SharedPreferences prefs, {
    required String pin,
  }) async {
    return _runPolicySerialized(() async {
      final remaining = lockRemaining(prefs);
      if (remaining != null) {
        final type = remaining.inMinutes >= 5
            ? AssetPinLockType.longLock
            : AssetPinLockType.cooldown;
        final failedAttempts = prefs.getInt(PrefKeys.assetPinFailedAttempts);
        return AssetPinPolicyResult.locked(
          lockType: type,
          lockRemaining: remaining,
          failedAttempts: failedAttempts,
        );
      }

      await clearLockIfExpired(prefs);

      final ok = await verifyPin(prefs, pin: pin);
      if (ok) {
        await prefs.remove(PrefKeys.assetPinFailedAttempts);
        await prefs.remove(PrefKeys.assetPinLockedUntilMs);
        return AssetPinPolicyResult.success();
      }

      final current = prefs.getInt(PrefKeys.assetPinFailedAttempts) ?? 0;
      final next = current + 1;
      await prefs.setInt(PrefKeys.assetPinFailedAttempts, next);

      if (next == cooldownThreshold) {
        await prefs.setInt(
          PrefKeys.assetPinLockedUntilMs,
          DateTime.now().add(cooldownDuration).millisecondsSinceEpoch,
        );
        return AssetPinPolicyResult.locked(
          lockType: AssetPinLockType.cooldown,
          lockRemaining: cooldownDuration,
          failedAttempts: next,
        );
      }

      if (next >= longLockThreshold) {
        await prefs.setInt(
          PrefKeys.assetPinLockedUntilMs,
          DateTime.now().add(longLockDuration).millisecondsSinceEpoch,
        );
        await prefs.remove(PrefKeys.assetPinFailedAttempts);
        return AssetPinPolicyResult.locked(
          lockType: AssetPinLockType.longLock,
          lockRemaining: longLockDuration,
          failedAttempts: next,
        );
      }

      return AssetPinPolicyResult.failed(
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

  Future<void> clearPin(SharedPreferences prefs) async {
    return _runPolicySerialized(() async {
      await prefs.remove(PrefKeys.assetPinSaltB64);
      await prefs.remove(PrefKeys.assetPinHashB64);
      await prefs.remove(PrefKeys.assetPinIterations);
      await prefs.remove(PrefKeys.assetPinFailedAttempts);
      await prefs.remove(PrefKeys.assetPinLockedUntilMs);
    });
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
