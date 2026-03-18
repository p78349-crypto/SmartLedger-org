import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import '../../utils/backup_crypto.dart';

/// [실험적 기능]
/// 복구 코드를 사용하여 데이터를 암호화/복호화하는 확장 클래스입니다.
/// 메인 BackupCrypto와 별도로 관리되어 출시 후 선택적으로 결합할 수 있습니다.
class RecoveryCodeCrypto {
  static final Cipher _cipher = AesGcm.with256bits();

  /// 복구 코드로 데이터를 암호화합니다.
  /// 결과물은 기존 SLBK 포맷에 'recovery_ct' 필드로 추가될 수 있도록 설계되었습니다.
  static Future<Map<String, dynamic>> encryptWithRecoveryCode({
    required String plainJson,
    required String recoveryCode,
  }) async {
    // 복구 코드를 정규화 (공백/하이픈 제거)
    final normalized = recoveryCode
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .toUpperCase();

    // BackupCrypto의 내부 로직을 활용하거나 독자적인 Salt 생성
    final salt = BackupCrypto.randomBytes(16);
    final nonce = BackupCrypto.randomBytes(12);

    // 복구 코드를 기반으로 키 유도
    // (주의: 복구 코드는 이미 엔트로피가 어느 정도 확보되어 있으므로 Iteration을 조절 가능)
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );

    final secretKey = await pbkdf2.deriveKeyFromPassword(
      password: normalized,
      nonce: salt,
    );

    final secretBox = await _cipher.encrypt(
      utf8.encode(plainJson),
      secretKey: secretKey,
      nonce: nonce,
    );

    return {
      'r_salt': base64Encode(salt),
      'r_nonce': base64Encode(secretBox.nonce),
      'r_ct': base64Encode(secretBox.cipherText),
      'r_mac': base64Encode(secretBox.mac.bytes),
    };
  }

  /// 복구 코드를 사용하여 SLBK 엔벨로프에서 데이터를 복호화합니다.
  static Future<String> decryptWithRecoveryCode({
    required Map<String, dynamic> envelope,
    required String recoveryCode,
  }) async {
    final normalized = recoveryCode
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .toUpperCase();

    final salt = base64Decode(envelope['r_salt']);
    final nonce = base64Decode(envelope['r_nonce']);
    final cipherText = base64Decode(envelope['r_ct']);
    final macBytes = base64Decode(envelope['r_mac']);

    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );

    final secretKey = await pbkdf2.deriveKeyFromPassword(
      password: normalized,
      nonce: salt,
    );

    final clear = await _cipher.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(macBytes)),
      secretKey: secretKey,
    );

    return utf8.decode(clear);
  }
}
