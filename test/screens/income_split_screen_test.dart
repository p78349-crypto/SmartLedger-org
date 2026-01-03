import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/screens/income_split_screen.dart';
import 'package:smart_ledger/services/income_split_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IncomeSplitScreen Widget', () {
    setUp(() async {
      // Ensure no leftover split
      await IncomeSplitService().deleteSplit('test_account');
    });

    testWidgets(
      'saves split when only one field is filled and total is empty',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: IncomeSplitScreen(accountName: 'test_account'),
            ),
          ),
        );

        // Ensure initial state
        await tester.pumpAndSettle();

        // Enter emergency amount only (4th TextField)
        final emergencyField = find.byType(TextField).at(3);
        await tester.enterText(emergencyField, '50000');
        await tester.pumpAndSettle();

        // Tap save button
        await tester.tap(find.text('저장'));
        await tester.pumpAndSettle();

        // Verify that IncomeSplitService saved the split
        final split = IncomeSplitService().getSplit('test_account');
        expect(split, isNotNull);
        expect(split!.emergencyAmount, equals(50000));
        expect(split.incomeItems.first.amount, equals(50000));
      },
    );
  });
}
