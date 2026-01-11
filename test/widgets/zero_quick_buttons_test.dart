import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/widgets/zero_quick_buttons.dart';

void main() {
  group('ZeroQuickButtons', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders three buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZeroQuickButtons(controller: controller),
          ),
        ),
      );

      expect(find.text('+00'), findsOneWidget);
      expect(find.text('+0'), findsOneWidget);
      expect(find.text('+000'), findsOneWidget);
    });

    testWidgets('appends 00 when first button pressed', (tester) async {
      controller.text = '12';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZeroQuickButtons(controller: controller),
          ),
        ),
      );

      await tester.tap(find.text('+00'));
      await tester.pump();

      expect(controller.text, '1200');
    });

    testWidgets('appends 0 when second button pressed', (tester) async {
      controller.text = '5';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZeroQuickButtons(controller: controller),
          ),
        ),
      );

      await tester.tap(find.text('+0'));
      await tester.pump();

      expect(controller.text, '50');
    });

    testWidgets('appends 000 when third button pressed', (tester) async {
      controller.text = '1';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZeroQuickButtons(controller: controller),
          ),
        ),
      );

      await tester.tap(find.text('+000'));
      await tester.pump();

      expect(controller.text, '1000');
    });

    testWidgets('works with empty initial text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZeroQuickButtons(controller: controller),
          ),
        ),
      );

      await tester.tap(find.text('+00'));
      await tester.pump();

      expect(controller.text, '00');
    });

    testWidgets('calls onChanged callback', (tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZeroQuickButtons(
              controller: controller,
              onChanged: () => callbackCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('+0'));
      await tester.pump();

      expect(callbackCalled, isTrue);
    });

    testWidgets('formats with thousands separator when enabled', (tester) async {
      controller.text = '123';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZeroQuickButtons(
              controller: controller,
              formatThousands: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('+000'));
      await tester.pump();

      expect(controller.text, '123,000');
    });

    testWidgets('multiple appends work correctly', (tester) async {
      controller.text = '1';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZeroQuickButtons(controller: controller),
          ),
        ),
      );

      await tester.tap(find.text('+0'));
      await tester.pump();
      expect(controller.text, '10');

      await tester.tap(find.text('+00'));
      await tester.pump();
      expect(controller.text, '1000');
    });
  });
}
