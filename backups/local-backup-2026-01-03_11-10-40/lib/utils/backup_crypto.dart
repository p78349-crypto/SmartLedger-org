import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class BackupCrypto {
  BackupCrypto._();

  static const String envelopeFormat = 'SLBK';
  static const int envelopeVersion = 1;

  static const int _saltLength = 16;
  static const int _nonceLength = 12;
  static const int _keyLengthBytes = 32;
  static const int _pbkdf2Iterations = 150000;

  static final Cipher _cipher = AesGcm.with256bits();

  static bool isEncryptedEnvelopeText(String text) {
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) return false;
      return decoded['format'] == envelopeFormat;
    } catch (_) {
      return false;
    }
  }

  static Future<String> encryptJsonPayload({
    required String plainJson,
    required String password,
  }) async {
    if (password.trim().isEmpty) {
      throw Exception('백업 암호가 비어있습니다');
    }

    final random = Random.secure();
    final salt = _randomBytes(random, _saltLength);
    final nonce = _randomBytes(random, _nonceLength);

    final secretKey = await _deriveKey(password: password, salt: salt);
    final secretBox = await _cipher.encrypt(
      utf8.encode(plainJson),
      secretKey: secretKey,
      nonce: nonce,
    );

    final envelope = <String, dynamic>{
      'format': envelopeFormat,
      'v': envelopeVersion,
      'kdf': 'pbkdf2-sha256',
      'iter': _pbkdf2Iterations,
      'salt': base64Encode(salt),
      'cipher': 'aes-256-gcm',
      'nonce': base64Encode(secretBox.nonce),
      'ct': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
      'createdAt': DateTime.now().toIso8601String(),
    };

    return jsonEncode(envelope);
  }

  static Future<String> decryptJsonEnvelope({
    required String encryptedEnvelopeJson,
    required String password,
  }) async {
    if (password.trim().isEmpty) {
      throw Exception('백업 암호가 비어있습니다');
    }

    final decoded = jsonDecode(encryptedEnvelopeJson);
    if (decoded is! Map) {
      throw Exception('암호화 백업 형식이 올바르지 않습니다');
    }

    if (decoded['format'] != envelopeFormat) {
      throw Exception('암호화 백업이 아닙니다');
    }

    final saltB64 = decoded['salt'];
    final nonceB64 = decoded['nonce'];
    final ctB64 = decoded['ct'];
    final macB64 = decoded['mac'];

    if (saltB64 is! String ||
        nonceB64 is! String ||
        ctB64 is! String ||
        macB64 is! String) {
      throw Exception('암호화 백업 데이터가 손상되었습니다');
    }

    final salt = base64Decode(saltB64);
    final nonce = base64Decode(nonceB64);
    final cipherText = base64Decode(ctB64);
    final macBytes = base64Decode(macB64);

    final secretKey = await _deriveKey(password: password, salt: salt);

    try {
      final clear = await _cipher.decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
        secretKey: secretKey,
      );
      return utf8.decode(clear);
    } on SecretBoxAuthenticationError {
      throw Exception('암호가 올바르지 않거나 백업 파일이 손상되었습니다');
    }
  }

  static Future<SecretKey> _deriveKey({
    required String password,
    required List<int> salt,
  }) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: _pbkdf2Iterations,
      bits: _keyLengthBytes * 8,
    );

    return pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  static List<int> _randomBytes(Random random, int length) {
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
}
