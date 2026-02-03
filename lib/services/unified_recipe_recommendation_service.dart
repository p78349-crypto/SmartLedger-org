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
    int? minMatchPercentage = 50,
  }) async {
    final inventory = items ?? ConsumableInventoryService.instance.items.value;
    
    final recommendations =
        await RecipeRecommendationUtils.getRecommendedRecipes(
      inventory,
      minMatchPercentage: minMatchPercentage ?? 50,
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
  /// 반환값: {recipe: Recipe, missingCount: int, missing: List<String>}
  /// - recipe: Recipe 객체
  /// - missingCount: 부족한 재료 개수
  /// - missing: 부족한 재료명 목록
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
    final recipes = await RecipeService.instance.load();
    for (final entry in recommendations.entries) {
      final recipe = recipes.firstWhere(
        (r) => r.name == entry.key,
        orElse: () => Recipe.empty(),
      );
      if (recipe.id.isEmpty) continue;

      if (entry.value.matchPercentage >= 100) {
        return {
          'recipe': recipe,
          'missingCount': 0,
          'missing': <String>[],
        };
      }
    }

    // 100% 일치 없으면 최고 일치도 반환
    final topEntry = recommendations.entries.first;
    final recipe = recipes.firstWhere(
      (r) => r.name == topEntry.key,
      orElse: () => Recipe.empty(),
    );
    
    if (recipe.id.isEmpty) {
      return null;
    }

    final missingIngredients = topEntry.value.missingIngredients ?? [];
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
    for (final entry in recommendations.entries) {
      final recipe = entry.value;
      final matchingIngredients = recipe.availableIngredients
              ?.where((ing) => ingredients
                  .any((q) => ing.toLowerCase().contains(q.toLowerCase())))
              .toList() ??
          [];

      if (matchingIngredients.isNotEmpty) {
        filtered.add(recipe);
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
        .map((match) => allRecipes.firstWhere(
              (r) => r.name == match.recipeName,
              orElse: () => Recipe.empty(),
            ))
        .where((r) => r.id.isNotEmpty)
        .toList();
  }

  /// 추천 레시피 메시지 생성 (원래 RecipeRecommendationUtils에서)
  String generateRecommendationMessage(RecipeMatch recipe) {
    return RecipeRecommendationUtils.generateRecommendationMessage(recipe);
  }
}
