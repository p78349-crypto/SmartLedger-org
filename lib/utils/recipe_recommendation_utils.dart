import 'package:smart_ledger/models/food_expiry_item.dart';

/// 사용 가능한 식재료 기반 요리 추천
class RecipeRecommendationUtils {
  RecipeRecommendationUtils._();

  /// 기본 요리 목록 (사용자 패턴 학습 전 기본값)
  static const List<Map<String, dynamic>> defaultRecipes = [
    {
      'name': '계란프라이',
      'ingredients': ['계란', '버터', '소금'],
    },
    {
      'name': '계란탁',
      'ingredients': ['계란', '국간장', '파'],
    },
    {
      'name': '채소 볶음',
      'ingredients': ['채소', '당근', '마늘', '간장'],
    },
    {
      'name': '김치찌개',
      'ingredients': ['김치', '돼지고기', '두부', '고추'],
    },
    {
      'name': '스파게티',
      'ingredients': ['면', '토마토', '양파', '마늘'],
    },
    {
      'name': '된장국',
      'ingredients': ['된장', '물', '두부', '파'],
    },
    {
      'name': '계란말이',
      'ingredients': ['계란', '소금', '기름', '파'],
    },
    {
      'name': '볶음밥',
      'ingredients': ['쌀', '계란', '야채', '간장'],
    },
  ];

  /// 주어진 식재료로 만들 수 있는 요리 추천
  /// Returns: (추천 요리명, 필요한 재료 수, 충분한 재료 수)
  static Map<String, RecipeMatch> getRecommendedRecipes(
    List<FoodExpiryItem> availableIngredients,
  ) {
    final availableNames = availableIngredients
        .map((item) => item.name.toLowerCase().trim())
        .toSet();

    final recommendations = <String, RecipeMatch>{};

    // 기본 요리 목록에서 추천
    for (final recipeData in defaultRecipes) {
      final recipeName = recipeData['name'] as String;
      final requiredIngredients = (recipeData['ingredients'] as List).cast<String>();

      if (requiredIngredients.isEmpty) continue;

      // 요리에 필요한 식재료 중 보유한 것의 개수
      int matchCount = 0;
      for (final required in requiredIngredients) {
        final normalized = required.toLowerCase().trim();
        if (availableNames.any((available) => available.contains(normalized) ||
            normalized.contains(available))) {
          matchCount++;
        }
      }

      // 최소 50% 이상의 재료가 있으면 추천
      final matchPercentage = (matchCount / requiredIngredients.length * 100).toInt();
      if (matchPercentage >= 50) {
        recommendations[recipeName] = RecipeMatch(
          recipeName: recipeName,
          requiredCount: requiredIngredients.length,
          availableCount: matchCount,
          matchPercentage: matchPercentage,
        );
      }
    }

    // 매칭 비율 순으로 정렬
    final sortedEntries = recommendations.entries.toList()
      ..sort((a, b) => b.value.matchPercentage.compareTo(a.value.matchPercentage));

    return Map.fromEntries(sortedEntries);
  }

  /// 상위 N개 추천 요리 반환
  static List<RecipeMatch> getTopRecommendations(
    List<FoodExpiryItem> availableIngredients, {
    int limit = 3,
  }) {
    final recommendations = getRecommendedRecipes(availableIngredients);
    return recommendations.values.take(limit).toList();
  }

  /// 추천 메시지 생성
  static String generateRecommendationMessage(
    List<FoodExpiryItem> expiringItems,
    RecipeMatch recipe,
  ) {
    final ingredientList = expiringItems
        .take(3)
        .map((item) => item.name)
        .join(', ');

    return '$ingredientList 같은 식재료를\n활용해서 ${recipe.recipeName}을(를)\n만들어보세요! 🍳';
  }
}

/// 요리 매칭 결과
class RecipeMatch {
  final String recipeName;
  final int requiredCount; // 필요한 총 재료 수
  final int availableCount; // 보유 중인 재료 수
  final int matchPercentage; // 매칭 비율 (0-100)

  RecipeMatch({
    required this.recipeName,
    required this.requiredCount,
    required this.availableCount,
    required this.matchPercentage,
  });

  /// 사용자 친화적 메시지
  String get message {
    if (matchPercentage == 100) {
      return '모든 재료가 준비됐습니다!';
    } else if (matchPercentage >= 80) {
      return '거의 모든 재료가 있습니다!';
    } else if (matchPercentage >= 60) {
      return '대부분의 재료가 있습니다.';
    } else {
      return '일부 재료가 필요합니다.';
    }
  }
}
