import 'package:flutter_test/flutter_test.dart';

import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/utils/expiring_ingredients_utils.dart';

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
  test('getExpiringWithinDays filters within window and excludes past', () {
    final now = DateTime(2026, 1, 9, 12);

    final items = <ConsumableInventoryItem>[
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
