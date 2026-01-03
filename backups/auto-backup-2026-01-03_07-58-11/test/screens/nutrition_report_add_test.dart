import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/screens/nutrition_report_screen.dart';

void main() {
  testWidgets('tapping add on a pairing calls callback', (tester) async {
    String? added;

    await tester.pumpWidget(MaterialApp(
      home: NutritionReportScreen(
        rawText: '',
        onAddIngredient: (s) => added = s,
      ),
    ));

    // Enter a query
    await tester.enterText(find.byType(TextField), '닭고기');
    await tester.pumpAndSettle();

    // Ensure the pairing is displayed
    expect(find.textContaining('브로콜리'), findsOneWidget);

    // Find first '추가' button and tap it
    final addButton = find.widgetWithText(ElevatedButton, '추가').first;
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(added, isNotNull);
    expect(added, anyOf('브로콜리', '버섯(표고/느타리/팽이)', '양파/마늘', '파프리카/토마토', '현미/귀리(또는 잡곡밥)'));
  });
}

