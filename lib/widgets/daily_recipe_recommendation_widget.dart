import 'package:flutter/material.dart';
import '../models/food_expiry_item.dart';
import '../services/food_expiry_service.dart';
import '../utils/expiring_ingredients_utils.dart';
import '../utils/icon_catalog.dart';
import '../utils/recipe_recommendation_utils.dart';

/// 오늘의 요리 추천 위젯
class DailyRecipeRecommendationWidget extends StatefulWidget {
  final String? accountName;

  const DailyRecipeRecommendationWidget({super.key, this.accountName});

  @override
  State<DailyRecipeRecommendationWidget> createState() =>
      _DailyRecipeRecommendationWidgetState();
}

class _DailyRecipeRecommendationWidgetState
    extends State<DailyRecipeRecommendationWidget> {
  List<FoodExpiryItem>? _expiringItems;
  RecipeMatch? _recommendedRecipe;
  bool _isLoading = true;

  Color _chipBackgroundColor(ThemeData theme, int daysLeft) {
    final scheme = theme.colorScheme;
    if (daysLeft <= 0) return scheme.errorContainer;
    if (daysLeft == 1) return scheme.tertiaryContainer;
    return scheme.secondaryContainer;
  }

  Color _badgeBackgroundColor(ThemeData theme, int percentage) {
    final scheme = theme.colorScheme;
    if (percentage >= 100) return scheme.primary;
    if (percentage >= 80) return scheme.secondary;
    if (percentage >= 60) return scheme.tertiary;
    return scheme.error;
  }

  Color _badgeForegroundColor(ThemeData theme, int percentage) {
    final scheme = theme.colorScheme;
    if (percentage >= 100) return scheme.onPrimary;
    if (percentage >= 80) return scheme.onSecondary;
    if (percentage >= 60) return scheme.onTertiary;
    return scheme.onError;
  }

  @override
  void initState() {
    super.initState();
    _loadRecommendation();
  }

  Future<void> _loadRecommendation() async {
    try {
      // 음식 보관함 서비스에서 전체 항목 로드
      final allItems = FoodExpiryService.instance.items.value;

      if (mounted) {
        // 3일 이내 유통기한 항목만 필터링
        final expiring = ExpiringIngredientsUtils.getExpiringWithin3Days(
          allItems,
        );

        // 유통기한 임박한 항목이 없으면 표시하지 않음
        if (expiring.isEmpty) {
          setState(() {
            _isLoading = false;
            _expiringItems = [];
          });
          return;
        }

        // 추천 요리 생성
        final topRecipes = RecipeRecommendationUtils.getTopRecommendations(
          expiring,
          limit: 1,
        );

        setState(() {
          _expiringItems = expiring;
          _recommendedRecipe = topRecipes.isNotEmpty ? topRecipes.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(
        'DailyRecipeRecommendation: Error loading recommendation - '
        '$e',
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // 추천할 항목이 없으면 표시하지 않음
    if (_expiringItems == null ||
        _expiringItems!.isEmpty ||
        _recommendedRecipe == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Row(
                children: [
                  Icon(
                    IconCatalog.restaurant,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '오늘의 요리 추천',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 임박한 재료 목록 (최대 3개)
              Text(
                '이 재료들이 곧 상해요:',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _expiringItems!.take(3).map((item) {
                  final daysLeft = ExpiringIngredientsUtils.daysUntilExpiry(
                    item,
                  );
                  return Chip(
                    label: Text(
                      '${item.name} ($daysLeft일)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    backgroundColor: _chipBackgroundColor(theme, daysLeft),
                    side: BorderSide.none,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 추천 요리
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _recommendedRecipe!.recipeName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _badgeBackgroundColor(
                              theme,
                              _recommendedRecipe!.matchPercentage,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_recommendedRecipe!.matchPercentage}% 준비됨',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _badgeForegroundColor(
                                theme,
                                _recommendedRecipe!.matchPercentage,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _recommendedRecipe!.message,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
