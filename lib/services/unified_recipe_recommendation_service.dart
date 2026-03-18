import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/models/recipe.dart';
import 'package:smart_ledger/services/recipe_service.dart';
import 'package:smart_ledger/services/consumable_inventory_service.dart';
import 'package:smart_ledger/utils/recipe_recommendation_utils.dart';
import 'package:smart_ledger/utils/daily_recipe_recommendation_utils.dart';

/// 통합 레시피 추천 서비스
///
/// 앱 전체의 레시피 추천을 담당하는 중앙 서비스입니다.
/// - 현재 재고 기반 추천
/// - 일일 추천 레시피
/// - 음성 명령 추천
class UnifiedRecipeRecommendationService {
  UnifiedRecipeRecommendationService._internal();
  static final UnifiedRecipeRecommendationService instance =
      UnifiedRecipeRecommendationService._internal();

  /// 현재 재고로 만들 수 있는 모든 레시피 추천
  ///
  /// 반환값: {레시피명: RecipeMatch}
  /// 정렬: 일치도 높은 순서대로
  Future<Map<String, RecipeMatch>> getRecommendedRecipes({
    List<ConsumableInventoryItem>? items,
    int minMatchPercentage = 50,
  }) async {
    final inventory = items ?? ConsumableInventoryService.instance.items.value;

    final recommendations =
        await RecipeRecommendationUtils.getRecommendedRecipes(
          inventory,
          minMatchPercentage: minMatchPercentage,
        );

    return recommendations;
  }

  /// 상위 N개 추천 레시피 (일치도 순)
  ///
  /// [count]: 반환할 레시피 개수 (기본 5개)
  /// [minMatchPercentage]: 최소 일치도 (기본 50%)
  Future<List<RecipeMatch>> getTopRecommendations({
    List<ConsumableInventoryItem>? items,
    int count = 5,
    int minMatchPercentage = 50,
  }) async {
    final inventory = items ?? ConsumableInventoryService.instance.items.value;

    final recommendations =
        await RecipeRecommendationUtils.getTopRecommendations(
          inventory,
          minMatchPercentage: minMatchPercentage,
        );

    return recommendations.take(count).toList();
  }

  /// 일일 추천 레시피
  ///
  /// 유통기한이 임박한 재료로 만들 수 있는 최고의 레시피 1개
  Future<DailyRecipeRecommendationResult> getDailyRecommendation({
    List<ConsumableInventoryItem>? items,
  }) async {
    final inventory = items ?? ConsumableInventoryService.instance.items.value;

    return DailyRecipeRecommendationUtils.build(inventory);
  }

  /// 음성 명령용 추천 레시피 (간단 버전)
  ///
  /// 완벽 일치 레시피 또는 최고 일치도 레시피 1개 반환
  ///
  /// 반환값: {recipe: Recipe, missingCount: int, missing: String 목록}
  /// - recipe: Recipe 객체
  /// - missingCount: 부족한 재료 개수
  /// - missing: 부족한 재료명 목록 (문자열 리스트)
  Future<Map<String, dynamic>?> getRecommendationForVoiceCommand({
    List<ConsumableInventoryItem>? items,
  }) async {
    final inventory = items ?? ConsumableInventoryService.instance.items.value;

    // 현재 재고로 만들 수 있는 모든 레시피
    final recommendations = await getRecommendedRecipes(
      items: inventory,
      minMatchPercentage: 30, // 음성 명령은 더 낮은 기준 허용
    );

    if (recommendations.isEmpty) {
      return null;
    }

    // 100% 일치 레시피 찾기
    await RecipeService.instance.load();
    final recipes = RecipeService.instance.recipes.value;
    for (final entry in recommendations.entries) {
      final recipe = _findRecipeByName(recipes, entry.key);
      if (recipe == null) continue;

      if (entry.value.matchPercentage >= 100) {
        return {'recipe': recipe, 'missingCount': 0, 'missing': <String>[]};
      }
    }

    // 100% 일치 없으면 최고 일치도 반환
    final topEntry = recommendations.entries.first;
    final recipe = _findRecipeByName(recipes, topEntry.key);
    if (recipe == null) {
      return null;
    }

    final missingIngredients = _computeMissingIngredients(recipe, inventory);
    return {
      'recipe': recipe,
      'missingCount': missingIngredients.length,
      'missing': missingIngredients,
    };
  }

  /// 특정 식재료로 만들 수 있는 레시피 찾기
  ///
  /// [ingredients]: 검색할 식재료명 목록
  Future<List<RecipeMatch>> findRecipesByIngredients(
    List<String> ingredients,
  ) async {
    final recommendations =
        await RecipeRecommendationUtils.getRecommendedRecipes(
          ConsumableInventoryService.instance.items.value,
          minMatchPercentage: 0,
        );

    // 지정된 식재료와 일치하는 레시피만 필터링
    final filtered = <RecipeMatch>[];
    await RecipeService.instance.load();
    final allRecipes = RecipeService.instance.recipes.value;
    for (final entry in recommendations.entries) {
      final recipe = _findRecipeByName(allRecipes, entry.key);
      if (recipe == null) continue;

      final matchingIngredients = recipe.ingredients
          .map((i) => i.name)
          .where(
            (ing) => ingredients.any(
              (q) => ing.toLowerCase().contains(q.toLowerCase()),
            ),
          )
          .toList();

      if (matchingIngredients.isNotEmpty) {
        filtered.add(entry.value);
      }
    }

    return filtered;
  }

  /// 추천 레시피를 Recipe 객체 목록으로 변환
  ///
  /// [recommendations]: RecipeMatch 목록
  Future<List<Recipe>> convertToRecipes(
    List<RecipeMatch> recommendations,
  ) async {
    await RecipeService.instance.load();
    final allRecipes = RecipeService.instance.recipes.value;

    return recommendations
        .map((match) => _findRecipeByName(allRecipes, match.recipeName))
        .where((r) => r != null)
        .cast<Recipe>()
        .toList();
  }

  /// 추천 레시피 메시지 생성 (원래 RecipeRecommendationUtils에서)
  String generateRecommendationMessage(
    RecipeMatch recipe, {
    List<ConsumableInventoryItem>? expiringItems,
  }) {
    final items = expiringItems ?? <ConsumableInventoryItem>[];
    return RecipeRecommendationUtils.generateRecommendationMessage(
      items,
      recipe,
    );
  }

  Recipe? _findRecipeByName(List<Recipe> recipes, String name) {
    for (final recipe in recipes) {
      if (recipe.name == name) return recipe;
    }
    return null;
  }

  List<String> _computeMissingIngredients(
    Recipe recipe,
    List<ConsumableInventoryItem> inventory,
  ) {
    final inventoryNames = inventory
        .map((i) => i.name.toLowerCase().trim())
        .where((n) => n.isNotEmpty)
        .toList();

    final missing = <String>[];
    for (final ingredient in recipe.ingredients) {
      final name = ingredient.name.trim();
      if (name.isEmpty) continue;
      final normalized = name.toLowerCase();
      final hasMatch = inventoryNames.any(
        (inv) => inv.contains(normalized) || normalized.contains(inv),
      );
      if (!hasMatch) missing.add(name);
    }
    return missing;
  }
}
