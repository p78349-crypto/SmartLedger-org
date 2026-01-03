import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/screens/shopping_cart_screen.dart';
import 'package:smart_ledger/services/user_pref_service.dart';

void main() {
  testWidgets('Enter moves focus: unit -> qty -> next unit', (tester) async {
    final now = DateTime.now();
    final items = [
      ShoppingCartItem(
        id: 'a',
        name: 'A',
        quantity: 1,
        unitPrice: 0,
        createdAt: now,
        updatedAt: now,
      ),
      ShoppingCartItem(
        id: 'b',
        name: 'B',
        quantity: 1,
        unitPrice: 0,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    // Prepare SharedPreferences and store items so the screen loads them
    SharedPreferences.setMockInitialValues({});
    await UserPrefService.setShoppingCartItems(
      accountName: 'test',
      items: items,
    );

    // Make test device larger to avoid layout overflow
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const MaterialApp(home: ShoppingCartScreen(accountName: 'test')),
    );

    await tester.pumpAndSettle();

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Enter unit for first item
    final unitFinder = find
        .byWidgetPredicate(
          (w) => w is TextField && (w.decoration?.hintText == '가격'),
        )
        .at(0);
    expect(unitFinder, findsOneWidget);
    expect(unitFinder, findsOneWidget);

    await tester.tap(unitFinder);
    await tester.pumpAndSettle();
    await tester.enterText(unitFinder, '1200');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    // qty should have focus
    final qtyFinder = find.byWidgetPredicate(
      (w) => w is TextField && (w.decoration?.hintText == '수량'),
    );
    expect(qtyFinder, findsWidgets);
    final qtyField = tester.widget<TextField>(qtyFinder.first);
    expect(qtyField.focusNode?.hasFocus ?? true, isTrue);

    // Enter qty and press Enter: should move to next unit
    await tester.tap(qtyFinder.first);
    await tester.pumpAndSettle();
    await tester.enterText(qtyFinder.first, '2');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    final nextUnitFinderAll = find.byWidgetPredicate(
      (w) => w is TextField && (w.decoration?.hintText == '가격'),
    );
    expect(nextUnitFinderAll, findsNWidgets(2));
    final nextUnitFinder = nextUnitFinderAll.at(1);
    final nextUnitField = tester.widget<TextField>(nextUnitFinder);
    expect(nextUnitField.focusNode?.hasFocus ?? true, isTrue);
  });
}
