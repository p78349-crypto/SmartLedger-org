import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/quick_simple_expense_input_history_service.dart';

@immutable
class MonthlyAggBucket {
  final String yearMonth; // YYYY-MM

  // ---- Transaction totals (for fast long-range stats) ----
  final double incomeAmount; // income + refund
  final int incomeCount; // income + refund

  final double refundAmount;
  final int refundCount;

  /// Expense aggregation used by AccountStatsScreen:
  /// expense + savings(allocation=expense)
  final double expenseAggAmount;
  final int expenseAggCount;

  /// Pure expense-only (tx.type == expense)
  final double expenseOnlyAmount;
  final int expenseOnlyCount;

  /// All savings (includes savings that are counted as expense)
  final double savingsTotalAmount;
  final int savingsTotalCount;

  /// Savings that are treated as expense (allocation=expense)
  final double savingsExpenseAmount;
  final int savingsExpenseCount;

  // ---- Memo numeric aggregation (optional) ----
  // (for future memo stats fast path)
  final double memoOutflowAmountAbs;
  final int memoOutflowCount;

  // ---- Quick input numeric aggregation (optional) ----
  final double quickInputAmount;
  final int quickInputCount;

  // ---- Card discount numeric aggregation (optional) ----
  // Definition:
  // - Only expense transactions with cardChargedAmount.
  // - discount = max(0, abs(amount) - cardChargedAmount)
  final double cardDiscountAmount;
  final int cardDiscountCount;

  const MonthlyAggBucket({
    required this.yearMonth,
    required this.incomeAmount,
    required this.incomeCount,
    required this.refundAmount,
    required this.refundCount,
    required this.expenseAggAmount,
    required this.expenseAggCount,
    required this.expenseOnlyAmount,
    required this.expenseOnlyCount,
    required this.savingsTotalAmount,
    required this.savingsTotalCount,
    required this.savingsExpenseAmount,
    required this.savingsExpenseCount,
    required this.memoOutflowAmountAbs,
    required this.memoOutflowCount,
    required this.quickInputAmount,
    required this.quickInputCount,
    required this.cardDiscountAmount,
    required this.cardDiscountCount,
  });

  factory MonthlyAggBucket.zero(String yearMonth) => MonthlyAggBucket(
        yearMonth: yearMonth,
        incomeAmount: 0,
        incomeCount: 0,
        refundAmount: 0,
        refundCount: 0,
        expenseAggAmount: 0,
        expenseAggCount: 0,
        expenseOnlyAmount: 0,
        expenseOnlyCount: 0,
        savingsTotalAmount: 0,
        savingsTotalCount: 0,
        savingsExpenseAmount: 0,
        savingsExpenseCount: 0,
        memoOutflowAmountAbs: 0,
        memoOutflowCount: 0,
        quickInputAmount: 0,
        quickInputCount: 0,
      cardDiscountAmount: 0,
      cardDiscountCount: 0,
      );

  double amountForType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return expenseAggAmount;
      case TransactionType.income:
        return incomeAmount;
      case TransactionType.refund:
        return refundAmount;
      case TransactionType.savings:
        // Savings view excludes savings counted as expense.
        return savingsTotalAmount - savingsExpenseAmount;
    }
  }

  int countForType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return expenseAggCount;
      case TransactionType.income:
        return incomeCount;
      case TransactionType.refund:
        return refundCount;
      case TransactionType.savings:
        return savingsTotalCount - savingsExpenseCount;
    }
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'yearMonth': yearMonth,
        'incomeAmount': incomeAmount,
        'incomeCount': incomeCount,
        'refundAmount': refundAmount,
        'refundCount': refundCount,
        'expenseAggAmount': expenseAggAmount,
        'expenseAggCount': expenseAggCount,
        'expenseOnlyAmount': expenseOnlyAmount,
        'expenseOnlyCount': expenseOnlyCount,
        'savingsTotalAmount': savingsTotalAmount,
        'savingsTotalCount': savingsTotalCount,
        'savingsExpenseAmount': savingsExpenseAmount,
        'savingsExpenseCount': savingsExpenseCount,
        'memoOutflowAmountAbs': memoOutflowAmountAbs,
        'memoOutflowCount': memoOutflowCount,
        'quickInputAmount': quickInputAmount,
        'quickInputCount': quickInputCount,
      'cardDiscountAmount': cardDiscountAmount,
      'cardDiscountCount': cardDiscountCount,
      };

  static MonthlyAggBucket? fromJson(Object? json) {
    if (json is! Map) return null;

    final yearMonth = json['yearMonth'];
    if (yearMonth is! String || yearMonth.trim().isEmpty) return null;

    double readDouble(String key) {
      final v = json[key];
      return (v is num) ? v.toDouble() : 0.0;
    }

    int readInt(String key) {
      final v = json[key];
      return (v is int) ? v : (v is num ? v.toInt() : 0);
    }

    return MonthlyAggBucket(
      yearMonth: yearMonth,
      incomeAmount: readDouble('incomeAmount'),
      incomeCount: readInt('incomeCount'),
      refundAmount: readDouble('refundAmount'),
      refundCount: readInt('refundCount'),
      expenseAggAmount: readDouble('expenseAggAmount'),
      expenseAggCount: readInt('expenseAggCount'),
      expenseOnlyAmount: readDouble('expenseOnlyAmount'),
      expenseOnlyCount: readInt('expenseOnlyCount'),
      savingsTotalAmount: readDouble('savingsTotalAmount'),
      savingsTotalCount: readInt('savingsTotalCount'),
      savingsExpenseAmount: readDouble('savingsExpenseAmount'),
      savingsExpenseCount: readInt('savingsExpenseCount'),
      memoOutflowAmountAbs: readDouble('memoOutflowAmountAbs'),
      memoOutflowCount: readInt('memoOutflowCount'),
      quickInputAmount: readDouble('quickInputAmount'),
      quickInputCount: readInt('quickInputCount'),
      cardDiscountAmount: readDouble('cardDiscountAmount'),
      cardDiscountCount: readInt('cardDiscountCount'),
    );
  }
}

