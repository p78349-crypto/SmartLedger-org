import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/pref_keys.dart';

/// 서버 설정 관리 서비스
///
/// - 서버 주소는 SharedPreferences (평문, 비민감)
/// - Admin Key는 FlutterSecureStorage (암호화)
/// - Self-signed cert 허용 옵션 제공
/// - 'cloud' / 'self_hosted' 서버 유형 관리
class ServerConfigService {
  ServerConfigService._internal();
  static final ServerConfigService _instance = ServerConfigService._internal();
  factory ServerConfigService() => _instance;

  static const _secureStorage = FlutterSecureStorage();
  static const _secureAdminKeyKey = 'server_admin_key_secure_v1';

  // ── 서버 주소 (비민감, SharedPreferences) ──

  Future<String?> getServerAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefKeys.serverAddress);
  }

  // ── Admin Key (민감, SecureStorage) ──

  Future<String?> getAdminKey() async {
    // SecureStorage 우선, 없으면 레거시 SharedPreferences에서 마이그레이션
    final secureKey = await _secureStorage.read(key: _secureAdminKeyKey);
    if (secureKey != null && secureKey.isNotEmpty) return secureKey;

    // 레거시 마이그레이션: SharedPreferences → SecureStorage
    final prefs = await SharedPreferences.getInstance();
    final legacyKey = prefs.getString(PrefKeys.adminKey);
    if (legacyKey != null && legacyKey.isNotEmpty) {
      await _secureStorage.write(key: _secureAdminKeyKey, value: legacyKey);
      await prefs.remove(PrefKeys.adminKey);
      return legacyKey;
    }
    return null;
  }

  // ── 설정 저장 ──

  Future<void> saveServerConfig(String address, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.serverAddress, address);
    // Admin Key는 SecureStorage에 저장
    await _secureStorage.write(key: _secureAdminKeyKey, value: key);
    // 레거시 키가 있으면 제거
    await prefs.remove(PrefKeys.adminKey);
  }

  // ── Self-signed cert 허용 여부 ──

  Future<bool> getAllowSelfSignedCert() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefKeys.allowSelfSignedCert) ?? false;
  }

  Future<void> setAllowSelfSignedCert(bool allow) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.allowSelfSignedCert, allow);
  }

  // ── 서버 유형 (cloud / self_hosted) ──

  Future<String> getServerType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefKeys.serverType) ?? 'cloud';
  }

  Future<void> setServerType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.serverType, type);
  }

  // ── Self-signed cert를 허용하는 HTTP Client 생성 ──

  Future<http.Client> createHttpClient() async {
    final allowSelfSigned = await getAllowSelfSignedCert();
    if (allowSelfSigned) {
      final ioClient = HttpClient()
        ..badCertificateCallback = (cert, host, port) => true;
      return IOClient(ioClient);
    }
    return http.Client();
  }

  // ── 서버 Health Check ──

  Future<bool> checkHealth() async {
    final address = await getServerAddress();
    final key = await getAdminKey();

    if (address == null || address.isEmpty || key == null || key.isEmpty) {
      return false;
    }

    final client = await createHttpClient();
    try {
      final response = await client
          .get(
            Uri.parse('$address/api/ledger/health'),
            headers: {'X-Admin-Key': key},
          )
          .timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    } finally {
      client.close();
    }
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final key = await getAdminKey();
    return {
      'Content-Type': 'application/json',
      if (key != null && key.isNotEmpty) 'X-Admin-Key': key,
    };
  }
}
