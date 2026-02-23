import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/pref_keys.dart';

class ServerConfigService {
  ServerConfigService._internal();
  static final ServerConfigService _instance = ServerConfigService._internal();
  factory ServerConfigService() => _instance;

  Future<String?> getServerAddress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefKeys.serverAddress);
  }

  Future<String?> getAdminKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefKeys.adminKey);
  }

  Future<void> saveServerConfig(String address, String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.serverAddress, address);
    await prefs.setString(PrefKeys.adminKey, key);
  }

  Future<bool> checkHealth() async {
    final address = await getServerAddress();
    final key = await getAdminKey();

    if (address == null || address.isEmpty || key == null || key.isEmpty) {
      return false;
    }

    try {
      final response = await http.get(
        Uri.parse('$address/api/ledger/health'),
        headers: {
          'X-Admin-Key': key,
        },
      ).timeout(const Duration(seconds: 3));

      return response.statusCode == 200;
    } catch (e) {
      return false;
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
