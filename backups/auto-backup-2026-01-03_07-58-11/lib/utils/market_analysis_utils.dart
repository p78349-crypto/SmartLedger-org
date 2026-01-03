import 'package:smart_ledger/models/transaction.dart';

/// 시장 분석 및 통계 유틸리티
/// - 품목별 가격 추이
/// - 최저가 시기 예측
/// - 구매 패턴 분석

class PriceStatistics {
  final String itemName;
  final double averagePrice;
  final double minPrice;
  final double maxPrice;
  final int purchaseCount;
  final DateTime? cheapestDate;

  PriceStatistics({
    required this.itemName,
    required this.averagePrice,
    required this.minPrice,
    required this.maxPrice,
    required this.purchaseCount,
    this.cheapestDate,
  });

  /// 가격 변동폭
  double get priceRange => maxPrice - minPrice;

  /// 변동폭 비율 (%)
  double get volatilityPercent {
    if (averagePrice <= 0) return 0;
    return (priceRange / averagePrice) * 100;
  }

  @override
  String toString() => 'PriceStatistics($itemName: ₩$averagePrice avg)';
}

class MarketAnalysisUtils {
  /// 품목별 통계 계산
  static PriceStatistics analyzeItemPrice(
    String itemName,
    List<Transaction> transactions,
  ) {
    final filtered = transactions
        .where((t) => t.description.toLowerCase() == itemName.toLowerCase())
        .toList();

    if (filtered.isEmpty) {
      return PriceStatistics(
        itemName: itemName,
        averagePrice: 0,
        minPrice: 0,
        maxPrice: 0,
        purchaseCount: 0,
      );
    }

    final prices = filtered.map((t) => t.unitPrice).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;

    // 최저가 거래 찾기
    final cheapestTransaction = filtered.reduce(
      (a, b) => a.unitPrice < b.unitPrice ? a : b,
    );

    return PriceStatistics(
      itemName: itemName,
      averagePrice: avgPrice,
      minPrice: minPrice,
      maxPrice: maxPrice,
      purchaseCount: filtered.length,
      cheapestDate: cheapestTransaction.date,
    );
  }

  /// 상위 구매 품목 (가격 기준)
  static List<String> getTopPurchasedItems(
    List<Transaction> transactions, {
    int limit = 5,
  }) {
    final itemMap = <String, int>{};
    for (final t in transactions) {
      itemMap[t.description] = (itemMap[t.description] ?? 0) + 1;
    }

    final sorted = itemMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// 카테고리별 지출 합계
  static Map<String, double> getCategorySpending(
    List<Transaction> transactions,
  ) {
    final categoryMap = <String, double>{};
    for (final t in transactions) {
      final category = t.mainCategory.isEmpty ? 'unknown' : t.mainCategory;
      categoryMap[category] = (categoryMap[category] ?? 0) + t.amount;
    }

    return categoryMap;
  }

  /// 월별 지출 트렌드
  static Map<String, double> getMonthlySpending(
    List<Transaction> transactions,
  ) {
    final monthMap = <String, double>{};
    for (final t in transactions) {
      if (t.type == TransactionType.income) continue;

      final monthKey =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      monthMap[monthKey] = (monthMap[monthKey] ?? 0) + t.amount;
    }

    return monthMap;
  }

  /// 최저가 시기 추천
  static String? recommendCheapestMonth(
    String itemName,
    List<Transaction> transactions,
  ) {
    final filtered = transactions
        .where((t) => t.description.toLowerCase() == itemName.toLowerCase())
        .toList();

    if (filtered.isEmpty) return null;

    final monthPrices = <String, List<double>>{};
    for (final t in filtered) {
      final monthKey =
          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      monthPrices[monthKey] ??= [];
      monthPrices[monthKey]!.add(t.unitPrice);
    }

    String? cheapestMonth;
    double? cheapestAvg;

    for (final entry in monthPrices.entries) {
      final avgPrice = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (cheapestAvg == null || avgPrice < cheapestAvg) {
        cheapestMonth = entry.key;
        cheapestAvg = avgPrice;
      }
    }

    return cheapestMonth;
  }

  /// AI 시장 리포트 생성 (시뮬레이션)
  static String generateAIReport(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return '데이터가 쌓이면 품목별 최저가 시기를 예측해 드립니다.';
    }

    final topItems = getTopPurchasedItems(transactions, limit: 3);
    final categorySpending = getCategorySpending(transactions);

    if (topItems.isEmpty) {
      return 'AI 분석 중입니다. 더 많은 데이터가 필요합니다.';
    }

    final topCategory = categorySpending.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    return '''
최근 구매 분석:
• 자주 구매한 품목: ${topItems.join(', ')}
• 최대 지출 카테고리: ${topCategory.key} (₩${topCategory.value.toStringAsFixed(0)})
💡 팁: ${topItems.first} 구매 시기를 최적화하면 절약할 수 있습니다.
''';
  }
}

