import 'package:flutter/material.dart';

class RecipeRecommendationStyleUtils {
  RecipeRecommendationStyleUtils._();

  static Color chipBackgroundColor(ThemeData theme, int daysLeft) {
    final scheme = theme.colorScheme;
    if (daysLeft <= 0) return scheme.errorContainer;
    if (daysLeft == 1) return scheme.tertiaryContainer;
    return scheme.secondaryContainer;
  }

  static Color matchBadgeBackgroundColor(ThemeData theme, int percentage) {
    final scheme = theme.colorScheme;
    if (percentage >= 100) return scheme.primary;
    if (percentage >= 80) return scheme.secondary;
    if (percentage >= 60) return scheme.tertiary;
    return scheme.error;
  }

  static Color matchBadgeForegroundColor(ThemeData theme, int percentage) {
    final scheme = theme.colorScheme;
    if (percentage >= 100) return scheme.onPrimary;
    if (percentage >= 80) return scheme.onSecondary;
    if (percentage >= 60) return scheme.onTertiary;
    return scheme.onError;
  }
}
