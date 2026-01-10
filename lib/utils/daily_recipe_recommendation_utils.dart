import '../models/food_expiry_item.dart';
import 'expiring_ingredients_utils.dart';
import 'recipe_recommendation_utils.dart';
import 'cache_utils.dart';

class DailyRecipeRecommendationResult {
  final List<FoodExpiryItem> expiringItems;
  final RecipeMatch? recommendedRecipe;

  const DailyRecipeRecommendationResult({
    required this.expiringItems,
    required this.recommendedRecipe,
  });

  bool get hasRecommendation =>
      expiringItems.isNotEmpty && recommendedRecipe != null;
}

class DailyRecipeRecommendationUtils {
  DailyRecipeRecommendationUtils._();

  static const int defaultExpiringWindowDays = 3;
  static const int defaultRecipeLimit = 1;
  static const Duration cacheMaxAge = Duration(minutes: 5);

  static final _cache = SimpleCache<String, DailyRecipeRecommendationResult>(
    maxAge: cacheMaxAge,
  );

  /// 캐시 키 생성 (재료 이름과 만료일 기반)
  static String _generateCacheKey(
    List<FoodExpiryItem> items,
    int expiringWindowDays,
  ) {
    if (items.isEmpty) return 'empty';
    
    // 임박 재료만 추출 (캐시 키 최소화)
    final expiring = ExpiringIngredientsUtils.getExpiringWithinDays(
      items,
      days: expiringWindowDays,
    );
    
    if (expiring.isEmpty) return 'no_expiring';
    
    // 재료명과 만료일 조합으로 키 생성
    final keyParts = expiring.map((item) {
      final days = ExpiringIngredientsUtils.daysUntilExpiry(item);
      return '${item.name}:$days';
    }).toList()
      ..sort(); // 순서 무관하게 동일한 키 생성
    
    return keyParts.join('|');
  }

  /// 캐시 무효화
  static void clearCache() {
    _cache.clear();
  }

  static Future<DailyRecipeRecommendationResult> build(
    List<FoodExpiryItem> allItems, {
    int expiringWindowDays = defaultExpiringWindowDays,
    int recipeLimit = defaultRecipeLimit,
    DateTime? now,
    bool includeUserRecipes = true, // 사용자 레시피 포함
    bool useCache = true, // 캐시 사용 여부
  }) async {
    // 조기 종료: 빈 목록
    if (allItems.isEmpty) {
      return const DailyRecipeRecommendationResult(
        expiringItems: <FoodExpiryItem>[],
        recommendedRecipe: null,
      );
    }

    // 캐시 키 생성
    final cacheKey = _generateCacheKey(allItems, expiringWindowDays);
    
    // 조기 종료: 임박 재료 없음
    if (cacheKey == 'no_expiring' || cacheKey == 'empty') {
      return const DailyRecipeRecommendationResult(
        expiringItems: <FoodExpiryItem>[],
        recommendedRecipe: null,
      );
    }

    // 캐시 확인
    if (useCache) {
      final cached = _cache.get(cacheKey);
      if (cached != null) {
        return cached;
      }
    }

    // 캐시 미스: 새로 계산
    final expiring = ExpiringIngredientsUtils.getExpiringWithinDays(
      allItems,
      days: expiringWindowDays,
      now: now,
    );

    final topRecipes = await RecipeRecommendationUtils.getTopRecommendations(
      expiring,
      limit: recipeLimit,
      includeUserRecipes: includeUserRecipes,
    );

    final result = DailyRecipeRecommendationResult(
      expiringItems: expiring,
      recommendedRecipe: topRecipes.isNotEmpty ? topRecipes.first : null,
    );

    // 캐시 저장
    if (useCache) {
      _cache.set(cacheKey, result);
    }

    return result;
  }
}
