import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/dialog_utils.dart';

void main() {
  group('DialogUtils', () {
    testWidgets('showConfirmDialog returns true when confirmed', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DialogUtils.showConfirmDialog(
                    context,
                    title: 't',
                    message: 'm',
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('t'), findsOneWidget);
      expect(find.text('m'), findsOneWidget);

      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('showTextInputDialog validates and returns trimmed value', (
      tester,
    ) async {
      String? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await DialogUtils.showTextInputDialog(
                    context,
                    title: 'input',
                    hint: 'h',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'required';
                      return null;
                    },
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Try confirm with empty -> show validation message
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();
      expect(find.text('required'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), '  abc  ');
      await tester.tap(find.text('확인'));
      await tester.pumpAndSettle();

      expect(result, 'abc');
    });
  });
}
