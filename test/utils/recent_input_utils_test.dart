import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/recent_input_utils.dart';

void main() {
  group('RecentInputUtils', () {
    test('selectAllText selects full range', () {
      final controller = TextEditingController(text: 'hello');
      RecentInputUtils.selectAllText(controller);
      expect(controller.selection.baseOffset, 0);
      expect(controller.selection.extentOffset, 5);
    });

    testWidgets('buildHistoryChips returns shrink when empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentInputUtils.buildHistoryChips(
              items: const [],
              onSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('buildHistoryChips builds chips and calls onSelected', (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentInputUtils.buildHistoryChips(
              items: const ['A', 'B'],
              label: '최근',
              onSelected: (v) => selected = v,
            ),
          ),
        ),
      );

      expect(find.text('최근'), findsOneWidget);
      expect(find.byType(ActionChip), findsNWidgets(2));

      await tester.tap(find.text('B'));
      await tester.pump();
      expect(selected, 'B');
    });
  });
}
