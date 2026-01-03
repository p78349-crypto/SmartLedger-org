import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

class CategoryUsageService {
  static const String separator = ' · ';
  static const int _maxEntries = 200;

  const CategoryUsageService._();

  static String labelFor({required String main, String? sub}) {
    final normalizedMain = main.trim();
    final normalizedSub = sub?.trim();
    if (normalizedSub == null || normalizedSub.isEmpty) {
      return normalizedMain;
    }
    return '$normalizedMain$separator$normalizedSub';
  }

  static Future<Map<String, int>> loadCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(PrefKeys.categoryUsageCountsV1);
    if (raw == null || raw.trim().isEmpty) return const <String, int>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <String, int>{};

      final map = <String, int>{};
      decoded.forEach((k, v) {
        if (k is! String) return;
        final key = k.trim();
        if (key.isEmpty) return;

        int? count;
        if (v is int) {
          count = v;
        } else if (v is num) {
          count = v.toInt();
        } else if (v is String) {
          count = int.tryParse(v);
        }

        if (count == null || count <= 0) return;
        map[key] = count;
      });

      return Map.unmodifiable(map);
    } catch (_) {
      return const <String, int>{};
    }
  }

  static int countForLabel(Map<String, int> counts, String label) {
    return counts[label.trim()] ?? 0;
  }

  static int countForMain(Map<String, int> counts, String main) {
    final m = main.trim();
    if (m.isEmpty) return 0;

    var sum = 0;
    for (final entry in counts.entries) {
      final k = entry.key;
      if (k == m || k.startsWith('$m$separator')) {
        sum += entry.value;
      }
    }
    return sum;
  }

  static Future<void> increment({required String main, String? sub}) async {
    final label = labelFor(main: main, sub: sub);
    if (label.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final current = await loadCounts();
    final next = <String, int>{...current};
    next[label] = (next[label] ?? 0) + 1;

    _trimInPlace(next);

    await prefs.setString(PrefKeys.categoryUsageCountsV1, jsonEncode(next));
  }

  static Future<void> replaceCounts(Map<String, int> counts) async {
    final prefs = await SharedPreferences.getInstance();

    final normalized = <String, int>{};
    for (final entry in counts.entries) {
      final k = entry.key.trim();
      if (k.isEmpty) continue;
      final v = entry.value;
      if (v <= 0) continue;
      normalized[k] = v;
    }

    _trimInPlace(normalized);

    if (normalized.isEmpty) {
      await prefs.remove(PrefKeys.categoryUsageCountsV1);
      return;
    }

    await prefs.setString(
      PrefKeys.categoryUsageCountsV1,
      jsonEncode(normalized),
    );
  }

  static Future<void> clearCounts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(PrefKeys.categoryUsageCountsV1);
  }

  static void _trimInPlace(Map<String, int> map) {
    if (map.length <= _maxEntries) return;

    final sorted = map.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    map
      ..clear()
      ..addEntries(sorted.take(_maxEntries));
  }
}
