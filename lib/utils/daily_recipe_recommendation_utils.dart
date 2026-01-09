import '../models/food_expiry_item.dart';
import 'expiring_ingredients_utils.dart';
import 'recipe_recommendation_utils.dart';

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

  static DailyRecipeRecommendationResult build(
    List<FoodExpiryItem> allItems, {
    int expiringWindowDays = defaultExpiringWindowDays,
    int recipeLimit = defaultRecipeLimit,
    DateTime? now,
  }) {
    final expiring = ExpiringIngredientsUtils.getExpiringWithinDays(
      allItems,
      days: expiringWindowDays,
      now: now,
    );

    if (expiring.isEmpty) {
      return const DailyRecipeRecommendationResult(
        expiringItems: <FoodExpiryItem>[],
        recommendedRecipe: null,
      );
    }

    final topRecipes = RecipeRecommendationUtils.getTopRecommendations(
      expiring,
      limit: recipeLimit,
    );

    return DailyRecipeRecommendationResult(
      expiringItems: expiring,
      recommendedRecipe: topRecipes.isNotEmpty ? topRecipes.first : null,
    );
  }
}
