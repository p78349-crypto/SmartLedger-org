import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/screens/shopping_cart_screen.dart';

void main() {
  testWidgets('ShoppingCart: renders and accepts inline input', (tester) async {
    SharedPreferences.setMockInitialValues({});

    final now = DateTime(2026, 1, 7);
    final items = <ShoppingCartItem>[
      ShoppingCartItem(
        id: 'i1',
        name: '브로콜리',
        unitLabel: '개수',
        createdAt: now,
        updatedAt: now,
      ),
      ShoppingCartItem(
        id: 'i2',
        name: '닭고기',
        unitLabel: '개수',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    Future<EditableText> editableForKey(ValueKey<String> key) async {
      final field = find.byKey(key);
      expect(field, findsOneWidget);
      final editable = find.descendant(
        of: field,
        matching: find.byType(EditableText),
      );
      expect(editable, findsOneWidget);
      return tester.widget<EditableText>(editable);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(420, 900)),
          child: ShoppingCartScreen(
            accountName: 'a',
            openPrepOnStart: true,
            initialItems: items,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Focus price of first item and input.
    const price1Key = ValueKey<String>('sc_price_i1');
    await tester.tap(find.byKey(price1Key));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(price1Key), '1200');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Focus qty of first item and input.
    const qty1Key = ValueKey<String>('sc_qty_i1');
    await tester.tap(find.byKey(qty1Key));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(qty1Key), '2');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Sanity: both fields are still in the tree.
    expect(await editableForKey(const ValueKey<String>('sc_qty_i1')), isNotNull);
    expect(await editableForKey(const ValueKey<String>('sc_price_i1')), isNotNull);
  });
}
