import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

/// Stores and retrieves recently used input values (up to 5) per logical key.
class RecentInputService {
  static const int _maxEntries = 5;

  const RecentInputService._();

  /// Returns the stored memo values, newest first.
  static Future<List<String>> loadMemos() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(PrefKeys.recentMemos) ?? const [];
  }

  /// Inserts [value] for memos, moving it to the front and trimming the list.
  static Future<List<String>> saveMemo(String value) async {
    return _saveValue(PrefKeys.recentMemos, value);
  }

  /// Returns the stored payment methods, newest first.
  static Future<List<String>> loadPaymentMethods() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(PrefKeys.recentPaymentMethods) ?? const [];
  }

  /// Inserts payment method, moving it to the front and trimming the list.
  static Future<List<String>> savePaymentMethod(String value) async {
    return _saveValue(PrefKeys.recentPaymentMethods, value);
  }

  /// Returns the stored categories, newest first.
  static Future<List<String>> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(PrefKeys.recentCategories) ?? const [];
  }

  /// Inserts category, moving it to the front and trimming the list.
  static Future<List<String>> saveCategory(String value) async {
    return _saveValue(PrefKeys.recentCategories, value);
  }

  /// Generic method for saving values with key
  static Future<List<String>> saveValue(String key, String value) async {
    return _saveValue(key, value);
  }

  /// Returns the stored values for [key], newest first.
  static Future<List<String>> loadValues(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? const [];
  }

  /// Overwrites stored values for [key] with [values].
  ///
  /// Values are normalized (trim, non-empty), de-duplicated (first wins),
  /// and truncated to [_maxEntries].
  static Future<void> replaceValues(String key, List<String> values) async {
    final normalized = <String>[];
    final seen = <String>{};
    for (final raw in values) {
      final v = raw.trim();
      if (v.isEmpty) continue;
      if (seen.contains(v)) continue;
      seen.add(v);
      normalized.add(v);
      if (normalized.length >= _maxEntries) break;
    }

    final prefs = await SharedPreferences.getInstance();
    if (normalized.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setStringList(key, normalized);
  }

  /// Removes the stored list for [key].
  static Future<void> clearValues(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  /// Internal helper to save values
  static Future<List<String>> _saveValue(String key, String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return loadValues(key);
    }
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(key) ?? <String>[];
    current.remove(trimmed);
    current.insert(0, trimmed);
    if (current.length > _maxEntries) {
      current.removeRange(_maxEntries, current.length);
    }
    await prefs.setStringList(key, current);
    return current;
  }
}

