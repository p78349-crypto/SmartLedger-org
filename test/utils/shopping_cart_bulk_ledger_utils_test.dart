import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/category_hint.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/utils/shopping_cart_bulk_ledger_utils.dart';

void main() {
  testWidgets('addCheckedItemsToLedgerBulk shows snack when nothing checked', (tester) async {
    final now = DateTime(2026, 1, 11);
    final items = <ShoppingCartItem>[
      ShoppingCartItem(id: 'i1', name: '물', isChecked: false, createdAt: now, updatedAt: now),
      ShoppingCartItem(id: 'i2', name: '빵', isChecked: false, createdAt: now, updatedAt: now),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  ShoppingCartBulkLedgerUtils.addCheckedItemsToLedgerBulk(
                    context: context,
                    accountName: 'acc1',
                    items: items,
                    categoryHints: <String, CategoryHint>{},
                    saveItems: (_) async {},
                    reload: () async {},
                  );
                },
                child: const Text('run'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('run'));
    await tester.pump();

    expect(find.text('체크된 항목이 없습니다.'), findsOneWidget);
  });
}
