import 'package:shared_preferences/shared_preferences.dart';
import '../utils/pref_keys.dart';

/// Simple privacy toggle service to control masking of sensitive fields in UI.
class PrivacyService {
  static const _prefKey = PrefKeys.privacyMaskSensitive;
  static bool _mask = true;

  const PrivacyService._();

  /// Returns current in-memory mask flag. Defaults to true for safety.
  static bool maskSensitive() => _mask;

  /// Loads persisted preference (if any). Should be called on app start.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_prefKey);
    if (v != null) _mask = v;
  }

  /// Sets and persists the masking preference.
  static Future<void> setMask(bool value) async {
    _mask = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }
}
