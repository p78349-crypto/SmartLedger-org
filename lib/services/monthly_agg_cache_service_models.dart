part of 'monthly_agg_cache_service.dart';

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
