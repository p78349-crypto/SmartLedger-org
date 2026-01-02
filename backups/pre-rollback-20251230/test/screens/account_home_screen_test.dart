import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/account_home_screen.dart';
import 'package:smart_ledger/services/income_split_service.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AccountHomeScreen shows category budget usage button', (
    WidgetTester tester,
  ) async {
    const accountName = 'test_account';
    await IncomeSplitService().setSplit(
      accountName: accountName,
      incomeItems: [
        IncomeItem(id: '1', name: '월급', amount: 5000000, category: 'salary'),
      ],
      savingsAmount: 1000000,
      budgetAmount: 2000000,
      emergencyAmount: 300000,
      categoryBudgets: const {'식비': 100000},
      persistToStorage: false,
      createAssetMoves: false,
    );

    await tester.pumpWidget(
      const MaterialApp(home: AccountHomeScreen(accountName: accountName)),
    );
    await tester.pumpAndSettle();

    expect(find.text('카테고리 예산 사용량 그래프 보기'), findsOneWidget);
  });
}

