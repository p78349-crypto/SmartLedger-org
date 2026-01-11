import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/snackbar_utils.dart';

void main() {
  group('SnackbarUtils', () {
    testWidgets('show displays a SnackBar with message', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SnackbarUtils.show(context, 'hello'),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();

      expect(find.text('hello'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('showWithUndo triggers onUndo callback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      var undone = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SnackbarUtils.showWithUndo(
                  context,
                  'deleted',
                  onUndo: () => undone = true,
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      expect(find.text('deleted'), findsOneWidget);

      final undoButton = find.widgetWithText(TextButton, '실행 취소');
      await tester.ensureVisible(undoButton);
      await tester.tap(undoButton);
      await tester.pumpAndSettle();

      expect(undone, isTrue);
    });
  });
}
