import '../models/transaction.dart';

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
    final months =
        ((lastDate.year - firstDate.year) * 12 + lastDate.month - firstDate.month)
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
    final variance =
        intervals.map((i) => (i - avg) * (i - avg)).reduce((a, b) => a + b) /
            intervals.length;
    final stdDev = variance > 0 ? variance / avg : 0.0;
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
