import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/page_indicator.dart';

void main() {
  group('PageIndicator', () {
    testWidgets('renders current page number (1-based)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PageIndicator(pageCount: 3, currentPage: 1),
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('tap calls onPageTap with currentPage', (tester) async {
      int? tapped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageIndicator(
              pageCount: 3,
              currentPage: 0,
              onPageTap: (v) => tapped = v,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PageIndicator));
      await tester.pump();

      expect(tapped, 0);
    });
  });
}