@immutable
class MonthlyAggCache {
  final int version;
  final Map<String, MonthlyAggBucket> months; // key=YYYY-MM

  const MonthlyAggCache({required this.version, required this.months});

  factory MonthlyAggCache.empty() =>
      const MonthlyAggCache(version: 1, months: {});

  Map<String, Object?> toJson() => <String, Object?>{
        'version': version,
        'months': months.map((k, v) => MapEntry(k, v.toJson())),
      };

  static MonthlyAggCache fromJson(Object? json) {
    if (json is! Map) return MonthlyAggCache.empty();
    final version = (json['version'] is int) ? (json['version'] as int) : 1;

    final rawMonths = json['months'];
    if (rawMonths is! Map) {
      return MonthlyAggCache(version: version, months: const {});
    }

    final out = <String, MonthlyAggBucket>{};
    rawMonths.forEach((key, value) {
      if (key is! String) return;
      final bucket = MonthlyAggBucket.fromJson(value);
      if (bucket == null) return;
      out[key] = bucket;
    });

    return MonthlyAggCache(version: version, months: out);
  }
}

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
      final d = DateTime(now.year, now.month - i, 1);
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
  /// - In-app screensaver refresh
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
    final allowed =
        recentYearMonths(now: DateTime.now(), maxMonths: maxMonths).toSet();
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
      bucket.quickInputAmount += e.amount;
    }

    return acc.map((k, v) => MapEntry(k, v.build()));
  }
}

class _BucketAccumulator {
  final String yearMonth;

  double incomeAmount = 0;
  int incomeCount = 0;

  double refundAmount = 0;
  int refundCount = 0;

  double expenseAggAmount = 0;
  int expenseAggCount = 0;

  double expenseOnlyAmount = 0;
  int expenseOnlyCount = 0;

  double savingsTotalAmount = 0;
  int savingsTotalCount = 0;

  double savingsExpenseAmount = 0;
  int savingsExpenseCount = 0;

  double memoOutflowAmountAbs = 0;
  int memoOutflowCount = 0;

  double quickInputAmount = 0;
  int quickInputCount = 0;

  double cardDiscountAmount = 0;
  int cardDiscountCount = 0;

  _BucketAccumulator(this.yearMonth);

  bool _isSavingsCountedAsExpense(Transaction tx) {
    if (tx.type != TransactionType.savings) return false;
    final alloc = tx.savingsAllocation ?? SavingsAllocation.assetIncrease;
    return alloc == SavingsAllocation.expense;
  }

  void applyTransaction(Transaction tx) {
    switch (tx.type) {
      case TransactionType.income:
        incomeAmount += tx.amount;
        incomeCount += 1;
        break;
      case TransactionType.refund:
        refundAmount += tx.amount;
        refundCount += 1;
        incomeAmount += tx.amount;
        incomeCount += 1;
        break;
      case TransactionType.expense:
        expenseOnlyAmount += tx.amount;
        expenseOnlyCount += 1;
        expenseAggAmount += tx.amount;
        expenseAggCount += 1;

        final charged = tx.cardChargedAmount;
        if (charged != null) {
          final baseAbs = tx.amount.abs();
          final discount = baseAbs - charged.abs();
          if (discount > 0) {
            cardDiscountAmount += discount;
            cardDiscountCount += 1;
          }
        }
        break;
      case TransactionType.savings:
        savingsTotalAmount += tx.amount;
        savingsTotalCount += 1;
        if (_isSavingsCountedAsExpense(tx)) {
          savingsExpenseAmount += tx.amount;
          savingsExpenseCount += 1;
          expenseAggAmount += tx.amount;
          expenseAggCount += 1;
        }
        break;
    }

    final memo = tx.memo.trim();
    if (memo.isNotEmpty && tx.type.isOutflow) {
      memoOutflowCount += 1;
      memoOutflowAmountAbs += tx.amount.abs();
    }
  }

  MonthlyAggBucket build() {
    return MonthlyAggBucket(
      yearMonth: yearMonth,
      incomeAmount: incomeAmount,
      incomeCount: incomeCount,
      refundAmount: refundAmount,
      refundCount: refundCount,
      expenseAggAmount: expenseAggAmount,
      expenseAggCount: expenseAggCount,
      expenseOnlyAmount: expenseOnlyAmount,
      expenseOnlyCount: expenseOnlyCount,
      savingsTotalAmount: savingsTotalAmount,
      savingsTotalCount: savingsTotalCount,
      savingsExpenseAmount: savingsExpenseAmount,
      savingsExpenseCount: savingsExpenseCount,
      memoOutflowAmountAbs: memoOutflowAmountAbs,
      memoOutflowCount: memoOutflowCount,
      quickInputAmount: quickInputAmount,
      quickInputCount: quickInputCount,
      cardDiscountAmount: cardDiscountAmount,
      cardDiscountCount: cardDiscountCount,
    );
  }
}

