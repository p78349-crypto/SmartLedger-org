import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/pref_keys.dart';
import '../utils/store_memo_utils.dart';

class StoreAliasService {
  StoreAliasService._();

  static String _prefsKeyForAccount(String accountName) {
    return PrefKeys.accountKey(accountName, PrefKeys.storeAliasMapV1Suffix);
  }

  static String? _normalizeStoreKey(String? raw) {
    final extracted = StoreMemoUtils.extractStoreKey(raw);
    if (extracted == null) return null;
    final trimmed = extracted.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Map<String, String> _decodeMap(Object? raw) {
    if (raw is! String) return const <String, String>{};
    if (raw.trim().isEmpty) return const <String, String>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <String, String>{};

      final out = <String, String>{};
      for (final e in decoded.entries) {
        final k = _normalizeStoreKey(e.key?.toString());
        final v = _normalizeStoreKey(e.value?.toString());
        if (k == null || v == null) continue;
        if (k == v) continue;
        out[k] = v;
      }
      return out;
    } catch (_) {
      return const <String, String>{};
    }
  }

  static String _encodeMap(Map<String, String> map) {
    final cleaned = <String, String>{};
    for (final e in map.entries) {
      final k = _normalizeStoreKey(e.key);
      final v = _normalizeStoreKey(e.value);
      if (k == null || v == null) continue;
      if (k == v) continue;
      cleaned[k] = v;
    }
    return jsonEncode(cleaned);
  }

  static Future<Map<String, String>> loadMap(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKeyForAccount(accountName));
    return _decodeMap(raw);
  }

  static Future<void> replaceMap(
    String accountName, {
    required Map<String, String> map,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _prefsKeyForAccount(accountName);

    if (map.isEmpty) {
      await prefs.remove(key);
      return;
    }

    await prefs.setString(key, _encodeMap(map));
  }

  static Future<void> setAlias(
    String accountName, {
    required String alias,
    required String canonical,
  }) async {
    final a = _normalizeStoreKey(alias);
    final c = _normalizeStoreKey(canonical);

    final key = _prefsKeyForAccount(accountName);
    final prefs = await SharedPreferences.getInstance();

    final map = _decodeMap(prefs.getString(key));

    if (a == null || c == null || a == c) {
      map.remove(a);
    } else {
      map[a] = c;
    }

    await replaceMap(accountName, map: map);
  }

  static Future<void> removeAlias(
    String accountName, {
    required String alias,
  }) async {
    final a = _normalizeStoreKey(alias);
    if (a == null) return;

    final key = _prefsKeyForAccount(accountName);
    final prefs = await SharedPreferences.getInstance();

    final map = _decodeMap(prefs.getString(key));
    map.remove(a);

    await replaceMap(accountName, map: map);
  }

  /// Resolve a store key to its canonical representative.
  ///
  /// - Applies transitive mapping (A->B, B->C => C)
  /// - Protects against cycles (A->B, B->A)
  /// - If invalid/cyclic, returns the original key.
  static String resolve(String storeKey, Map<String, String> aliasToCanonical) {
    final start = _normalizeStoreKey(storeKey);
    if (start == null) return storeKey;

    final visited = <String>{};
    var current = start;

    for (var i = 0; i < 12; i++) {
      if (!visited.add(current)) {
        // Cycle detected.
        return start;
      }

      final next = aliasToCanonical[current];
      final normalizedNext = _normalizeStoreKey(next);
      if (normalizedNext == null || normalizedNext == current) {
        return current;
      }

      current = normalizedNext;
    }

    // Depth limit reached; keep it safe.
    return start;
  }
}
