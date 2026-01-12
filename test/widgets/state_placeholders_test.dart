import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/widgets/state_placeholders.dart';

void main() {
  group('EmptyState', () {
    testWidgets('displays title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(title: 'No items found'),
          ),
        ),
      );

      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets('displays optional message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Empty',
              message: 'Add some items to get started',
            ),
          ),
        ),
      );

      expect(find.text('Add some items to get started'), findsOneWidget);
    });

    testWidgets('displays icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(title: 'Empty'),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('displays primary action button when provided', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Empty',
              primaryLabel: 'Add Item',
              onPrimary: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);

      await tester.tap(find.text('Add Item'));
      expect(pressed, isTrue);
    });

    testWidgets('displays secondary action when provided', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              title: 'Empty',
              secondaryLabel: 'Learn More',
              onSecondary: () => pressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Learn More'), findsOneWidget);

      await tester.tap(find.text('Learn More'));
      expect(pressed, isTrue);
    });
  });

  group('ErrorState', () {
    testWidgets('displays default error title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(),
          ),
        ),
      );

      expect(find.text('오류가 발생했습니다'), findsOneWidget);
    });

    testWidgets('displays custom title and message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(
              title: 'Error occurred',
              message: 'Something went wrong',
            ),
          ),
        ),
      );

      expect(find.text('Error occurred'), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('displays retry button when callback provided', (tester) async {
      bool retried = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorState(
              title: 'Error',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('다시 시도'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      expect(retried, isTrue);
    });

    testWidgets('hides retry button when no callback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorState(title: 'Error'),
          ),
        ),
      );

      expect(find.text('다시 시도'), findsNothing);
    });
  });

  group('LoadingCardListSkeleton', () {
    testWidgets('renders default item count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: LoadingCardListSkeleton(),
            ),
          ),
        ),
      );

      // 기본 4개 아이템
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('renders custom item count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: LoadingCardListSkeleton(itemCount: 2),
            ),
          ),
        ),
      );

      expect(find.byType(LoadingCardListSkeleton), findsOneWidget);
    });
  });
}
