/// 지출 분석 유틸리티
///
/// TOP 5 지출 항목 분석, 반복 지출 패턴 감지, 구매 주기 예측 등
/// 사용자에게 실질적인 지출 인사이트를 제공합니다.
library;

import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/stats_calculator.dart';

/// 항목별 지출 분석 결과
class ItemSpendingAnalysis {
  final String name;
  final double totalAmount;
  final int count;
  final double avgAmount;
  final double percentage;
  final List<Transaction> transactions;
  final String? category;
  final String? store;

  const ItemSpendingAnalysis({
    required this.name,
    required this.totalAmount,
    required this.count,
    required this.avgAmount,
    required this.percentage,
    required this.transactions,
    this.category,
    this.store,
  });

  /// 월평균 지출 (거래 기간 기준)
  double get monthlyAverage {
    if (transactions.isEmpty) return 0;
    final dates = transactions.map((t) => t.date).toList()..sort();
    final firstDate = dates.first;
    final lastDate = dates.last;
    final months = ((lastDate.year - firstDate.year) * 12 +
            lastDate.month -
            firstDate.month)
        .clamp(1, 999);
    return totalAmount / months;
  }
}

/// 반복 지출 패턴
class RecurringSpendingPattern {
  final String name;
  final double avgAmount;
  final int frequency; // 월 평균 횟수
  final double avgInterval; // 평균 구매 간격 (일)
  final DateTime? predictedNextPurchase;
  final List<DateTime> purchaseDates;
  final String? category;

  const RecurringSpendingPattern({
    required this.name,
    required this.avgAmount,
    required this.frequency,
    required this.avgInterval,
    this.predictedNextPurchase,
    required this.purchaseDates,
    this.category,
  });

  /// 예측 정확도 (0~1, 간격 일관성 기반)
  double get predictionConfidence {
    if (purchaseDates.length < 3) return 0.0;
    final intervals = <int>[];
    for (int i = 1; i < purchaseDates.length; i++) {
      intervals.add(purchaseDates[i].difference(purchaseDates[i - 1]).inDays);
    }
    if (intervals.isEmpty) return 0.0;
    final avg = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals.map((i) => (i - avg) * (i - avg)).reduce((a, b) => a + b) / intervals.length;
    final stdDev = variance > 0 ? variance / avg : 0.0;
    // 표준편차가 낮을수록 높은 신뢰도
    return (1.0 - stdDev.clamp(0.0, 1.0)).clamp(0.3, 1.0);
  }
}

/// 카테고리별 지출 요약
class CategorySpendingSummary {
  final String category;
  final double totalAmount;
  final double percentage;
  final int transactionCount;
  final List<ItemSpendingAnalysis> topItems;
  final double monthOverMonthChange; // 전월 대비 변동 (%)
  final double avgMonthlySpending;

  const CategorySpendingSummary({
    required this.category,
    required this.totalAmount,
    required this.percentage,
    required this.transactionCount,
    required this.topItems,
    required this.monthOverMonthChange,
    required this.avgMonthlySpending,
  });
}

