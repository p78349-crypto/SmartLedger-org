import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction.dart';
import 'quick_simple_expense_input_history_service.dart';

part 'monthly_agg_cache_service_models.dart';
part 'monthly_agg_cache_service_accumulator.dart';

/// Monthly numeric pre-aggregation cache.
///
/// Goals:
/// - Keep long-range stats (up to 10 years) fast by using month buckets.
/// - Preserve accuracy by allowing month-level rebuild after edits.
/// - Avoid heavy work on every write by tracking dirty months and rebuilding
///   when needed (e.g., on stats screens load).
class MonthlyAggCacheService {
  static final MonthlyAggCacheService _instance =
      MonthlyAggCacheService._internal();
  factory MonthlyAggCacheService() => _instance;
  MonthlyAggCacheService._internal();

  static const int defaultMaxMonths = 120; // 10 years
  static const int _moneyScale = 6;

  static double _normalizeMoney(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    final normalized = double.parse(value.toStringAsFixed(_moneyScale));
    if (normalized == -0.0) return 0.0;
    return normalized;
  }

  static String _cacheKeyFor(String accountName) {
    final safe = accountName.trim();
    return 'monthly_agg_cache_v1_$safe';
  }

  static String _dirtyKeyFor(String accountName) {
    final safe = accountName.trim();
    return 'monthly_agg_dirty_months_v1_$safe';
  }

  static String _autoBuildStampKeyFor(String accountName) {
    final safe = accountName.trim();
    return 'monthly_agg_autobuild_stamp_v1_$safe';
  }

  static String _autoBuildYmKeyFor(String accountName) {
    final safe = accountName.trim();
    return 'monthly_agg_autobuild_ym_v1_$safe';
  }

  static String yearMonthOf(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  static List<String> recentYearMonths({
    required DateTime now,
    required int maxMonths,
  }) {
    final out = <String>[];
    for (var i = 0; i < maxMonths; i++) {
      final d = DateTime(now.year, now.month - i);
      out.add(yearMonthOf(d));
    }
    return out;
  }

  Future<MonthlyAggCache> load(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKeyFor(accountName));
    if (raw == null || raw.trim().isEmpty) return MonthlyAggCache.empty();

    try {
      final decoded = jsonDecode(raw);
      return MonthlyAggCache.fromJson(decoded);
    } catch (_) {
      return MonthlyAggCache.empty();
    }
  }

