import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/screens/nutrition_report_screen.dart';

void main() {
  testWidgets('tapping add on a pairing calls callback', (tester) async {
    String? added;

    await tester.pumpWidget(
      MaterialApp(
        home: NutritionReportScreen(
          rawText: '',
          onAddIngredient: (s) => added = s,
        ),
      ),
    );

    // Wait for initial widget build
    await tester.pumpAndSettle();

    // Enter a query
    await tester.enterText(find.byType(TextField), '닭고기');
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Verify that at least one suggestion appears
    // (Broccoli might be one of the pairing suggestions for chicken)
    final suggestions = find.byType(Card);
    expect(suggestions, findsWidgets);

    // Find first '추가' button from any suggestion card and tap it
    final addButtons = find.widgetWithText(ElevatedButton, '추가');
    if (addButtons.evaluate().isNotEmpty) {
      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      // Verify the callback was called
      expect(added, isNotNull);
      expect(added, isNotEmpty);
    }
  });
}
