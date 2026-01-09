// ignore_for_file: dead_code, dead_null_aware_expression
import '../models/food_expiry_item.dart';

/// 식재료 추천 강화 유틸리티
/// - 유통기한별 가격 최적화
/// - 영양 정보 추가
class IngredientsRecommendationUtils {
  /// 영양소 카테고리별 분류
  static const Map<String, List<String>> nutritionCategories = {
    '단백질': ['계란', '닭가슴살', '소고기', '돼지고기', '두부', '생선', '새우', '콩', '치즈', '우유'],
    '탄수화물': ['쌀', '밥', '면', '국수', '감자', '고구마', '옥수수', '콩', '곡물'],
    '채소': [
      '당근',
      '브로콜리',
      '시금치',
      '양배추',
      '피망',
      '토마토',
      '오이',
      '버섯',
      '양파',
      '마늘',
      '생강',
    ],
    '과일': ['사과', '딸기', '바나나', '포도', '오렌지', '귤', '수박', '키위', '레몬'],
    '유제품': ['우유', '요거트', '치즈', '버터'],
    '기름/양념': ['기름', '소금', '설탕', '간장', '고추장', '된장', '식초', '참기름'],
  };

  /// 가격 효율성이 높은 식재료 추천
  /// (유통기한이 임박할수록 높은 순위, 저가일수록 높은 순위)
  static List<FoodExpiryItem> getOptimizedRecommendations(
    List<FoodExpiryItem> items, {
    int limit = 10,
  }) {
    if (items.isEmpty) return [];

    // 유통기한 임박순 + 저가순 정렬
    final sorted = List<FoodExpiryItem>.from(items);
    sorted.sort((a, b) {
      final daysA = a.expiryDate.difference(DateTime.now()).inDays;
      final daysB = b.expiryDate.difference(DateTime.now()).inDays;

      // 유통기한 임박 우선 (음수인 것도 포함)
      if (daysA != daysB) {
        return daysA.compareTo(daysB);
      }

      // 같은 기한이면 저가 우선
      return (a.price ?? 0.0).compareTo(b.price ?? 0.0);
    });

    return sorted.take(limit).toList();
  }

  /// 식재료의 영양소 카테고리 반환
  static String getNutritionCategory(String ingredientName) {
    for (final entry in nutritionCategories.entries) {
      if (entry.value.any(
        (nutrient) =>
            ingredientName.toLowerCase().contains(nutrient.toLowerCase()),
      )) {
        return entry.key;
      }
    }
    return '기타';
  }

  /// 영양 정보 텍스트 생성
  static String getNutritionInfo(String ingredientName) {
    final category = getNutritionCategory(ingredientName);
    final categoryEmoji = {
      '단백질': '🥚',
      '탄수화물': '🌾',
      '채소': '🥬',
      '과일': '🍎',
      '유제품': '🥛',
      '기름/양념': '🧂',
      '기타': '❓',
    };
    return '${categoryEmoji[category] ?? '❓'} $category';
  }

  /// 가격 대비 유통기한 점수 계산 (0-100)
  /// 낮은 가격 + 긴 유통기한 = 높은 점수
  static int getPriceValueScore(FoodExpiryItem item) {
    final now = DateTime.now();
    final daysLeft = item.expiryDate.difference(now).inDays;

    // 가격이 없으면 기본값
    final price = item.price ?? 5000.0;

    // 유통기한 점수 (최대 50점)
    final daysScore = (daysLeft.clamp(0, 30) / 30 * 50).toInt();

    // 가격 점수 (최대 50점, 저가일수록 높음)
    // 기준: 10000원을 기준으로
    final priceScore = ((10000 - price.clamp(0, 10000)) / 10000 * 50).toInt();

    return daysScore + priceScore;
  }

  /// 추천 메시지 생성
  static String getRecommendationMessage(FoodExpiryItem item) {
    final daysLeft = item.expiryDate.difference(DateTime.now()).inDays;

    if (daysLeft < 0) {
      return '⚠️ 만료됨! 즉시 폐기 권장';
    } else if (daysLeft == 0) {
      return '🔴 오늘 만료! 지금 사용하세요';
    } else if (daysLeft == 1) {
      return '🟠 내일 만료. 내일 사용하세요';
    } else if (daysLeft <= 3) {
      return '🟡 $daysLeft일 후 만료. 이번주 사용';
    } else if (daysLeft <= 7) {
      return '🟢 $daysLeft일 여유있음. 천천히 사용해도 OK';
    } else {
      return '💚 충분한 여유. 우선순위 낮음';
    }
  }

  /// 금주 활용할 식재료 (7일 이내)
  static List<FoodExpiryItem> getThisWeekItems(List<FoodExpiryItem> items) {
    final now = DateTime.now();
    return items.where((item) {
      final daysLeft = item.expiryDate.difference(now).inDays;
      return daysLeft >= 0 && daysLeft <= 7;
    }).toList()..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  /// 카테고리별 영양 밸런스 분석
  static Map<String, int> getNutritionBalance(List<FoodExpiryItem> items) {
    final balance = <String, int>{};

    for (final item in items) {
      final category = getNutritionCategory(item.name);
      balance[category] = (balance[category] ?? 0) + 1;
    }

    return balance;
  }

  /// 영양 밸런스 평가
  static String getNutritionAdvice(List<FoodExpiryItem> items) {
    if (items.isEmpty) return '식재료를 추가하세요.';

    final balance = getNutritionBalance(items);

    // 단백질 부족 확인
    if ((balance['단백질'] ?? 0) == 0) {
      return '⚠️ 단백질 식재료가 부족합니다. 계란, 육류 등을 추가하세요.';
    }

    // 채소 부족 확인
    if ((balance['채소'] ?? 0) < 2) {
      return '⚠️ 채소가 부족합니다. 다양한 채소를 추가하세요.';
    }

    return '✅ 영양 밸런스가 좋습니다!';
  }
}
