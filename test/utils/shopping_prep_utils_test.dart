import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/utils/shopping_prep_utils.dart';

void main() {
  group('ShoppingPrepUtils', () {
    ShoppingCartItem item(String id, String name) => ShoppingCartItem(
          id: id,
          name: name,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        );

    test('normalizeName trims/lowercases/removes spaces', () {
      expect(ShoppingPrepUtils.normalizeName('  Ab C  '), 'abc');
    });

    test('mergeByName adds unique incoming and skips duplicates', () {
      final existing = [item('e1', 'Apple')];
      final incoming = [
        item('i1', ' apple '), // duplicate (normalized)
        item('i2', 'Banana'),
        item('i3', '  '), // ignored
      ];

      final result = ShoppingPrepUtils.mergeByName(existing: existing, incoming: incoming);
      expect(result.added, 1);
      expect(result.skipped, 1);
      expect(result.merged.length, 2);

      // New items come first.
      expect(result.merged.first.name, 'Banana');
      expect(result.merged.last.name, 'Apple');
    });
  });
}
