import '../models/transaction.dart';
import 'spending_analysis_models.dart';
import 'stats_calculator.dart';

String spendingNormalizeItemName(String name) {
  return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

int spendingCalculateMonthSpan(List<Transaction> transactions) {
  if (transactions.isEmpty) return 0;
  final dates = transactions.map((t) => t.date).toList()..sort();
  final firstDate = dates.first;
  final lastDate = dates.last;
  return ((lastDate.year - firstDate.year) * 12 +
          lastDate.month -
          firstDate.month)
      .clamp(1, 999);
}

List<CategorySpendingSummary> spendingGetTopSpendingCategories({
  required List<Transaction> transactions,
  required int topN,
  DateTime? currentMonth,
  required List<ItemSpendingAnalysis> Function({
    required List<Transaction> transactions,
    required int topN,
    DateTime? startDate,
    DateTime? endDate,
  }) getTopSpendingItems,
}) {
  currentMonth ??= DateTime.now();

  final currentMonthStart = DateTime(currentMonth.year, currentMonth.month);
  final currentMonthEnd = DateTime(
    currentMonth.year,
    currentMonth.month + 1,
    0,
  );
  final currentMonthTx = StatsCalculator.filterByRange(
    StatsCalculator.filterByType(transactions, TransactionType.expense),
    currentMonthStart,
    currentMonthEnd,
  );

  final prevMonthStart = DateTime(currentMonth.year, currentMonth.month - 1);
  final prevMonthEnd = DateTime(currentMonth.year, currentMonth.month, 0);
  final prevMonthTx = StatsCalculator.filterByRange(
    StatsCalculator.filterByType(transactions, TransactionType.expense),
    prevMonthStart,
    prevMonthEnd,
  );

  final allExpenses = StatsCalculator.filterByType(
    transactions,
    TransactionType.expense,
  );

  final categoryStats = StatsCalculator.calculateCategoryStats(
    currentMonthTx,
    TransactionType.expense,
  );

  final prevCategoryTotals = <String, double>{};
  for (final tx in prevMonthTx) {
    final cat = tx.mainCategory.isEmpty
        ? Transaction.defaultMainCategory
        : tx.mainCategory;
    prevCategoryTotals[cat] = (prevCategoryTotals[cat] ?? 0) + tx.amount;
  }

  final months = spendingCalculateMonthSpan(allExpenses);

  final summaries = categoryStats.map((catStat) {
    final allCategoryTx = StatsCalculator.filterByCategory(
      allExpenses,
      catStat.category,
      TransactionType.expense,
    );
    final allCategoryTotal = StatsCalculator.calculateTotal(allCategoryTx);

    final prevTotal = prevCategoryTotals[catStat.category] ?? 0;
    final momChange = prevTotal > 0
        ? ((catStat.total - prevTotal) / prevTotal * 100)
        : (catStat.total > 0 ? 100 : 0);

    final topItems = getTopSpendingItems(
      transactions: catStat.transactions,
      topN: 3,
    );

    return CategorySpendingSummary(
      category: catStat.category,
      totalAmount: catStat.total,
      percentage: catStat.percentage,
      transactionCount: catStat.count,
      topItems: topItems,
      monthOverMonthChange: momChange.toDouble(),
      avgMonthlySpending: months > 0 ? allCategoryTotal / months : 0,
    );
  }).toList();

  return summaries.take(topN).toList();
}

List<RecurringSpendingPattern> spendingDetectRecurringPatterns({
  required List<Transaction> transactions,
  required int minOccurrences,
  required int maxIntervalDays,
}) {
  final expenses = StatsCalculator.filterByType(
    transactions,
    TransactionType.expense,
  );

  final grouped = <String, List<Transaction>>{};
  for (final tx in expenses) {
    final name = spendingNormalizeItemName(tx.description);
    grouped.putIfAbsent(name, () => []).add(tx);
  }

  final patterns = <RecurringSpendingPattern>[];

  for (final entry in grouped.entries) {
    if (entry.value.length < minOccurrences) continue;

    final txList = entry.value..sort((a, b) => a.date.compareTo(b.date));
    final dates = txList.map((t) => t.date).toList();

    final intervals = <int>[];
    for (int i = 1; i < dates.length; i++) {
      intervals.add(dates[i].difference(dates[i - 1]).inDays);
    }

    if (intervals.isEmpty) continue;

    final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

    if (avgInterval > maxIntervalDays) continue;

    final monthSpan = spendingCalculateMonthSpan(txList);
    final frequency = monthSpan > 0
        ? (txList.length / monthSpan).round()
        : txList.length;

    final lastPurchase = dates.last;
    final predictedNext = lastPurchase.add(
      Duration(days: avgInterval.round()),
    );

    final avgAmount = StatsCalculator.calculateTotal(txList) / txList.length;

    patterns.add(
      RecurringSpendingPattern(
        name: entry.key,
        avgAmount: avgAmount,
        frequency: frequency,
        avgInterval: avgInterval,
        predictedNextPurchase: predictedNext,
        purchaseDates: dates,
        category: txList.first.mainCategory,
      ),
    );
  }

  patterns.sort((a, b) => b.frequency.compareTo(a.frequency));
  return patterns;
}

List<double> spendingGetItemSpendingTrend({
  required List<Transaction> transactions,
  required String itemName,
  required int months,
}) {
  final normalizedName = spendingNormalizeItemName(itemName);
  final now = DateTime.now();
  final trend = <double>[];

  for (int i = months - 1; i >= 0; i--) {
    final monthStart = DateTime(now.year, now.month - i);
    final monthEnd = DateTime(now.year, now.month - i + 1, 0);

    final monthTx = StatsCalculator.filterByRange(
      transactions,
      monthStart,
      monthEnd,
    ).where(
      (tx) =>
          tx.type == TransactionType.expense &&
          spendingNormalizeItemName(tx.description) == normalizedName,
    );

    trend.add(StatsCalculator.calculateTotal(monthTx.toList()));
  }

  return trend;
}
