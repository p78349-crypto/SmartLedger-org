import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/shopping_cart_next_prep_dialog_utils.dart';

void main() {
  testWidgets('ShoppingCartNextPrepDialogUtils shows default action first and returns selection', (tester) async {
    ShoppingCartNextPrepAction? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  selected = await ShoppingCartNextPrepDialogUtils.show(
                    context,
                    defaultAction: ShoppingCartNextPrepAction.recentPurchases20,
                  );
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Default action should have (추천) suffix.
    expect(find.text('최근 구매 20개 (추천)'), findsOneWidget);
    expect(find.text('추천 품목 20개'), findsOneWidget);
    expect(find.text('마트/쇼핑몰별 추천 20개'), findsOneWidget);
    expect(find.text('요리 레시피 검색'), findsOneWidget);

    // Select one option and ensure it returns.
    final option = find.widgetWithText(ListTile, '요리 레시피 검색');
    final scrollable = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(option, 200, scrollable: scrollable);
    await tester.pumpAndSettle();
    await tester.tap(option);
    await tester.pumpAndSettle();

    expect(selected, ShoppingCartNextPrepAction.recipeSearch);
  });
}