  Future<void> save(String accountName, MonthlyAggCache cache) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(cache.toJson());
    await prefs.setString(_cacheKeyFor(accountName), encoded);
  }

  Future<Set<String>> loadDirtyMonths(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    final items = prefs.getStringList(_dirtyKeyFor(accountName)) ?? const [];
    return items.where((e) => e.trim().isNotEmpty).toSet();
  }

  Future<void> markDirty(String accountName, Set<String> yearMonths) async {
    if (yearMonths.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = await loadDirtyMonths(accountName);
    final next = <String>{...current, ...yearMonths};
    await prefs.setStringList(_dirtyKeyFor(accountName), next.toList());
  }

  Future<void> clearDirtyMonths(String accountName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dirtyKeyFor(accountName));
  }

  /// Auto-builds the monthly cache only when needed (dirty months exist), and
  /// throttles execution to avoid heavy work on frequent refresh loops.
  ///
  /// Intended use:
  /// - App start / first account screen
  Future<void> autoEnsureBuiltIfDirtyThrottled({
    required String accountName,
    required List<Transaction> transactions,
    Duration minIntervalSameMonth = const Duration(hours: 6),
    int maxMonths = defaultMaxMonths,
    bool includeQuickInput = false,
  }) async {
    final dirty = await loadDirtyMonths(accountName);
    if (dirty.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final nowYm = yearMonthOf(now);
    final lastMs = prefs.getInt(_autoBuildStampKeyFor(accountName)) ?? 0;
    final lastYm = prefs.getString(_autoBuildYmKeyFor(accountName));

    if (lastMs > 0 && lastYm == nowYm) {
      final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
      if (now.difference(last) < minIntervalSameMonth) {
        return;
      }
    }

    await ensureBuilt(
      accountName: accountName,
      transactions: transactions,
      maxMonths: maxMonths,
      includeQuickInput: includeQuickInput,
    );

    await prefs.setInt(
      _autoBuildStampKeyFor(accountName),
      now.millisecondsSinceEpoch,
    );
    await prefs.setString(_autoBuildYmKeyFor(accountName), nowYm);
  }

  /// Ensures the cache exists and is up-to-date for dirty months.
  ///
  /// This is intended to be called from stats screens initialization.
  Future<MonthlyAggCache> ensureBuilt({
    required String accountName,
    required List<Transaction> transactions,
    int maxMonths = defaultMaxMonths,
    bool includeQuickInput = false,
  }) async {
    final existing = await load(accountName);

    final dirty = await loadDirtyMonths(accountName);

    // If never built, build the entire recent window.
    if (existing.months.isEmpty) {
      final quick = includeQuickInput
          ? await QuickSimpleExpenseInputHistoryService().loadEntries(
              accountName,
            )
          : const <QuickSimpleExpenseInputEntry>[];

      final built = rebuildRecentMonths(
        now: DateTime.now(),
        transactions: transactions,
        quickEntries: quick,
        maxMonths: maxMonths,
      );
      await save(accountName, built);
      await clearDirtyMonths(accountName);
      return built;
    }

    if (dirty.isEmpty) {
      // Keep only the recent window even when nothing is dirty.
      final trimmed = _trimToRecent(existing, maxMonths: maxMonths);
      if (!mapEquals(trimmed.months, existing.months)) {
        await save(accountName, trimmed);
        return trimmed;
      }
      return existing;
    }

    final quick = includeQuickInput
        ? await QuickSimpleExpenseInputHistoryService().loadEntries(accountName)
        : const <QuickSimpleExpenseInputEntry>[];

    final rebuilt = rebuildSpecificMonths(
      base: existing,
      transactions: transactions,
      quickEntries: quick,
      monthsToRebuild: dirty,
      now: DateTime.now(),
      maxMonths: maxMonths,
    );

    await save(accountName, rebuilt);
    await clearDirtyMonths(accountName);
    return rebuilt;
  }

  MonthlyAggCache rebuildRecentMonths({
    required DateTime now,
    required List<Transaction> transactions,
    required List<QuickSimpleExpenseInputEntry> quickEntries,
    int maxMonths = defaultMaxMonths,
  }) {
    final allowed = recentYearMonths(now: now, maxMonths: maxMonths).toSet();
    final buckets = _buildBuckets(
      allowed: allowed,
      transactions: transactions,
      quickEntries: quickEntries,
    );
    return MonthlyAggCache(version: 1, months: buckets);
  }

  MonthlyAggCache rebuildSpecificMonths({
    required MonthlyAggCache base,
    required List<Transaction> transactions,
    required List<QuickSimpleExpenseInputEntry> quickEntries,
    required Set<String> monthsToRebuild,
    required DateTime now,
    int maxMonths = defaultMaxMonths,
  }) {
    final recent = recentYearMonths(now: now, maxMonths: maxMonths).toSet();

    // Rebuild only months within the retention window.
    final target = monthsToRebuild.where(recent.contains).toSet();
    if (target.isEmpty) {
      return _trimToRecent(base, maxMonths: maxMonths);
    }

    final rebuiltBuckets = _buildBuckets(
      allowed: target,
      transactions: transactions,
      quickEntries: quickEntries,
    );

    final next = <String, MonthlyAggBucket>{...base.months};
    for (final entry in rebuiltBuckets.entries) {
      next[entry.key] = entry.value;
    }

    final trimmed = _trimToRecent(
      MonthlyAggCache(version: base.version, months: next),
      maxMonths: maxMonths,
    );
    return trimmed;
  }

  MonthlyAggCache _trimToRecent(
    MonthlyAggCache cache, {
    required int maxMonths,
  }) {
    final allowed = recentYearMonths(
      now: DateTime.now(),
      maxMonths: maxMonths,
    ).toSet();
    final next = <String, MonthlyAggBucket>{};
    for (final entry in cache.months.entries) {
      if (allowed.contains(entry.key)) {
        next[entry.key] = entry.value;
      }
    }
    return MonthlyAggCache(version: cache.version, months: next);
  }

  Map<String, MonthlyAggBucket> _buildBuckets({
    required Set<String> allowed,
    required List<Transaction> transactions,
    required List<QuickSimpleExpenseInputEntry> quickEntries,
  }) {
    final acc = <String, _BucketAccumulator>{
      for (final ym in allowed) ym: _BucketAccumulator(ym),
    };

    for (final tx in transactions) {
      final ym = yearMonthOf(tx.date);
      final bucket = acc[ym];
      if (bucket == null) continue;

      bucket.applyTransaction(tx);
    }

    for (final e in quickEntries) {
      final ym = yearMonthOf(e.createdAt);
      final bucket = acc[ym];
      if (bucket == null) continue;

      bucket.quickInputCount += 1;
      bucket.quickInputAmount = _normalizeMoney(
        bucket.quickInputAmount + e.amount,
      );
    }

    return acc.map((k, v) => MapEntry(k, v.build()));
  }
}
