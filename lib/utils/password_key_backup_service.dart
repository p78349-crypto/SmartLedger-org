import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class PasswordKeyBackupBootstrapData {
  const PasswordKeyBackupBootstrapData({
    required this.recoveryKeyBase64,
    required this.passwordHashB64,
    required this.passwordHashSaltB64,
    required this.wrappedDekByPassword,
    required this.wrappedDekByRecoveryKey,
  });

  final String recoveryKeyBase64;
  final String passwordHashB64;
  final String passwordHashSaltB64;
  final Map<String, dynamic> wrappedDekByPassword;
  final Map<String, dynamic> wrappedDekByRecoveryKey;

  Map<String, dynamic> toPayload({required String accountId}) {
    return {
      'accountId': accountId,
      'passwordHash': passwordHashB64,
      'passwordHashSalt': passwordHashSaltB64,
      'dekWrapByPassword': wrappedDekByPassword,
      'dekWrapByRecoveryKey': wrappedDekByRecoveryKey,
    };
  }
}

class PasswordKeyBackupService {
  PasswordKeyBackupService._internal();
  static final PasswordKeyBackupService _instance =
      PasswordKeyBackupService._internal();
  factory PasswordKeyBackupService() => _instance;

  static const int _passwordHashIterations = 150000;
  static const int _wrapIterations = 120000;
  static const int _saltLength = 16;
  static const int _dekLength = 32;
  static const int _nonceLength = 12;

  final Cipher _cipher = AesGcm.with256bits();
  final Random _random = Random.secure();

  Future<PasswordKeyBackupBootstrapData> createBootstrapData({
    required String accountId,
    required String password,
  }) async {
    final normalizedPassword = password.trim();
    if (accountId.trim().isEmpty) {
      throw ArgumentError('accountId is empty');
    }
    if (normalizedPassword.isEmpty) {
      throw ArgumentError('password is empty');
    }

    final dek = _randomBytes(_dekLength);
    final recoveryKeyRaw = _randomBytes(_dekLength);

    final hashSalt = _randomBytes(_saltLength);
    final passwordHash = await _deriveKeyBytes(
      secret: normalizedPassword,
      salt: hashSalt,
      iterations: _passwordHashIterations,
    );

    final wrappedByPassword = await _wrapDek(
      dek: dek,
      secret: normalizedPassword,
    );
    final wrappedByRecoveryKey = await _wrapDek(
      dek: dek,
      secretB64: base64Encode(recoveryKeyRaw),
    );

    return PasswordKeyBackupBootstrapData(
      recoveryKeyBase64: base64Encode(recoveryKeyRaw),
      passwordHashB64: base64Encode(passwordHash),
      passwordHashSaltB64: base64Encode(hashSalt),
      wrappedDekByPassword: wrappedByPassword,
      wrappedDekByRecoveryKey: wrappedByRecoveryKey,
    );
  }

  Future<Map<String, dynamic>> buildRecoverPayloadWithPassword({
    required String accountId,
    required String password,
  }) async {
    final normalizedPassword = password.trim();
    if (accountId.trim().isEmpty) {
      throw ArgumentError('accountId is empty');
    }
    if (normalizedPassword.isEmpty) {
      throw ArgumentError('password is empty');
    }

    return {
      'accountId': accountId,
      'password': normalizedPassword,
    };
  }

  Future<Map<String, dynamic>> buildRecoverPayloadWithRecoveryKey({
    required String accountId,
    required String recoveryKeyBase64,
  }) async {
    if (accountId.trim().isEmpty) {
      throw ArgumentError('accountId is empty');
    }
    if (recoveryKeyBase64.trim().isEmpty) {
      throw ArgumentError('recovery key is empty');
    }

    return {
      'accountId': accountId,
      'recoveryKey': recoveryKeyBase64.trim(),
    };
  }

  Future<Map<String, dynamic>> buildRotatePayload({
    required String accountId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final normalizedCurrent = currentPassword.trim();
    final normalizedNew = newPassword.trim();
    if (accountId.trim().isEmpty) {
      throw ArgumentError('accountId is empty');
    }
    if (normalizedCurrent.isEmpty || normalizedNew.isEmpty) {
      throw ArgumentError('password is empty');
    }

    final hashSalt = _randomBytes(_saltLength);
    final newPasswordHash = await _deriveKeyBytes(
      secret: normalizedNew,
      salt: hashSalt,
      iterations: _passwordHashIterations,
    );

    return {
      'accountId': accountId,
      'currentPassword': normalizedCurrent,
      'newPassword': normalizedNew,
      'newPasswordHash': base64Encode(newPasswordHash),
      'newPasswordHashSalt': base64Encode(hashSalt),
    };
  }

  Future<Map<String, dynamic>> _wrapDek({
    required Uint8List dek,
    String? secret,
    String? secretB64,
  }) async {
    final source = secret ?? secretB64;
    if (source == null || source.isEmpty) {
      throw ArgumentError('wrap secret is empty');
    }

    final salt = _randomBytes(_saltLength);
    final nonce = _randomBytes(_nonceLength);

    final keyBytes = await _deriveKeyBytes(
      secret: source,
      salt: salt,
      iterations: _wrapIterations,
    );

    final box = await _cipher.encrypt(
      dek,
      secretKey: SecretKey(keyBytes),
      nonce: nonce,
    );

    return {
      'kdf': 'pbkdf2-sha256',
      'iter': _wrapIterations,
      'salt': base64Encode(salt),
      'cipher': 'aes-256-gcm',
      'nonce': base64Encode(box.nonce),
      'ct': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Future<Uint8List> _deriveKeyBytes({
    required String secret,
    required Uint8List salt,
    required int iterations,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );

    final key = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(secret)),
      nonce: salt,
    );

    return Uint8List.fromList(await key.extractBytes());
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(length, (_) => _random.nextInt(256)),
    );
  }
}
