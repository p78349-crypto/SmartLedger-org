import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/pref_keys.dart';

/// Gold-medal style reward counters that accumulate over time.
///
/// - Stored in SharedPreferences
/// - Supports "award once" with a dedupe key to prevent double increments
///   (useful for manual + auto triggers)
class RewardBadgeService {
  RewardBadgeService._();

  static final RewardBadgeService instance = RewardBadgeService._();

  static const String _suffixCountsV1 = 'reward_badge_counts_v1';
  static const String _suffixAwardedKeysV1 = 'reward_badge_awarded_keys_v1';

  static const String typeProject100m = 'project100m';
  static const String typeSkippedSpend = 'skippedSpend';
  static const String typeFoodRescue = 'foodRescue';

  static const List<String> types = <String>[
    typeProject100m,
    typeSkippedSpend,
    typeFoodRescue,
  ];

  String _countsKey(String accountName) =>
      PrefKeys.accountKey(accountName, _suffixCountsV1);

  String _awardedKey(String accountName, String type) =>
      PrefKeys.accountKey(accountName, '${_suffixAwardedKeysV1}_$type');

  Future<Map<String, int>> getCounts(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_countsKey(accountName));
    if (raw == null || raw.trim().isEmpty) {
      return <String, int>{for (final t in types) t: 0};
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return <String, int>{for (final t in types) t: 0};
      }
      final out = <String, int>{for (final t in types) t: 0};
      for (final t in types) {
        final v = decoded[t];
        if (v is int) out[t] = v;
      }
      return out;
    } catch (_) {
      return <String, int>{for (final t in types) t: 0};
    }
  }

  Future<int> getCount(String accountName, String type) async {
    final counts = await getCounts(accountName);
    return counts[type] ?? 0;
  }

  Future<void> _setCounts(String accountName, Map<String, int> counts) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = <String, int>{for (final t in types) t: 0};
    for (final e in counts.entries) {
      if (!normalized.containsKey(e.key)) continue;
      final v = e.value;
      normalized[e.key] = v < 0 ? 0 : v;
    }
    await prefs.setString(_countsKey(accountName), jsonEncode(normalized));
  }

  Future<bool> awardOnce({
    required String accountName,
    required String type,
    required String dedupeKey,
    int incrementBy = 1,
  }) async {
    final t = type.trim();
    if (!types.contains(t)) return false;
    final dk = dedupeKey.trim();
    if (dk.isEmpty) return false;
    if (incrementBy <= 0) return false;

    final prefs = await SharedPreferences.getInstance();

    // Dedupe: keep a bounded list of awarded keys for each type.
    final awardedRaw =
        prefs.getStringList(_awardedKey(accountName, t)) ?? <String>[];
    if (awardedRaw.contains(dk)) return false;

    final nextAwarded = <String>[...awardedRaw, dk];
    const maxKeys = 400;
    if (nextAwarded.length > maxKeys) {
      nextAwarded.removeRange(0, nextAwarded.length - maxKeys);
    }
    await prefs.setStringList(_awardedKey(accountName, t), nextAwarded);

    final counts = await getCounts(accountName);
    counts[t] = (counts[t] ?? 0) + incrementBy;
    await _setCounts(accountName, counts);

    return true;
  }
}