/// 지출 분석 메인 유틸리티 클래스
class SpendingAnalysisUtils {
  /// TOP N 지출 항목 분석 (품목명 기준)
  static List<ItemSpendingAnalysis> getTopSpendingItems({
    required List<Transaction> transactions,
    int topN = 5,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    // 지출 타입만 필터링
    var filtered = StatsCalculator.filterByType(
      transactions,
      TransactionType.expense,
    );

    // 기간 필터링
    if (startDate != null && endDate != null) {
      filtered = StatsCalculator.filterByRange(filtered, startDate, endDate);
    }

    // 품목명(description)으로 그룹화
    final grouped = <String, List<Transaction>>{};
    for (final tx in filtered) {
      final name = _normalizeItemName(tx.description);
      grouped.putIfAbsent(name, () => []).add(tx);
    }

    final totalSpending = StatsCalculator.calculateTotal(filtered);

    // 분석 결과 생성
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

    // 금액 내림차순 정렬 후 TOP N 반환
    analyses.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return analyses.take(topN).toList();
  }

  /// TOP N 지출 카테고리 분석 (대분류 기준)
  static List<CategorySpendingSummary> getTopSpendingCategories({
    required List<Transaction> transactions,
    int topN = 5,
    DateTime? currentMonth,
  }) {
    currentMonth ??= DateTime.now();

    // 현재 월 거래
    final currentMonthStart = DateTime(currentMonth.year, currentMonth.month);
    final currentMonthEnd = DateTime(currentMonth.year, currentMonth.month + 1, 0);
    final currentMonthTx = StatsCalculator.filterByRange(
      StatsCalculator.filterByType(transactions, TransactionType.expense),
      currentMonthStart,
      currentMonthEnd,
    );

    // 이전 월 거래 (비교용)
    final prevMonthStart = DateTime(currentMonth.year, currentMonth.month - 1);
    final prevMonthEnd = DateTime(currentMonth.year, currentMonth.month, 0);
    final prevMonthTx = StatsCalculator.filterByRange(
      StatsCalculator.filterByType(transactions, TransactionType.expense),
      prevMonthStart,
      prevMonthEnd,
    );

    // 전체 기간 (평균 계산용)
    final allExpenses = StatsCalculator.filterByType(
      transactions,
      TransactionType.expense,
    );

    // 현재 월 카테고리별 집계
    final categoryStats = StatsCalculator.calculateCategoryStats(
      currentMonthTx,
      TransactionType.expense,
    );

    // 이전 월 카테고리별 합계 맵
    final prevCategoryTotals = <String, double>{};
    for (final tx in prevMonthTx) {
      final cat = tx.mainCategory.isEmpty
          ? Transaction.defaultMainCategory
          : tx.mainCategory;
      prevCategoryTotals[cat] = (prevCategoryTotals[cat] ?? 0) + tx.amount;
    }

    // 전체 기간 월수 계산
    final months = _calculateMonthSpan(allExpenses);

    final summaries = categoryStats.map((catStat) {
      // 해당 카테고리의 전체 기간 합계
      final allCategoryTx = StatsCalculator.filterByCategory(
        allExpenses,
        catStat.category,
        TransactionType.expense,
      );
      final allCategoryTotal = StatsCalculator.calculateTotal(allCategoryTx);

      // 전월 대비 변동
      final prevTotal = prevCategoryTotals[catStat.category] ?? 0;
      final momChange = prevTotal > 0
          ? ((catStat.total - prevTotal) / prevTotal * 100)
          : (catStat.total > 0 ? 100 : 0);

      // 해당 카테고리 내 TOP 3 품목
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

  /// 반복 지출 패턴 감지
  static List<RecurringSpendingPattern> detectRecurringPatterns({
    required List<Transaction> transactions,
    int minOccurrences = 3, // 최소 반복 횟수
    int maxIntervalDays = 45, // 최대 구매 간격 (일)
  }) {
    final expenses = StatsCalculator.filterByType(
      transactions,
      TransactionType.expense,
    );

    // 품목명으로 그룹화
    final grouped = <String, List<Transaction>>{};
    for (final tx in expenses) {
      final name = _normalizeItemName(tx.description);
      grouped.putIfAbsent(name, () => []).add(tx);
    }

    final patterns = <RecurringSpendingPattern>[];

    for (final entry in grouped.entries) {
      if (entry.value.length < minOccurrences) continue;

      // 날짜 정렬
      final txList = entry.value..sort((a, b) => a.date.compareTo(b.date));
      final dates = txList.map((t) => t.date).toList();

      // 구매 간격 계산
      final intervals = <int>[];
      for (int i = 1; i < dates.length; i++) {
        intervals.add(dates[i].difference(dates[i - 1]).inDays);
      }

      if (intervals.isEmpty) continue;

      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;

      // 평균 간격이 너무 길면 반복 패턴으로 보지 않음
      if (avgInterval > maxIntervalDays) continue;

      // 월 평균 빈도 계산
      final monthSpan = _calculateMonthSpan(txList);
      final frequency = monthSpan > 0 ? (txList.length / monthSpan).round() : txList.length;

      // 다음 구매 예측
      final lastPurchase = dates.last;
      final predictedNext = lastPurchase.add(Duration(days: avgInterval.round()));

      // 평균 금액
      final avgAmount = StatsCalculator.calculateTotal(txList) / txList.length;

      patterns.add(RecurringSpendingPattern(
        name: entry.key,
        avgAmount: avgAmount,
        frequency: frequency,
        avgInterval: avgInterval,
        predictedNextPurchase: predictedNext,
        purchaseDates: dates,
        category: txList.first.mainCategory,
      ));
    }

    // 빈도순 정렬
    patterns.sort((a, b) => b.frequency.compareTo(a.frequency));
    return patterns;
  }

  /// 중복 구매 위험 항목 감지
  /// 최근 구매한 항목 중 재구매 주기가 아직 안 된 것들
  static List<RecurringSpendingPattern> detectDuplicatePurchaseRisk({
    required List<Transaction> transactions,
    int lookbackDays = 30,
  }) {
    final patterns = detectRecurringPatterns(transactions: transactions);
    final now = DateTime.now();
    final risks = <RecurringSpendingPattern>[];

    for (final pattern in patterns) {
      if (pattern.predictedNextPurchase == null) continue;

      // 마지막 구매일
      final lastPurchase = pattern.purchaseDates.last;
      final daysSinceLastPurchase = now.difference(lastPurchase).inDays;

      // 평균 간격의 70% 이하면 아직 구매 시기가 아님
      if (daysSinceLastPurchase < pattern.avgInterval * 0.7) {
        risks.add(pattern);
      }
    }

    return risks;
  }

  /// 주간 TOP 5 지출 항목
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

  /// 월간 TOP 5 지출 항목
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

  /// 특정 품목의 지출 트렌드 (최근 6개월)
  static List<double> getItemSpendingTrend({
    required List<Transaction> transactions,
    required String itemName,
    int months = 6,
  }) {
    final normalizedName = _normalizeItemName(itemName);
    final now = DateTime.now();
    final trend = <double>[];

    for (int i = months - 1; i >= 0; i--) {
      final monthStart = DateTime(now.year, now.month - i);
      final monthEnd = DateTime(now.year, now.month - i + 1, 0);

      final monthTx = StatsCalculator.filterByRange(
        transactions,
        monthStart,
        monthEnd,
      ).where((tx) =>
          tx.type == TransactionType.expense &&
          _normalizeItemName(tx.description) == normalizedName);

      trend.add(StatsCalculator.calculateTotal(monthTx.toList()));
    }

    return trend;
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

    // store로 그룹화
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

  // === Private Helpers ===

  /// 품목명 정규화 (공백 제거, 소문자 변환 등)
  static String _normalizeItemName(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// 거래 목록의 월 범위 계산
  static int _calculateMonthSpan(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0;
    final dates = transactions.map((t) => t.date).toList()..sort();
    final firstDate = dates.first;
    final lastDate = dates.last;
    return ((lastDate.year - firstDate.year) * 12 +
            lastDate.month -
            firstDate.month)
        .clamp(1, 999);
  }
}
