// ignore_for_file: dead_code, dead_null_aware_expression,
//   invalid_null_aware_operator, unchecked_use_of_nullable_value
import 'package:flutter/material.dart';
import '../models/food_expiry_item.dart';
import '../services/food_expiry_service.dart';
import '../services/recipe_knowledge_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/ingredients_recommendation_utils.dart';
import '../mixins/food_expiry_items_auto_refresh_mixin.dart';

/// 식재료 추천 강화 위젯
class IngredientsRecommendationWidget extends StatefulWidget {
  const IngredientsRecommendationWidget({super.key});

  @override
  State<IngredientsRecommendationWidget> createState() =>
      _IngredientsRecommendationWidgetState();
}

class _IngredientsRecommendationWidgetState
    extends State<IngredientsRecommendationWidget>
    with FoodExpiryItemsAutoRefreshMixin {
  List<FoodExpiryItem>? _recommendations;
  String? _nutritionAdvice;
  List<MissingMainIngredientSuggestion>? _missingMain;
  bool _isLoading = true;

  @override
  Future<void> onFoodExpiryItemsChanged() => _loadRecommendations();

  @override
  void initState() {
    super.initState();
    requestFoodExpiryItemsRefresh();
  }

  Future<void> _loadRecommendations() async {
    try {
      final items = FoodExpiryService.instance.items.value;
      await RecipeKnowledgeService.instance.loadData();
      final thisWeek = IngredientsRecommendationUtils.getThisWeekItems(items);
      final optimized =
          IngredientsRecommendationUtils.getOptimizedRecommendations(
            thisWeek,
            limit: 5,
          );

      final advice = IngredientsRecommendationUtils.getNutritionAdvice(items);
      final missingMain = RecipeKnowledgeService.instance
          .suggestMissingMainIngredients(items);

      if (!mounted) return;
      setState(() {
        _recommendations = optimized;
        _nutritionAdvice = advice;
        _missingMain = missingMain;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator.adaptive(),
      );
    }

    if (_recommendations == null || _recommendations!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  IconCatalog.ingredients,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '🍽️ 이번주 추천 식재료',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recommendations!.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _recommendations![index];
              final nutrition = IngredientsRecommendationUtils.getNutritionInfo(
                item.name,
              );
              final message =
                  IngredientsRecommendationUtils.getRecommendationMessage(item);
              final priceScore =
                  IngredientsRecommendationUtils.getPriceValueScore(item);

              return Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    nutrition,
                                    style: theme.textTheme.labelSmall,
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getScoreColor(priceScore),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '점수: $priceScore',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.price.toStringAsFixed(0)}원',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(message, style: theme.textTheme.labelMedium),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '보유량: ${item.quantity} ${item.unit}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(height: 1),
          if (_nutritionAdvice != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _nutritionAdvice!,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_missingMain != null && _missingMain!.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.add_shopping_cart,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '주재료가 없을 때 추천',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _missingMain!.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final s = _missingMain![index];
                final hint = s.matchedPairings.isEmpty
                    ? '집에 있는 재료와 잘 어울려요.'
                    : '집에 있는 재료: ${s.matchedPairings.take(2).join(', ')}';

                return ListTile(
                  title: Text(
                    s.primaryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}
