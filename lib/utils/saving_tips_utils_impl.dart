import 'saving_tips_database.dart';
import 'saving_tips_models.dart';
import 'spending_analysis_utils.dart';

/// 절약 팁 생성 유틸리티
class SavingTipsUtils {
  /// 카테고리별 맞춤 팁 제공
  static List<SavingTip> getTipsForCategory(String category) {
    final normalizedCategory = category.toLowerCase();

    if (normalizedCategory.contains('외식') ||
        normalizedCategory.contains('식당') ||
        normalizedCategory.contains('배달')) {
      return SavingTipsDatabase.diningOutTips;
    }

    if (normalizedCategory.contains('카페') ||
        normalizedCategory.contains('커피') ||
        normalizedCategory.contains('음료')) {
      return SavingTipsDatabase.beverageTips;
    }

    if (normalizedCategory.contains('생활') ||
        normalizedCategory.contains('용품') ||
        normalizedCategory.contains('세제') ||
        normalizedCategory.contains('생필품')) {
      return SavingTipsDatabase.householdTips;
    }

    if (normalizedCategory.contains('식료') ||
        normalizedCategory.contains('마트') ||
        normalizedCategory.contains('장보기') ||
        normalizedCategory.contains('식품') ||
        normalizedCategory.contains('식재료')) {
      return SavingTipsDatabase.groceryTips;
    }

    if (normalizedCategory.contains('교통') ||
        normalizedCategory.contains('주유') ||
        normalizedCategory.contains('택시')) {
      return SavingTipsDatabase.transportTips;
    }

    if (normalizedCategory.contains('쇼핑') ||
        normalizedCategory.contains('의류') ||
        normalizedCategory.contains('패션')) {
      return SavingTipsDatabase.shoppingTips;
    }

    return SavingTipsDatabase.loyaltyTips;
  }

  /// 지출 분석 결과 기반 맞춤 팁 생성
  static List<SavingTip> generateTipsFromAnalysis({
    required List<CategorySpendingSummary> topCategories,
    required List<RecurringSpendingPattern> recurringPatterns,
    int maxTips = 5,
  }) {
    final tips = <SavingTip>[];

    for (final category in topCategories.take(3)) {
      final categoryTips = getTipsForCategory(category.category);
      if (categoryTips.isEmpty) continue;

      final tip = categoryTips.first;
      final estimatedSaving = category.totalAmount * 0.2;
      tips.add(
        SavingTip(
          title: tip.title,
          description: tip.description,
          type: tip.type,
          category: category.category,
          estimatedMonthlySaving: estimatedSaving,
          actionItems: tip.actionItems,
          priority: tip.priority,
        ),
      );
    }

    for (final pattern in recurringPatterns.take(3)) {
      if (pattern.frequency < 4) continue;

      tips.add(
        SavingTip(
          title: '${pattern.name} 구매 패턴 발견',
          description:
              '월 평균 ${pattern.frequency}회 구매 중입니다. '
              '대용량 구매나 구독 서비스를 고려해보세요.',
          type: SavingTipType.bulk,
          category: pattern.category,
          estimatedMonthlySaving: pattern.avgAmount * pattern.frequency * 0.15,
          actionItems: [
            '대용량 제품으로 전환 시 약 15% 절약 가능',
            '정기배송 서비스 할인 확인하기',
            '묶음 구매 프로모션 활용하기',
          ],
          priority: 2,
          relatedItem: pattern.name,
        ),
      );
    }

    for (final category in topCategories) {
      if (category.monthOverMonthChange <= 30) continue;

      tips.add(
        SavingTip(
          title: '${category.category} 지출 급증 주의',
          description:
              '전월 대비 '
              '${category.monthOverMonthChange.toStringAsFixed(0)}% '
              '증가했습니다. '
              '지출 원인을 점검해보세요.',
          type: SavingTipType.habit,
          category: category.category,
          actionItems: [
            '이번 달 ${category.category} 내역 확인하기',
            '불필요한 지출이 있었는지 검토하기',
            '다음 달 예산 재설정하기',
          ],
          priority: 1,
        ),
      );
    }

    if (tips.length < maxTips) {
      tips.add(SavingTipsDatabase.loyaltyTips.first);
    }

    tips.sort((a, b) => a.priority.compareTo(b.priority));
    return tips.take(maxTips).toList();
  }

  /// 중복 구매 위험 항목에 대한 팁 생성
  static List<SavingTip> generateDuplicatePurchaseWarnings(
    List<RecurringSpendingPattern> risks,
  ) {
    return risks.map((pattern) {
      final daysSinceLast = DateTime.now()
          .difference(pattern.purchaseDates.last)
          .inDays;
      final nextPurchaseIn = pattern.avgInterval.round() - daysSinceLast;

      return SavingTip(
        title: '${pattern.name} 재구매 주의',
        description:
            '최근 $daysSinceLast일 전에 구매했습니다. '
            '평균 구매 주기(${pattern.avgInterval.round()}일)에 따르면 '
            '약 $nextPurchaseIn일 후 구매하면 적절합니다.',
        type: SavingTipType.habit,
        category: pattern.category,
        actionItems: [
          '구매 전 집에 재고가 있는지 확인하세요',
          '장보기 전 목록 작성 습관을 들이세요',
          '필요 시점까지 구매를 미뤄보세요',
        ],
        priority: 1,
        relatedItem: pattern.name,
      );
    }).toList();
  }

  /// 예상 월간 총 절약 금액 계산
  static double calculateTotalPotentialSavings(List<SavingTip> tips) {
    return tips.fold(0.0, (sum, tip) {
      return sum + (tip.estimatedMonthlySaving ?? 0);
    });
  }

  /// 팁 타입별 아이콘 이름
  static String getTipTypeIcon(SavingTipType type) {
    switch (type) {
      case SavingTipType.challenge:
        return 'emoji_events';
      case SavingTipType.comparison:
        return 'compare_arrows';
      case SavingTipType.timing:
        return 'schedule';
      case SavingTipType.alternative:
        return 'swap_horiz';
      case SavingTipType.habit:
        return 'psychology';
      case SavingTipType.bulk:
        return 'inventory_2';
      case SavingTipType.subscription:
        return 'autorenew';
      case SavingTipType.loyalty:
        return 'card_giftcard';
    }
  }

  /// 팁 타입 라벨
  static String getTipTypeLabel(SavingTipType type) {
    switch (type) {
      case SavingTipType.challenge:
        return '챌린지';
      case SavingTipType.comparison:
        return '비교 분석';
      case SavingTipType.timing:
        return '타이밍';
      case SavingTipType.alternative:
        return '대안 제안';
      case SavingTipType.habit:
        return '습관 개선';
      case SavingTipType.bulk:
        return '대량 구매';
      case SavingTipType.subscription:
        return '구독 서비스';
      case SavingTipType.loyalty:
        return '포인트/할인';
    }
  }
}
