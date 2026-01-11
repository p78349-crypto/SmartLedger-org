import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/recipe_recommendation_style_utils.dart';

void main() {
  group('RecipeRecommendationStyleUtils', () {
    final theme = ThemeData.from(colorScheme: const ColorScheme.light());

    test('chipBackgroundColor uses urgency buckets', () {
      expect(
        RecipeRecommendationStyleUtils.chipBackgroundColor(theme, -1),
        theme.colorScheme.errorContainer,
      );
      expect(
        RecipeRecommendationStyleUtils.chipBackgroundColor(theme, 0),
        theme.colorScheme.errorContainer,
      );
      expect(
        RecipeRecommendationStyleUtils.chipBackgroundColor(theme, 1),
        theme.colorScheme.tertiaryContainer,
      );
      expect(
        RecipeRecommendationStyleUtils.chipBackgroundColor(theme, 2),
        theme.colorScheme.secondaryContainer,
      );
    });

    test('matchBadge colors map by percentage', () {
      expect(
        RecipeRecommendationStyleUtils.matchBadgeBackgroundColor(theme, 100),
        theme.colorScheme.primary,
      );
      expect(
        RecipeRecommendationStyleUtils.matchBadgeBackgroundColor(theme, 80),
        theme.colorScheme.secondary,
      );
      expect(
        RecipeRecommendationStyleUtils.matchBadgeBackgroundColor(theme, 60),
        theme.colorScheme.tertiary,
      );
      expect(
        RecipeRecommendationStyleUtils.matchBadgeBackgroundColor(theme, 10),
        theme.colorScheme.error,
      );

      expect(
        RecipeRecommendationStyleUtils.matchBadgeForegroundColor(theme, 100),
        theme.colorScheme.onPrimary,
      );
      expect(
        RecipeRecommendationStyleUtils.matchBadgeForegroundColor(theme, 80),
        theme.colorScheme.onSecondary,
      );
      expect(
        RecipeRecommendationStyleUtils.matchBadgeForegroundColor(theme, 60),
        theme.colorScheme.onTertiary,
      );
      expect(
        RecipeRecommendationStyleUtils.matchBadgeForegroundColor(theme, 10),
        theme.colorScheme.onError,
      );
    });
  });
}
