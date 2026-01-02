import 'package:shared_preferences/shared_preferences.dart';

class AccountOptionService {
  static String _key(String account, String option) => 'opt_${account}_$option';

  static String _prefix(String account) => 'opt_${account}_';

  static Future<Map<String, bool>> exportOptions(String account) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = _prefix(account);
    final out = <String, bool>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(prefix)) continue;
      final option = key.substring(prefix.length);
      if (option.isEmpty) continue;
      final value = prefs.getBool(key);
      if (value == null) continue;
      out[option] = value;
    }
    return out;
  }

  static Future<void> importOptions(
    String account,
    Map<String, dynamic> options,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = _prefix(account);
    final keysToRemove = prefs
        .getKeys()
        .where((k) => k.startsWith(prefix))
        .toList();
    for (final key in keysToRemove) {
      await prefs.remove(key);
    }

    for (final entry in options.entries) {
      final option = entry.key;
      final value = entry.value;
      if (value is bool) {
        await prefs.setBool(_key(account, option), value);
      }
    }
  }

  static Future<bool> getOption(
    String account,
    String option, {
    bool defaultValue = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(account, option)) ?? defaultValue;
  }

  static Future<void> setOption(
    String account,
    String option,
    bool value,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(account, option), value);
  }
}

