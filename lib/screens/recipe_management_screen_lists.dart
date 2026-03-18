import 'package:flutter/material.dart';
import '../models/recipe.dart';
import 'recipe_management_screen_card.dart';

/// Build list view for my recipes (user-created)
Widget buildMyRecipesList({
  required List<Recipe> recipes,
  required String searchQuery,
  required VoidCallback onRefresh,
  required VoidCallback onAddNew,
  required void Function(Recipe) onEdit,
  required void Function(Recipe) onDelete,
  required void Function(Recipe) onCopyToMy,
  required void Function(Recipe) onSendToCart,
}) {
  if (recipes.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? '아직 작성한 레시피가 없습니다' : '검색 결과가 없습니다',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  return RefreshIndicator(
    onRefresh: () async => onRefresh(),
    child: ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final r = recipes[index];
        return RecipeCard(
          recipe: r,
          isMyRecipe: true,
          onTap: () => onEdit(r),
          onDelete: () => onDelete(r),
          onCopyToMy: () => onCopyToMy(r),
          onSendToCart: () => onSendToCart(r),
        );
      },
    ),
  );
}

/// Build list view for recommended recipes
Widget buildRecommendedRecipesList({
  required List<Recipe> recipes,
  required String searchQuery,
  required VoidCallback onRefresh,
  required void Function(Recipe) onEdit,
  required void Function(Recipe) onDelete,
  required void Function(Recipe) onCopyToMy,
  required void Function(Recipe) onSendToCart,
}) {
  if (recipes.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? '추천 레시피가 없습니다' : '검색 결과가 없습니다',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  return RefreshIndicator(
    onRefresh: () async => onRefresh(),
    child: ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final r = recipes[index];
        return RecipeCard(
          recipe: r,
          isMyRecipe: false,
          onTap: () => onEdit(r),
          onDelete: () => onDelete(r),
          onCopyToMy: () => onCopyToMy(r),
          onSendToCart: () => onSendToCart(r),
        );
      },
    ),
  );
}
