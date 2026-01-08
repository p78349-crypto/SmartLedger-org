import 'package:smart_ledger/models/cooking_usage_log.dart';

/// 절약 통계 계산을 담당하는 유틸리티 클래스
/// 이 클래스는 pure 계산 함수들을 제공하므로, 어디서든 재사용 가능합니다.
class SavingsStatisticsUtils {
  const SavingsStatisticsUtils._();

  /// 냉파 성공 지수: 챌린지 기간(20일~말일) 동안 추가 구매 없이 해결한 끼니 수
  static int calculateCookingSuccessIndex(List<CookingUsageLog> logs) {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1);

    // 20일부터 말일까지의 기간
    final challengeStart = DateTime(now.year, now.month, 20);
    final challengeEnd = nextMonth.subtract(const Duration(days: 1));

    return logs
        .where((log) =>
            log.isFromExistingInventory &&
            log.usageDate.isAfter(challengeStart) &&
            log.usageDate.isBefore(challengeEnd.add(const Duration(days: 1))))
        .length;
  }

  /// 구조된 식재료: 유통기한 임박 알림을 받았으나 버리지 않고 요리에 활용한 식재료의 총 가치
  static double calculateSavedIngredientsValue(List<CookingUsageLog> logs) {
    return logs
        .where((log) => log.memo.contains('임박') || log.isFromExistingInventory)
        .fold<double>(0, (sum, log) => sum + log.totalUsedPrice);
  }

  /// 월별 식비 지출 변화 데이터 계산
  static Map<String, double> calculateMonthlyFoodExpenses(
      List<dynamic> transactions) {
    final result = <String, double>{};

    for (final tx in transactions) {
      // 식비 관련 카테고리만 필터
      if (_isFoodCategory(tx.mainCategory)) {
        final monthKey =
            '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}';
        result[monthKey] = (result[monthKey] ?? 0) + tx.amount;
      }
    }

    return result;
  }

  /// 식비 카테고리 판정
  static bool _isFoodCategory(String category) {
    const foodKeywords = ['식품', '식비', '음료', 'food', 'drink'];
    return foodKeywords
        .any((keyword) => category.toLowerCase().contains(keyword));
  }

  /// 두 달간의 지출 비교
  static ({
    double beforePrice,
    double afterPrice,
    double savingsAmount,
    double savingsPercent
  }) compareSavings(Map<String, double> monthlyExpenses) {
    final now = DateTime.now();

    // 이번 달
    final thisMonthKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final afterPrice = monthlyExpenses[thisMonthKey] ?? 0.0;

    // 지난 달
    final beforeDate = DateTime(now.year, now.month - 1);
    final beforeMonthKey =
        '${beforeDate.year}-${beforeDate.month.toString().padLeft(2, '0')}';
    final beforePrice = monthlyExpenses[beforeMonthKey] ?? 0.0;

    final savingsAmount = (beforePrice - afterPrice).clamp(0.0, double.infinity);
    final savingsPercent =
        beforePrice > 0 ? ((savingsAmount / beforePrice) * 100) : 0.0;

    return (
      beforePrice: beforePrice,
      afterPrice: afterPrice,
      savingsAmount: savingsAmount,
      savingsPercent: savingsPercent,
    );
  }

  /// 통계 화면에 표시할 메시지 생성 (성공 사례)
  static String getCookingSuccessMessage(int index) {
    if (index == 0) {
      return '다음 20일부터 챌린지를 시작해보세요!';
    } else if (index < 5) {
      return '좋은 시작입니다! 계속 정진하세요! 💪';
    } else if (index < 10) {
      return '훌륭합니다! 이미 $index끼니를 절약했어요! 🎉';
    } else {
      return '정말 멋집니다! 냉장고 정리의 달인이 되고 있어요! 🏆';
    }
  }

  /// 절약액 메시지
  static String getSavingsMessage(double savingsAmount) {
    if (savingsAmount == 0) {
      return '아직 절약액이 기록되지 않았습니다.';
    }
    return '지난달 대비 ₩${savingsAmount.toStringAsFixed(0)}원을 절약했습니다!';
  }
}
