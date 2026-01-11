import '../models/food_expiry_item.dart';
import '../services/recipe_service.dart';

/// 사용 가능한 식재료 기반 요리 추천
class RecipeRecommendationUtils {
  RecipeRecommendationUtils._();

  /// 기본 요리 목록 (사용자 패턴 학습 전 기본값)
  /// healthScore: 1(저) ~ 5(매우 건강) - 영양 균형, 칼로리, 조리법 기준
  static const List<Map<String, dynamic>> defaultRecipes = [
    {
      'name': '계란프라이',
      'ingredients': ['계란', '버터', '소금'],
      'healthScore': 3, // 단백질 풍부하지만 버터 사용
    },
    {
      'name': '계란탁',
      'ingredients': ['계란', '국간장', '파'],
      'healthScore': 4, // 저칼로리, 단백질 풍부
    },
    {
      'name': '채소 볶음',
      'ingredients': ['채소', '당근', '마늘', '간장'],
      'healthScore': 5, // 비타민, 섬유질 풍부, 저칼로리
    },
    {
      'name': '김치찌개',
      'ingredients': ['김치', '돼지고기', '두부', '고추'],
      'healthScore': 4, // 발효식품(김치), 단백질, 비타민
    },
    {
      'name': '스파게티',
      'ingredients': ['면', '토마토', '양파', '마늘'],
      'healthScore': 3, // 탄수화물 많음, 토마토는 건강
    },
    {
      'name': '된장국',
      'ingredients': ['된장', '물', '두부', '파'],
      'healthScore': 5, // 발효식품, 단백질, 저칼로리
    },
    {
      'name': '계란말이',
      'ingredients': ['계란', '소금', '기름', '파'],
      'healthScore': 4, // 단백질 풍부, 채소 포함
    },
    {
      'name': '볶음밥',
      'ingredients': ['쌀', '계란', '야채', '간장'],
      'healthScore': 3, // 탄수화물 많음, 야채 포함
    },
    {
      'name': '두부조림',
      'ingredients': ['두부', '간장', '마늘', '파'],
      'healthScore': 5, // 식물성 단백질, 저칼로리
    },
    {
      'name': '시금치나물',
      'ingredients': ['시금치', '마늘', '참기름', '소금'],
      'healthScore': 5, // 철분, 비타민 풍부
    },
    {
      'name': '닭가슴살 샐러드',
      'ingredients': ['닭고기', '채소', '토마토', '올리브유'],
      'healthScore': 5, // 저지방 단백질, 비타민
    },
    {
      'name': '미역국',
      'ingredients': ['미역', '소고기', '마늘', '참기름'],
      'healthScore': 5, // 미네랄, 단백질, 저칼로리
    },
  ];

  /// 주어진 식재료로 만들 수 있는 요리 추천
  /// 유통기한 3일 이내 재료를 포함한 레시피를 최우선 추천
  /// prioritizeHealth=true면 건강한 요리를 우선 추천
  /// includeUserRecipes=true면 사용자가 만든 레시피도 포함
  /// Returns: (추천 요리명, 필요한 재료 수, 충분한 재료 수)
  static Future<Map<String, RecipeMatch>> getRecommendedRecipes(
    List<FoodExpiryItem> availableIngredients, {
    bool prioritizeExpiring = true,
    bool prioritizeHealth = true,
    bool includeUserRecipes = true,
  }) async {
    final now = DateTime.now();

    // 유통기한 임박 재료 식별 (3일 이내)
    final expiringItems = availableIngredients
        .where((item) => item.daysLeft(now) <= 3)
        .toSet();

    final availableMap = <String, FoodExpiryItem>{};
    for (final item in availableIngredients) {
      availableMap[item.name.toLowerCase().trim()] = item;
    }

    final recommendations = <String, RecipeMatch>{};

    // 1. 기본 요리 목록에서 추천
    for (final recipeData in defaultRecipes) {
      final recipeName = recipeData['name'] as String;
      final requiredIngredients = (recipeData['ingredients'] as List)
          .cast<String>();
      final healthScore = (recipeData['healthScore'] as int?) ?? 3;

      if (requiredIngredients.isEmpty) continue;

      final matchResult = _matchIngredients(
        requiredIngredients,
        availableMap,
        expiringItems,
      );

      // 최소 50% 이상의 재료가 있으면 추천
      final matchPercentage =
          (matchResult.matchCount / requiredIngredients.length * 100).toInt();
      if (matchPercentage >= 50) {
        recommendations[recipeName] = RecipeMatch(
          recipeName: recipeName,
          requiredCount: requiredIngredients.length,
          availableCount: matchResult.matchCount,
          matchPercentage: matchPercentage,
          expiringIngredientCount: matchResult.expiringMatchCount,
          healthScore: healthScore,
        );
      }
    }

    // 2. 사용자가 만든 레시피 추가
    if (includeUserRecipes) {
      final userRecipes = RecipeService.instance.recipes.value;

      for (final recipe in userRecipes) {
        final requiredIngredients = recipe.ingredients
            .map((i) => i.name)
            .toList();

        if (requiredIngredients.isEmpty) continue;

        final matchResult = _matchIngredients(
          requiredIngredients,
          availableMap,
          expiringItems,
        );

        final matchPercentage =
            (matchResult.matchCount / requiredIngredients.length * 100).toInt();
        if (matchPercentage >= 50) {
          recommendations[recipe.name] = RecipeMatch(
            recipeName: recipe.name,
            requiredCount: requiredIngredients.length,
            availableCount: matchResult.matchCount,
            matchPercentage: matchPercentage,
            expiringIngredientCount: matchResult.expiringMatchCount,
            healthScore: recipe.healthScore,
            isUserRecipe: true, // 사용자 레시피 표시
          );
        }
      }
    }

    // 정렬: 유통기한 임박 재료 사용 개수 → 건강 점수 → 매칭 비율 순
    final sortedEntries = recommendations.entries.toList(growable: false)
      ..sort((a, b) {
        if (prioritizeExpiring) {
          final expiringCompare = b.value.expiringIngredientCount.compareTo(
            a.value.expiringIngredientCount,
          );
          if (expiringCompare != 0) return expiringCompare;
        }

        if (prioritizeHealth) {
          final healthCompare = b.value.healthScore.compareTo(
            a.value.healthScore,
          );
          if (healthCompare != 0) return healthCompare;
        }

        return b.value.matchPercentage.compareTo(a.value.matchPercentage);
      });

    return Map<String, RecipeMatch>.fromEntries(sortedEntries);
  }

