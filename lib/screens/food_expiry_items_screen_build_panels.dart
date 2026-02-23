// ignore_for_file: invalid_use_of_protected_member

part of 'food_expiry_items_screen.dart';

/// Build helpers for ingredient comparison and missing-ingredients panels.
extension FoodExpiryBuildPanelsExt on _FoodExpiryItemsScreenState {
  Widget buildIngredientComparisonPanel(
    ThemeData theme,
    List<FoodExpiryItem> items,
    List<String> ingredientNames,
    List<String> missingIngredients,
  ) {
    return Container(
      width: double.maxFinite,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.25,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fact_check_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '재료 비교 (${ingredientNames.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addIngredientNamesToCart(ingredientNames),
                icon: const Icon(Icons.playlist_add, size: 16),
                label: const Text('모두 담기'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              if (missingIngredients.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _addMissingToCart(missingIngredients),
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 16,
                  ),
                  label: const Text('재고 0 모두 담기'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...ingredientNames.expand((ing) {
            final matchedAll = _matchAllItemsForIngredient(ing, items);
            final matched = _matchAvailableItemsForIngredient(ing, items);
            final isMissing = matched.isEmpty;
            final nearest = isMissing ? null : matched.first;
            final left = nearest?.daysLeft(DateTime.now());
            final leftText = left == null
                ? ''
                : (left < 0 ? '지남 ${-left}일' : '$left일 남음');
            final nearestExpiry = left == null
                ? null
                : DateFormat('yyyy-MM-dd').format(nearest!.expiryDate);

            final subtitle = isMissing
                ? (matchedAll.isEmpty
                      ? '재고: 0 (없음)'
                      : '재고: 0 (수량 0)')
                : '총 ${_formatMatchedTotal(matched)} / '
                      '가장 빠른 기한: $nearestExpiry ($leftText)';

            final warnColor = (left != null && left <= 2)
                ? theme.colorScheme.error
                : null;

            return [
              InkWell(
                onTap: matchedAll.isEmpty
                    ? null
                    : () => _showIngredientMatchesDetail(
                        context,
                        ingredientName: ing,
                        matched: matchedAll,
                      ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ing,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: warnColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isMissing)
                        IconButton(
                          tooltip: '장바구니 담기',
                          onPressed: () => _addMissingToCart([ing]),
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 18,
                          ),
                        )
                      else
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: theme.colorScheme.outline,
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
            ];
          }).toList()
            ..removeLast(),
        ],
      ),
    );
  }

  Widget buildMissingIngredientsPanel(
    ThemeData theme,
    List<String> missingIngredients,
  ) {
    return Container(
      width: double.maxFinite,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '부족한 식료품/생활용품 (${missingIngredients.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _addMissingToCart(missingIngredients),
                icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                label: const Text('장바구니 담기'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('식료품/생활용품 목록'),
          Wrap(
            spacing: 8,
            children: missingIngredients
                .map(
                  (ing) => Chip(
                    label: Text(ing),
                    visualDensity: VisualDensity.compact,
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
