import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/collapsible_section.dart';

void main() {
  group('CollapsibleSectionHeader', () {
    testWidgets('shows title and optional subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollapsibleSectionHeader(
              title: '제목',
              subtitle: '부제',
              isExpanded: true,
              onToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('제목'), findsOneWidget);
      expect(find.text('부제'), findsOneWidget);
    });

    testWidgets('shows back icon when expanded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollapsibleSectionHeader(
              title: '제목',
              isExpanded: true,
              onToggle: () {},
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.arrow_back_ios);
    });

    testWidgets('shows forward icon when collapsed', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollapsibleSectionHeader(
              title: '제목',
              isExpanded: false,
              onToggle: () {},
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.arrow_forward_ios);
    });

    testWidgets('tapping calls onToggle', (tester) async {
      var toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollapsibleSectionHeader(
              title: '제목',
              isExpanded: true,
              onToggle: () {
                toggled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(toggled, true);
    });
  });

  group('CollapsibleSection', () {
    testWidgets('shows children when initiallyExpanded is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: '섹션',
              initiallyExpanded: true,
              children: [Text('Child')],
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('hides children when initiallyExpanded is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: '섹션',
              initiallyExpanded: false,
              children: [Text('Child')],
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsNothing);
    });

    testWidgets('toggles children when header tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: '섹션',
              initiallyExpanded: true,
              children: [Text('Child')],
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(find.text('Child'), findsNothing);

      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(find.text('Child'), findsOneWidget);
    });
  });
}
