import '../models/consumable_inventory_item.dart';

/// 월별 예상 지출, 예산 알림 유틸리티
class CostPredictionUtils {
  /// 기본 월별 예산 (계정별)
  static const int defaultMonthlyBudget = 500000; // 50만원

  /// 현재 월의 식재료 총 가격
  static double getCurrentMonthTotalCost(List<ConsumableInventoryItem> items) {
    final now = DateTime.now();
    return items
        .where((item) {
          // 이번 달에 등록된 항목만
          final date = _effectiveDate(item);
          return date.year == now.year && date.month == now.month;
        })
        .fold(0.0, (sum, item) => sum + (item.price ?? 0.0));
  }

  /// 월별 예상 지출 계산 (현재 추세 기반)
  static double predictMonthlyExpense(
    List<ConsumableInventoryItem> items,
    DateTime targetMonth,
  ) {
    if (items.isEmpty) return 0;

    // 최근 3개월 평균 계산
    double totalCost = 0;
    int monthCount = 0;

    for (int i = 0; i < 3; i++) {
      final month = DateTime(targetMonth.year, targetMonth.month - i);
      final monthCost = items
          .where((item) {
            final date = _effectiveDate(item);
            return date.year == month.year && date.month == month.month;
          })
          .fold(0.0, (sum, item) => sum + (item.price ?? 0.0));

      if (monthCost > 0) {
        totalCost += monthCost;
        monthCount++;
      }
    }

    if (monthCount == 0) return 0;
    return totalCost / monthCount;
  }

  /// 예산 대비 실제 소비 분석
  static BudgetAnalysis analyzeBudget(
    List<ConsumableInventoryItem> items, {
    int monthlyBudget = defaultMonthlyBudget,
  }) {
    final currentCost = getCurrentMonthTotalCost(items);
    final remaining = (monthlyBudget - currentCost).toDouble();
    final usage = (currentCost / monthlyBudget * 100).toStringAsFixed(1);

    return BudgetAnalysis(
      monthlyBudget: monthlyBudget.toDouble(),
      currentCost: currentCost,
      remaining: remaining,
      usagePercentage: double.parse(usage),
      isOverBudget: currentCost > monthlyBudget,
    );
  }

  /// 초과 예산 경고 메시지
  static String getBudgetWarning(BudgetAnalysis analysis) {
    if (analysis.isOverBudget) {
      final excess = analysis.currentCost - analysis.monthlyBudget;
      return '⚠️ 예산 초과! ${excess.toStringAsFixed(0)}원 초과했습니다.';
    } else if (analysis.usagePercentage > 80) {
      return '🟡 예산 경고! 남은 예산: ${analysis.remaining.toStringAsFixed(0)}원';
    } else if (analysis.usagePercentage > 50) {
      return '💚 적절한 범위. 남은 예산: ${analysis.remaining.toStringAsFixed(0)}원';
    } else {
      return '✅ 예산 여유 있음. 남은 예산: ${analysis.remaining.toStringAsFixed(0)}원';
    }
  }

  /// 일일 평균 지출 계산
  static double getDailyAverageExpense(List<ConsumableInventoryItem> items) {
    if (items.isEmpty) return 0;

    final totalCost = items.fold(0.0, (sum, item) => sum + (item.price ?? 0.0));
    const daysInMonth = 30;

    return totalCost / daysInMonth;
  }

  /// 카테고리별 지출 분석
  static Map<String, double> getCategorySpending(
    List<ConsumableInventoryItem> items,
  ) {
    final spending = <String, double>{};

    for (final item in items) {
      final category = item.category;
      spending[category] = (spending[category] ?? 0.0) + (item.price ?? 0.0);
    }

    return spending;
  }

