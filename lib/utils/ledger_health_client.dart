import 'dart:convert';

import 'package:http/http.dart' as http;

import '../services/server_config_service.dart';

class LedgerHealthClient {
  LedgerHealthClient({http.Client? client}) : _explicitClient = client;

  final http.Client? _explicitClient;

  Future<bool> check({
    required String ledgerBaseUrl,
    required String adminKey,
  }) async {
    final normalized = ledgerBaseUrl.trim().replaceAll(RegExp(r'/$'), '');
    final healthUrl = normalized.endsWith('/api/ledger')
        ? '$normalized/health'
        : '$normalized/api/ledger/health';

    final client =
        _explicitClient ?? await ServerConfigService().createHttpClient();
    try {
      final response = await client.get(
        Uri.parse(healthUrl),
        headers: {
          if (adminKey.trim().isNotEmpty) 'X-Admin-Key': adminKey.trim(),
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return false;

      if (response.body.trim().isEmpty) return true;
      final parsed = jsonDecode(response.body);
      if (parsed is Map<String, dynamic>) {
        final status = parsed['status'];
        return status == null || status == 'ok';
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      if (_explicitClient == null) client.close();
    }
  }
}
