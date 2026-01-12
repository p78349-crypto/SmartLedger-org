import '../models/transaction.dart';
import 'spending_analysis_algorithms.dart';
import 'spending_analysis_models.dart';
import 'stats_calculator.dart';

/// 지출 분석 메인 유틸리티 클래스
class SpendingAnalysisUtils {
  /// TOP N 지출 항목 분석 (품목명 기준)
  static List<ItemSpendingAnalysis> getTopSpendingItems({
    required List<Transaction> transactions,
    int topN = 5,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var filtered = StatsCalculator.filterByType(
      transactions,
      TransactionType.expense,
    );

    if (startDate != null && endDate != null) {
      filtered = StatsCalculator.filterByRange(filtered, startDate, endDate);
    }

    final grouped = <String, List<Transaction>>{};
    for (final tx in filtered) {
      final name = spendingNormalizeItemName(tx.description);
      grouped.putIfAbsent(name, () => []).add(tx);
    }

    final totalSpending = StatsCalculator.calculateTotal(filtered);

    final analyses = grouped.entries.map((entry) {
      final txList = entry.value;
      final total = StatsCalculator.calculateTotal(txList);
      return ItemSpendingAnalysis(
        name: entry.key,
        totalAmount: total,
        count: txList.length,
        avgAmount: total / txList.length,
        percentage: totalSpending > 0 ? (total / totalSpending * 100) : 0,
        transactions: txList,
        category: txList.first.mainCategory,
        store: txList.first.store,
      );
    }).toList();

    analyses.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return analyses.take(topN).toList();
  }

  /// TOP N 지출 카테고리 분석 (대분류 기준)
  static List<CategorySpendingSummary> getTopSpendingCategories({
    required List<Transaction> transactions,
    int topN = 5,
    DateTime? currentMonth,
  }) {
    return spendingGetTopSpendingCategories(
      transactions: transactions,
      topN: topN,
      currentMonth: currentMonth,
      getTopSpendingItems: getTopSpendingItems,
    );
  }

  /// 반복 지출 패턴 감지
  static List<RecurringSpendingPattern> detectRecurringPatterns({
    required List<Transaction> transactions,
    int minOccurrences = 3,
    int maxIntervalDays = 45,
  }) {
    return spendingDetectRecurringPatterns(
      transactions: transactions,
      minOccurrences: minOccurrences,
      maxIntervalDays: maxIntervalDays,
    );
  }

  /// 중복 구매 위험 항목 감지
  static List<RecurringSpendingPattern> detectDuplicatePurchaseRisk({
    required List<Transaction> transactions,
    int lookbackDays = 30,
  }) {
    final patterns = detectRecurringPatterns(transactions: transactions);
    final now = DateTime.now();
    final risks = <RecurringSpendingPattern>[];

    for (final pattern in patterns) {
      if (pattern.predictedNextPurchase == null) continue;

      final lastPurchase = pattern.purchaseDates.last;
      final daysSinceLastPurchase = now.difference(lastPurchase).inDays;

      if (daysSinceLastPurchase < pattern.avgInterval * 0.7) {
        risks.add(pattern);
      }
    }

    return risks;
  }

  /// 주간 TOP N 지출 항목
  static List<ItemSpendingAnalysis> getWeeklyTopSpending({
    required List<Transaction> transactions,
    DateTime? weekStart,
    int topN = 5,
  }) {
    weekStart ??= DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    final weekEnd = weekStart.add(const Duration(days: 6));

    return getTopSpendingItems(
      transactions: transactions,
      topN: topN,
      startDate: weekStart,
      endDate: weekEnd,
    );
  }

  /// 월간 TOP N 지출 항목
  static List<ItemSpendingAnalysis> getMonthlyTopSpending({
    required List<Transaction> transactions,
    DateTime? month,
    int topN = 5,
  }) {
    month ??= DateTime.now();
    final monthStart = DateTime(month.year, month.month);
    final monthEnd = DateTime(month.year, month.month + 1, 0);

    return getTopSpendingItems(
      transactions: transactions,
      topN: topN,
      startDate: monthStart,
      endDate: monthEnd,
    );
  }

  /// 특정 품목의 지출 트렌드 (최근 N개월)
  static List<double> getItemSpendingTrend({
    required List<Transaction> transactions,
    required String itemName,
    int months = 6,
  }) {
    return spendingGetItemSpendingTrend(
      transactions: transactions,
      itemName: itemName,
      months: months,
    );
  }

  /// 마트/상점별 지출 분석
  static List<ItemSpendingAnalysis> getTopSpendingStores({
    required List<Transaction> transactions,
    int topN = 5,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var filtered = StatsCalculator.filterByType(
      transactions,
      TransactionType.expense,
    );

    if (startDate != null && endDate != null) {
      filtered = StatsCalculator.filterByRange(filtered, startDate, endDate);
    }

    final grouped = <String, List<Transaction>>{};
    for (final tx in filtered) {
      final store = tx.store ?? '기타';
      grouped.putIfAbsent(store, () => []).add(tx);
    }

    final totalSpending = StatsCalculator.calculateTotal(filtered);

    final analyses = grouped.entries.map((entry) {
      final txList = entry.value;
      final total = StatsCalculator.calculateTotal(txList);
      return ItemSpendingAnalysis(
        name: entry.key,
        totalAmount: total,
        count: txList.length,
        avgAmount: total / txList.length,
        percentage: totalSpending > 0 ? (total / totalSpending * 100) : 0,
        transactions: txList,
        store: entry.key,
      );
    }).toList();

    analyses.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return analyses.take(topN).toList();
  }
}
