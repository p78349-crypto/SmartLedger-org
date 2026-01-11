import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/screens/ceo_monthly_defense_report_screen.dart';

void main() {
  group('CEOMonthlyDefenseReportScreen', () {
    testWidgets('renders with required accountName', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CEOMonthlyDefenseReportScreen(accountName: 'TestAccount'),
          ),
        ),
      );

      // 초기 로딩 상태 확인
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('widget creates without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CEOMonthlyDefenseReportScreen(accountName: 'TestAccount'),
          ),
        ),
      );

      // 위젯 생성 확인
      expect(find.byType(CEOMonthlyDefenseReportScreen), findsOneWidget);
      
      // 몇 프레임 진행
      await tester.pump(const Duration(milliseconds: 100));
      
      // 여전히 위젯 존재
      expect(find.byType(CEOMonthlyDefenseReportScreen), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CEOMonthlyDefenseReportScreen(accountName: 'TestAccount'),
          ),
        ),
      );

      // 첫 프레임에서 로딩 인디케이터 확인
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
