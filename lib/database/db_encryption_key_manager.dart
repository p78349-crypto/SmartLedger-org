import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DbEncryptionKeyManager {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
      synchronizable: true, // iCloud Keychain 동기화 활성화
    ),
  );
  static const _keyName = 'db_encryption_key';

  /// 데이터베이스 암호화 키를 가져오거나, 없으면 새로 생성하여 저장합니다.
  static Future<String> getOrCreateKey() async {
    String? key = await _storage.read(key: _keyName);
    if (key == null) {
      // 32바이트(256비트) 랜덤 키 생성
      final random = Random.secure();
      final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
      key = base64Url.encode(keyBytes);
      await _storage.write(key: _keyName, value: key);
    }
    return key;
  }

  /// 기기 분실/초기화 시 복구를 위해 현재 암호화 키를 반환합니다.
  /// (주의: 이 키는 사용자에게만 노출되어야 하며, 종이 백업 등 오프라인 보관을 권장합니다.)
  static Future<String?> exportKeyForBackup() async {
    return await _storage.read(key: _keyName);
  }

  /// 사용자가 백업해둔 키를 입력하여 복구합니다.
  /// 기존 키가 덮어씌워지므로 주의가 필요합니다.
  static Future<bool> restoreKeyFromBackup(String backupKey) async {
    try {
      // 키 유효성 검증 (Base64Url 디코딩 가능 여부 및 길이 확인)
      final decoded = base64Url.decode(backupKey);
      if (decoded.length != 32) {
        return false; // 256비트(32바이트) 키가 아님
      }
      await _storage.write(key: _keyName, value: backupKey);
      return true;
    } catch (e) {
      return false; // 잘못된 형식의 키
    }
  }
}