  /// 상위 N개 추천 요리 반환
  /// includeUserRecipes=true면 사용자가 만든 레시피도 포함
  static Future<List<RecipeMatch>> getTopRecommendations(
    List<FoodExpiryItem> availableIngredients, {
    int limit = 3,
    bool prioritizeExpiring = true,
    bool prioritizeHealth = true,
    bool includeUserRecipes = true,
  }) async {
    final recommendations = await getRecommendedRecipes(
      availableIngredients,
      prioritizeExpiring: prioritizeExpiring,
      prioritizeHealth: prioritizeHealth,
      includeUserRecipes: includeUserRecipes,
    );

    return recommendations.values.take(limit).toList(growable: false);
  }

  static _MatchResult _matchIngredients(
    List<String> requiredIngredients,
    Map<String, FoodExpiryItem> availableMap,
    Set<FoodExpiryItem> expiringItems,
  ) {
    int matchCount = 0;
    int expiringMatchCount = 0;

    for (final required in requiredIngredients) {
      final normalized = required.toLowerCase().trim();

      for (final entry in availableMap.entries) {
        final available = entry.key;
        final item = entry.value;

        if (available.contains(normalized) || normalized.contains(available)) {
          matchCount++;
          if (expiringItems.contains(item)) {
            expiringMatchCount++;
          }
          break;
        }
      }
    }

    return _MatchResult(
      matchCount: matchCount,
      expiringMatchCount: expiringMatchCount,
    );
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

/// 재료 매칭 결과
class _MatchResult {
  final int matchCount;
  final int expiringMatchCount;

  _MatchResult({required this.matchCount, required this.expiringMatchCount});
}

/// 요리 매칭 결과
class RecipeMatch {
  final String recipeName;
  final int requiredCount; // 필요한 총 재료 수
  final int availableCount; // 보유 중인 재료 수
  final int matchPercentage; // 매칭 비율 (0-100)
  final int expiringIngredientCount; // 유통기한 임박 재료 개수 (3일 이내)
  final int healthScore; // 건강 점수 (1-5, 높을수록 건강)
  final bool isUserRecipe; // 사용자가 만든 레시피 여부

  RecipeMatch({
    required this.recipeName,
    required this.requiredCount,
    required this.availableCount,
    required this.matchPercentage,
    this.expiringIngredientCount = 0,
    this.healthScore = 3,
    this.isUserRecipe = false,
  });

  /// 유통기한 임박 재료 사용 여부
  bool get usesExpiringIngredients => expiringIngredientCount > 0;

  /// 건강한 요리 여부 (점수 4 이상)
  bool get isHealthy => healthScore >= 4;

  /// 매우 건강한 요리 여부 (점수 5)
  bool get isVeryHealthy => healthScore == 5;

  /// 건강 점수 텍스트
  String get healthLabel {
    switch (healthScore) {
      case 5:
        return '💚 매우 건강';
      case 4:
        return '💚 건강';
      case 3:
        return '🟡 보통';
      case 2:
        return '🟠 주의';
      case 1:
        return '🔴 비건강';
      default:
        return '🟡 보통';
    }
  }

  /// 사용자 친화적 메시지
  String get message {
    final parts = <String>[];

    if (isUserRecipe) {
      parts.add('👤 내 레시피');
    }

    if (usesExpiringIngredients) {
      parts.add('⚠️ 유통기한 임박 재료 활용');
    }

    if (isVeryHealthy) {
      parts.add('💚 매우 건강한 요리');
    } else if (isHealthy) {
      parts.add('💚 건강한 요리');
    }

    if (matchPercentage == 100) {
      parts.add('모든 재료 준비됨');
    } else if (matchPercentage >= 80) {
      parts.add('거의 모든 재료 있음');
    } else if (matchPercentage >= 60) {
      parts.add('대부분 재료 있음');
    } else {
      parts.add('일부 재료 필요');
    }

    return parts.join(' • ');
  }
}
