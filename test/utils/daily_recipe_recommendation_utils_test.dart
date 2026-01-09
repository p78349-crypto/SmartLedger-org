import 'package:flutter_test/flutter_test.dart';

import 'package:smart_ledger/models/food_expiry_item.dart';
import 'package:smart_ledger/utils/daily_recipe_recommendation_utils.dart';

FoodExpiryItem _item(String id, String name, DateTime expiryDate) {
  final createdAt = DateTime(2026);
  return FoodExpiryItem(
    id: id,
    name: name,
    purchaseDate: createdAt,
    expiryDate: expiryDate,
    createdAt: createdAt,
  );
}

void main() {
  test('build returns empty when no expiring items', () {
    final now = DateTime(2026, 1, 9, 12);

    final items = <FoodExpiryItem>[
      _item('late', '늦음', now.add(const Duration(days: 10))),
    ];

    final result = DailyRecipeRecommendationUtils.build(
      items,
      now: now,
    );

    expect(result.expiringItems, isEmpty);
    expect(result.recommendedRecipe, isNull);
    expect(result.hasRecommendation, isFalse);
  });
}