  /// 카테고리별 지출 추천 메시지
  static String getCategorySpendingAdvice(
    Map<String, double> spending,
    int monthlyBudget,
  ) {
    if (spending.isEmpty) return '지출 데이터가 없습니다.';

    final entries = spending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategory = entries.first;
    final percentage = (topCategory.value / monthlyBudget * 100)
        .toStringAsFixed(1);

    return '💡 가장 많이 지출하는 카테고리: ${topCategory.key} ($percentage%)';
  }

  /// 저렴한 식재료 추천 (절약 목표)
  static List<ConsumableInventoryItem> getAffordableAlternatives(
    List<ConsumableInventoryItem> items,
    double priceThreshold,
  ) {
    return items.where((item) => (item.price ?? 0.0) <= priceThreshold).toList()
      ..sort((a, b) => (a.price ?? 0.0).compareTo(b.price ?? 0.0));
  }

  /// 예상 절약액 계산 (저가 식재료로 전환시)
  static double calculatePotentialSavings(
    List<ConsumableInventoryItem> items,
    double targetPricePerItem,
  ) {
    final currentTotal = items.fold(
      0.0,
      (sum, item) => sum + (item.price ?? 0.0),
    );
    final potentialTotal = items.length * targetPricePerItem;

    return currentTotal - potentialTotal;
  }

  /// 월별 지출 트렌드 분석
  static String getMonthlyTrend(
    List<ConsumableInventoryItem> items,
    DateTime currentMonth,
  ) {
    double thisMonthCost = 0;
    double lastMonthCost = 0;

    for (final item in items) {
      final date = _effectiveDate(item);
      if (date.year == currentMonth.year && date.month == currentMonth.month) {
        thisMonthCost += item.price ?? 0.0;
      } else if (date.year == currentMonth.year &&
          date.month == currentMonth.month - 1) {
        lastMonthCost += item.price ?? 0.0;
      }
    }

    if (lastMonthCost == 0) return '지난 달 데이터가 없습니다.';

    final change = thisMonthCost - lastMonthCost;
    final percentage = (change / lastMonthCost * 100).toStringAsFixed(1);

    if (change > 0) {
      return '📈 지난 달 대비 $percentage% 증가했습니다.';
    } else if (change < 0) {
      return '📉 지난 달 대비 ${percentage.replaceFirst('-', '')}% 감소했습니다.';
    } else {
      return '➡️ 지난 달과 동일한 수준입니다.';
    }
  }

  /// 최적 구매 시기 분석
  static String getOptimalPurchasingAdvice(
    List<ConsumableInventoryItem> items,
    int monthlyBudget,
  ) {
    final analysis = analyzeBudget(items, monthlyBudget: monthlyBudget);

    if (analysis.usagePercentage < 30) {
      return '🛒 충분한 예산이 있습니다. 필요한 식재료를 구입해도 좋습니다.';
    } else if (analysis.usagePercentage < 60) {
      return '🛒 적절한 시점입니다. 필수 식재료만 구입하세요.';
    } else if (analysis.usagePercentage < 80) {
      return '⚠️ 예산이 부족해집니다. 필수 식재료만 구입하세요.';
    } else {
      return '🛑 예산이 거의 남지 않았습니다. 구입을 자제하세요.';
    }
  }

  static DateTime _effectiveDate(ConsumableInventoryItem item) {
    return item.purchaseDate ?? item.expiryDate ?? item.createdAt;
  }
}

/// 예산 분석 결과
class BudgetAnalysis {
  final double monthlyBudget;
  final double currentCost;
  final double remaining;
  final double usagePercentage;
  final bool isOverBudget;

  BudgetAnalysis({
    required this.monthlyBudget,
    required this.currentCost,
    required this.remaining,
    required this.usagePercentage,
    required this.isOverBudget,
  });

  String get statusEmoji {
    if (isOverBudget) return '⚠️';
    if (usagePercentage > 80) return '🟡';
    if (usagePercentage > 50) return '💚';
    return '✅';
  }

  String get statusText {
    if (isOverBudget) return '초과';
    if (usagePercentage > 80) return '경고';
    if (usagePercentage > 50) return '적절';
    return '여유';
  }
}
