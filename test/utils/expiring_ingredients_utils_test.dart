import 'package:flutter_test/flutter_test.dart';

import 'package:smart_ledger/models/food_expiry_item.dart';
import 'package:smart_ledger/utils/expiring_ingredients_utils.dart';

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
  test('getExpiringWithinDays filters within window and excludes past', () {
    final now = DateTime(2026, 1, 9, 12);

    final items = <FoodExpiryItem>[
      _item('past', '지난것', now.subtract(const Duration(days: 1))),
      _item('in1', '내일', now.add(const Duration(days: 1))),
      _item('in3', '3일', now.add(const Duration(days: 3))),
      _item('in4', '4일', now.add(const Duration(days: 4))),
    ];

    final result = ExpiringIngredientsUtils.getExpiringWithinDays(
      items,
      days: 3,
      now: now,
    );

    expect(result.map((e) => e.id).toList(), ['in1', 'in3']);
  });
}
