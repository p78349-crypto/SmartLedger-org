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
  });
}
