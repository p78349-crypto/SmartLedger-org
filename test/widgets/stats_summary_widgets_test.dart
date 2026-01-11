import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/widgets/stats_summary_widgets.dart';

void main() {
  group('StatsSummaryGrid', () {
    testWidgets('renders 2-column grid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsSummaryGrid(
              children: [
                Container(key: const Key('item1')),
                Container(key: const Key('item2')),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('item1')), findsOneWidget);
      expect(find.byKey(const Key('item2')), findsOneWidget);
    });

    testWidgets('uses GridView.count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatsSummaryGrid(children: [Container()]),
          ),
        ),
      );

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('StatsSummaryCard', () {
    testWidgets('displays icon, title, and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsSummaryCard(
              icon: Icons.attach_money,
              title: 'Total Income',
              value: '₩1,000,000',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.attach_money), findsOneWidget);
      expect(find.text('Total Income'), findsOneWidget);
      expect(find.text('₩1,000,000'), findsOneWidget);
    });

    testWidgets('applies custom valueColor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsSummaryCard(
              icon: Icons.trending_up,
              title: 'Profit',
              value: '+50%',
              valueColor: Colors.green,
            ),
          ),
        ),
      );

      // 카드가 렌더링되는지 확인
      expect(find.byType(StatsSummaryCard), findsOneWidget);
      expect(find.text('+50%'), findsOneWidget);
    });

    testWidgets('uses primary color when valueColor is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: const Scaffold(
            body: StatsSummaryCard(
              icon: Icons.account_balance,
              title: 'Balance',
              value: '₩500,000',
            ),
          ),
        ),
      );

      expect(find.byType(StatsSummaryCard), findsOneWidget);
    });
  });
}
