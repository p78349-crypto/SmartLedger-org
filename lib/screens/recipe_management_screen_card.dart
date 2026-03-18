import 'package:flutter/material.dart';
import '../models/recipe.dart';

/// 레시피 카드 위젯
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipe,
    required this.isMyRecipe,
    required this.onTap,
    required this.onDelete,
    required this.onCopyToMy,
    required this.onSendToCart,
  });

  final Recipe recipe;
  final bool isMyRecipe;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onCopyToMy;
  final VoidCallback onSendToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ingredientCount = recipe.ingredients.length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme, ingredientCount),
              const SizedBox(height: 12),
              _buildIngredientPreview(),
              const Divider(height: 24),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    int ingredientCount,
  ) {
    final lang = Localizations.localeOf(context).languageCode;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                recipe.nameForLocale(lang),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _tag(recipe.cuisine),
                  const SizedBox(width: 8),
                  _tag('재료 $ingredientCount개'),
                  const SizedBox(width: 8),
                  _healthScore(recipe.healthScore),
                ],
              ),
            ],
          ),
        ),
        if (isMyRecipe)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            tooltip: '삭제',
          ),
      ],
    );
  }

  Widget _buildIngredientPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: recipe.ingredients
              .take(5)
              .map(
                (ing) => Chip(
                  label: Text(ing.name, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              )
              .toList(),
        ),
        if (recipe.ingredients.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${recipe.ingredients.length - 5}개 더',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }

  Widget _buildActions() {
    // Make the two action buttons share horizontal space and align neatly.
    return Row(
      children: [
        if (!isMyRecipe) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onCopyToMy,
              icon: const Icon(Icons.content_copy, size: 18),
              label: const Text('내 레시피로 복사'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: FilledButton.icon(
            onPressed: onSendToCart,
            icon: const Icon(Icons.shopping_cart, size: 18),
            label: const Text('장바구니에 추가'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
      ),
    );
  }

  static Widget _healthScore(int score) {
    final color = score >= 4
        ? Colors.green
        : score >= 3
        ? Colors.orange
        : Colors.red;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.favorite, size: 14, color: color),
        const SizedBox(width: 2),
        Text('$score', style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
