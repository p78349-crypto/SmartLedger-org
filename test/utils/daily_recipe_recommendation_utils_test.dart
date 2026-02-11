import 'package:flutter_test/flutter_test.dart';

import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/utils/daily_recipe_recommendation_utils.dart';

ConsumableInventoryItem _item(String id, String name, DateTime expiryDate) {
  final createdAt = DateTime(2026);
  return ConsumableInventoryItem(
    id: id,
    name: name,
    createdAt: createdAt,
    lastUpdated: createdAt,
    purchaseDate: createdAt,
    expiryDate: expiryDate,
  );
}

void main() {
  test('build returns empty when no expiring items', () async {
    final now = DateTime(2026, 1, 9, 12);

    final items = <ConsumableInventoryItem>[
      _item('late', '늦음', now.add(const Duration(days: 10))),
    ];

    final result = await DailyRecipeRecommendationUtils.build(items, now: now);

    expect(result.expiringItems, isEmpty);
    expect(result.recommendedRecipe, isNull);
    expect(result.hasRecommendation, isFalse);
  });
}
