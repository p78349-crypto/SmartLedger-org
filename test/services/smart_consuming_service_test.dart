import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/fixed_cost.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/budget_service.dart';
import 'package:smart_ledger/services/fixed_cost_service.dart';
import 'package:smart_ledger/services/smart_consuming_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testAccount = 'weekly_logic_test_account';

  group('SmartConsumingService - Weekly Logic', () {
    late SmartConsumingService smartService;
    late BudgetService budgetService;
    late TransactionService transactionService;
    late FixedCostService fixedCostService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        PrefKeys.txStorageBackendV1: 'prefs',
      });
      smartService = SmartConsumingService();

      budgetService = BudgetService();
      // Force reload to clear previous state
      await budgetService.loadBudgets();

      transactionService = TransactionService();
      await transactionService.loadTransactions();
      if (transactionService.getAllAccountNames().contains(testAccount)) {
        await transactionService.deleteAccount(testAccount);
      }
      await transactionService.createAccount(testAccount);

      fixedCostService = FixedCostService();
      await fixedCostService.loadFixedCosts();
    });

    test('Budget not set returns error message', () async {
      final report = await smartService.analyzeWeeklyStatus(testAccount);
      expect(report.message, '예산 미설정');
      expect(report.weeklyBudget, 0);
    });

    test('Weekly Sector Calculation and Standard Report', () async {
      // Setup: 100만원 Budget
      await budgetService.setBudget(testAccount, 1000000);

      final report = await smartService.analyzeWeeklyStatus(testAccount);

      // Basic checks
      expect(report.weeklyBudget, greaterThan(0));
      expect(report.currentWeek, greaterThanOrEqualTo(1));

      // If no spending, burn rate should be 0
      expect(report.burnRate, 0.0);
    });

    test('Burn Rate Calculation (Overspending scenario)', () async {
      // Setup: 100만원 Budget
      await budgetService.setBudget(testAccount, 1000000);

      // Spend 60만원 today (assuming today is early in the month, this is high burn)
      // Note: This test depends on the actual date.
      // If today is day 1, spending 60% is huge (30*0.6=18x burn).
      // If today is day 30, spending 60% is low burn (0.6x).
      // We can't easily mock DateTime.now() without a library or refactoring,
      // so we check relative logic or ensure non-zero.

      final now = DateTime.now();
      await transactionService.addTransaction(
        testAccount,
        Transaction(
          id: 'tx1',
          type: TransactionType.expense,
          amount: 600000,
          date: now,
          description: 'Large Spending',
        ),
      );

      final report = await smartService.analyzeWeeklyStatus(testAccount);

      // We definitely spent something, so burn rate > 0
      expect(report.burnRate, greaterThan(0));

      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final timeRatio = now.day / daysInMonth;
      const budgetRatio = 600000 / 1000000;

      // If we spent 60% of budget on day 1 (time ratio ~0.03), burn rate ~20.
      if (timeRatio > 0) {
        expect(report.burnRate, closeTo(budgetRatio / timeRatio, 0.01));
      }
    });

    test('Tactical Shift - High Fixed Cost reduces recommended limit', () async {
      // 100만원 예산
      await budgetService.setBudget(testAccount, 1000000);

      // 고정 지출 30만원 (말일 예정)
      // Ensure dueDay is in the future but within this month
      // If today is 31st, this test might be tricky logic-wise.
      // Assuming typical day. If today is end of month, future fixed cost is 0.

      final now = DateTime.now();
      final lastDay = DateTime(now.year, now.month + 1, 0).day;

      if (now.day < lastDay) {
        await fixedCostService.addFixedCost(
          testAccount,
          FixedCost(
            id: 'fc1',
            name: 'Future Rent',
            amount: 300000,
            dueDay: lastDay, // end of month
            // category: 'Housing' Removed
          ),
        );

        final report = await smartService.analyzeWeeklyStatus(testAccount);

        // Recommended limit should consider the 300k reserved.
        // Available = 1000k - 300k = 700k.
        // If we are in week 1 of 4, recommended ~ 700k/4 = 175k.
        // Standard budget ~ 1000k/4 = 250k.
        // So recommended < standard.

        expect(report.recommendedLimit, lessThan(report.weeklyBudget));
      } else {
        // Can't test future fixed cost on last day of month easily without mocking time
        // Just pass
      }
    });

    test('Tactical Shift - Emergency Stop (Over Budget)', () async {
      await budgetService.setBudget(testAccount, 1000000);

      // Spend 120만원
      await transactionService.addTransaction(
        testAccount,
        Transaction(
          id: 'tx_overflow',
          type: TransactionType.expense,
          amount: 1200000,
          date: DateTime.now(),
          description: 'Disaster',
        ),
      );

      final report = await smartService.analyzeWeeklyStatus(testAccount);

      expect(report.recommendedLimit, 0);
      expect(report.subMessage, contains('지출을 멈춰야'));
    });
  });
}
