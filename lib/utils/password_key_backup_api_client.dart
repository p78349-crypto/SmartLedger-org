import 'dart:convert';

import 'package:http/http.dart' as http;

import '../services/server_config_service.dart';

class PasswordKeyBackupApiResponse {
  const PasswordKeyBackupApiResponse({
    required this.statusCode,
    this.jsonBody,
    this.rawBody,
    this.offline = false,
  });

  final int statusCode;
  final Map<String, dynamic>? jsonBody;
  final String? rawBody;
  final bool offline;

  bool get isOk => statusCode >= 200 && statusCode < 300;
}

class PasswordKeyBackupApiClient {
  PasswordKeyBackupApiClient({
    required this.ledgerBaseUrl,
    required this.adminKey,
    http.Client? client,
  }) : _explicitClient = client;

  final String ledgerBaseUrl;
  final String adminKey;
  final http.Client? _explicitClient;

  Future<PasswordKeyBackupApiResponse> bootstrap(Map<String, dynamic> payload) {
    return _post('/key-backup/bootstrap', payload);
  }

  Future<PasswordKeyBackupApiResponse> recover(Map<String, dynamic> payload) {
    return _post('/key-backup/recover', payload);
  }

  Future<PasswordKeyBackupApiResponse> rotate(Map<String, dynamic> payload) {
    return _post('/key-backup/rotate', payload);
  }

  Future<PasswordKeyBackupApiResponse> _post(
    String path,
    Map<String, dynamic> payload,
  ) async {
    final base = ledgerBaseUrl.trim().replaceAll(RegExp(r'/$'), '');
    final uri = Uri.parse('$base$path');

    final client =
        _explicitClient ?? await ServerConfigService().createHttpClient();
    try {
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (adminKey.trim().isNotEmpty) 'X-Admin-Key': adminKey.trim(),
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 6));

      final parsed = _tryDecodeMap(response.body);
      return PasswordKeyBackupApiResponse(
        statusCode: response.statusCode,
        jsonBody: parsed,
        rawBody: response.body,
      );
    } catch (_) {
      return const PasswordKeyBackupApiResponse(statusCode: -1, offline: true);
    } finally {
      if (_explicitClient == null) client.close();
    }
  }

  Map<String, dynamic>? _tryDecodeMap(String body) {
    if (body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }
}
