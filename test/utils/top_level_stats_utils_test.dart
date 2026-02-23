import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/widgets/root_summary_card.dart';
import 'package:smart_ledger/utils/top_level_stats_utils.dart';

void main() {
  group('TopLevelStatsUtils', () {
    test('buildDashboardContext symbol is available (smoke)', () {
      // Avoid invoking it here because it touches services (DB/prefs).
      expect(TopLevelStatsUtils.buildDashboardContext, isA<Function>());
    });

    test('RootDashboardContext can be constructed', () {
      const summary = RootSummaryData(
        totalIncome: 0,
        totalExpense: 0,
        totalSavings: 0,
        totalRefund: 0,
        totalFixedCost: 0,
        totalExpenseWithFixed: 0,
        netDisplay: 0,
        hasFixedCosts: false,
        topTransactions: <RootTransactionEntry>[],
        topFixedCosts: <RootFixedCostEntry>[],
      );

      const ctx = RootDashboardContext(
        accounts: [],
        transactionsByAccount: {},
        transactionAccountMap: {},
        allTransactions: <Transaction>[],
        summaryData: summary,
        allFixedCosts: <RootFixedCostEntry>[],
        orphanAccountNames: [],
        trackedAccountNames: [],
      );

      expect(ctx.accounts, isEmpty);
      expect(ctx.allTransactions, isEmpty);
      expect(ctx.summaryData.netDisplay, 0);
    });

    test('buildSummaryData treats savings expense-allocation as expense', () {
      final txs = <Transaction>[
        Transaction(
          id: 'income-1',
          type: TransactionType.income,
          description: 'salary',
          amount: 1000,
          date: DateTime(2026, 2),
        ),
        Transaction(
          id: 'save-asset',
          type: TransactionType.savings,
          description: 'asset saving',
          amount: 300,
          date: DateTime(2026, 2, 2),
          savingsAllocation: SavingsAllocation.assetIncrease,
        ),
        Transaction(
          id: 'save-expense',
          type: TransactionType.savings,
          description: 'expense-like saving',
          amount: 200,
          date: DateTime(2026, 2, 3),
          savingsAllocation: SavingsAllocation.expense,
        ),
      ];

      final summary = TopLevelStatsUtils.buildSummaryData(
        allTransactions: txs,
        transactionAccountMap: const {
          'income-1': 'A',
          'save-asset': 'A',
          'save-expense': 'A',
        },
        totalFixedCost: 0,
        fixedCostEntries: const <RootFixedCostEntry>[],
      );

      expect(summary.totalIncome, 1000);
      expect(summary.totalSavings, 300);
      expect(summary.totalExpense, 200);
      expect(summary.netDisplay, 800);
    });

    test('buildSummaryData includes savings-expense in top outflows', () {
      final txs = <Transaction>[
        Transaction(
          id: 'e1',
          type: TransactionType.expense,
          description: 'normal expense',
          amount: 100,
          date: DateTime(2026, 2, 2),
        ),
        Transaction(
          id: 's1',
          type: TransactionType.savings,
          description: 'saving as expense',
          amount: 250,
          date: DateTime(2026, 2, 3),
          savingsAllocation: SavingsAllocation.expense,
        ),
      ];

      final summary = TopLevelStatsUtils.buildSummaryData(
        allTransactions: txs,
        transactionAccountMap: const {'e1': 'A', 's1': 'A'},
        totalFixedCost: 0,
        fixedCostEntries: const <RootFixedCostEntry>[],
      );

      expect(summary.topTransactions.length, 2);
      expect(summary.topTransactions.first.transaction.id, 's1');
    });

    test('buildTopOutflowEntries excludes assetIncrease savings and maps account', () {
      final txs = <Transaction>[
        Transaction(
          id: 'expense-1',
          type: TransactionType.expense,
          description: 'expense',
          amount: 100,
          date: DateTime(2026, 2),
        ),
        Transaction(
          id: 'save-asset-1',
          type: TransactionType.savings,
          description: 'asset saving',
          amount: 500,
          date: DateTime(2026, 2, 2),
          savingsAllocation: SavingsAllocation.assetIncrease,
        ),
        Transaction(
          id: 'save-expense-1',
          type: TransactionType.savings,
          description: 'expense saving',
          amount: 300,
          date: DateTime(2026, 2, 3),
          savingsAllocation: SavingsAllocation.expense,
        ),
      ];

      final result = TopLevelStatsUtils.buildTopOutflowEntries(
        allTransactions: txs,
        transactionAccountMap: const {
          'expense-1': 'A',
          'save-asset-1': 'A',
          'save-expense-1': 'B',
        },
        limit: 10,
      );

      final ids = result.map((e) => e.transaction.id).toList();
      expect(ids, containsAll(<String>['expense-1', 'save-expense-1']));
      expect(ids, isNot(contains('save-asset-1')));

      final savingsExpenseEntry = result.firstWhere(
        (entry) => entry.transaction.id == 'save-expense-1',
      );
      expect(savingsExpenseEntry.accountName, 'B');
    });

    test('summary totals stay consistent with mixed flow matrix', () {
      final txs = <Transaction>[
        Transaction(
          id: 'income',
          type: TransactionType.income,
          description: 'income',
          amount: 1200,
          date: DateTime(2026),
        ),
        Transaction(
          id: 'expense',
          type: TransactionType.expense,
          description: 'expense',
          amount: 250,
          date: DateTime(2026, 2),
        ),
        Transaction(
          id: 'expense-refund-flag',
          type: TransactionType.expense,
          description: 'expense refund correction',
          amount: 80,
          date: DateTime(2026, 2, 2),
          isRefund: true,
        ),
        Transaction(
          id: 'savings-asset',
          type: TransactionType.savings,
          description: 'asset saving',
          amount: 300,
          date: DateTime(2026, 2, 3),
          savingsAllocation: SavingsAllocation.assetIncrease,
        ),
        Transaction(
          id: 'savings-expense',
          type: TransactionType.savings,
          description: 'expense saving',
          amount: 150,
          date: DateTime(2026, 2, 4),
          savingsAllocation: SavingsAllocation.expense,
        ),
        Transaction(
          id: 'refund',
          type: TransactionType.refund,
          description: 'refund',
          amount: 40,
          date: DateTime(2026, 2, 5),
        ),
      ];

      final summary = TopLevelStatsUtils.buildSummaryData(
        allTransactions: txs,
        transactionAccountMap: const {
          'income': 'A',
          'expense': 'A',
          'expense-refund-flag': 'A',
          'savings-asset': 'A',
          'savings-expense': 'A',
          'refund': 'A',
        },
        totalFixedCost: 60,
        fixedCostEntries: const <RootFixedCostEntry>[],
      );

      // expense: 250 - 80 + 150 = 320
      expect(summary.totalExpense, 320);
      expect(summary.totalSavings, 300);
      expect(summary.totalIncome, 1200);
      expect(summary.totalRefund, 40);
      expect(summary.totalExpenseWithFixed, 380);
      expect(summary.netDisplay, 820); // 1200 - 380
    });

    test('top outflow entries are strictly expense-like transactions', () {
      final txs = <Transaction>[
        Transaction(
          id: 'income-1',
          type: TransactionType.income,
          description: 'income',
          amount: 500,
          date: DateTime(2026),
        ),
        Transaction(
          id: 'refund-1',
          type: TransactionType.refund,
          description: 'refund',
          amount: 100,
          date: DateTime(2026, 2),
        ),
        Transaction(
          id: 'expense-1',
          type: TransactionType.expense,
          description: 'expense',
          amount: 200,
          date: DateTime(2026, 2, 2),
        ),
        Transaction(
          id: 'savings-expense-1',
          type: TransactionType.savings,
          description: 'savings as expense',
          amount: 90,
          date: DateTime(2026, 2, 3),
          savingsAllocation: SavingsAllocation.expense,
        ),
        Transaction(
          id: 'savings-asset-1',
          type: TransactionType.savings,
          description: 'savings as asset',
          amount: 999,
          date: DateTime(2026, 2, 4),
          savingsAllocation: SavingsAllocation.assetIncrease,
        ),
      ];

      final result = TopLevelStatsUtils.buildTopOutflowEntries(
        allTransactions: txs,
        transactionAccountMap: const {
          'income-1': 'X',
          'refund-1': 'X',
          'expense-1': 'X',
          'savings-expense-1': 'X',
          'savings-asset-1': 'X',
        },
        limit: 10,
      );

      final ids = result.map((e) => e.transaction.id).toSet();
      expect(ids, contains('expense-1'));
      expect(ids, contains('savings-expense-1'));
      expect(ids, isNot(contains('income-1')));
      expect(ids, isNot(contains('refund-1')));
      expect(ids, isNot(contains('savings-asset-1')));
    });
  });
}
