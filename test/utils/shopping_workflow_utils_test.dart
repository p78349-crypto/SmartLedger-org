import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/shopping_workflow_utils.dart';

void main() {
  group('ShoppingWorkflowUtils', () {
    test('createItem sets name and default fields', () {
      final item = ShoppingWorkflowUtils.createItem('Apple');
      expect(item.name, 'Apple');
      expect(item.quantity, '1');
      expect(item.estimatedPrice, '0');
      expect(item.isChecked, isFalse);
      expect(item.id, isNotEmpty);
    });

    test('toggleItemCheck toggles isChecked', () {
      final item = CartItem(id: '1', name: 'A');
      expect(item.isChecked, isFalse);
      ShoppingWorkflowUtils.toggleItemCheck(item);
      expect(item.isChecked, isTrue);
      ShoppingWorkflowUtils.toggleItemCheck(item);
      expect(item.isChecked, isFalse);
    });

    test('updateItemDetails updates quantity/price when provided', () {
      final item = CartItem(id: '1', name: 'A');
      ShoppingWorkflowUtils.updateItemDetails(item, quantity: '3');
      expect(item.quantity, '3');
      ShoppingWorkflowUtils.updateItemDetails(item, price: '1200');
      expect(item.estimatedPrice, '1200');
    });

    test('getCheckedItems filters only checked', () {
      final items = [
        CartItem(id: '1', name: 'A', isChecked: true),
        CartItem(id: '2', name: 'B'),
      ];
      final checked = ShoppingWorkflowUtils.getCheckedItems(items);
      expect(checked.map((e) => e.id).toList(), ['1']);
    });

    test('calculateTotal parses qty/price with fallbacks', () {
      final items = [
        CartItem(id: '1', name: 'A', quantity: '2', estimatedPrice: '1000'),
        CartItem(id: '2', name: 'B', quantity: 'x', estimatedPrice: '500'), // qty fallback 1
        CartItem(id: '3', name: 'C', quantity: '3', estimatedPrice: 'y'), // price fallback 0
      ];
      expect(ShoppingWorkflowUtils.calculateTotal(items), 2 * 1000 + 1 * 500 + 3 * 0);
    });

    test('getNextMode follows workflow rules', () {
      expect(
        ShoppingWorkflowUtils.getNextMode(ShoppingMode.planning, []),
        ShoppingMode.planning,
      );
      expect(
        ShoppingWorkflowUtils.getNextMode(
          ShoppingMode.planning,
          [CartItem(id: '1', name: 'A')],
        ),
        ShoppingMode.shopping,
      );

      final items = [CartItem(id: '1', name: 'A', isChecked: true)];
      expect(
        ShoppingWorkflowUtils.getNextMode(ShoppingMode.shopping, items),
        ShoppingMode.recording,
      );

      expect(
        ShoppingWorkflowUtils.getNextMode(ShoppingMode.recording, items),
        ShoppingMode.planning,
      );
    });

    test('completeWorkflow removes checked items', () {
      final items = [
        CartItem(id: '1', name: 'A', isChecked: true),
        CartItem(id: '2', name: 'B'),
      ];
      ShoppingWorkflowUtils.completeWorkflow(items);
      expect(items.map((e) => e.id).toList(), ['2']);
    });
  });
}
