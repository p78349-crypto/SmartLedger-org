import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/account.dart';
import 'package:smart_ledger/models/fixed_cost.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/root_account_summary_aggregation_utils.dart';
import 'package:smart_ledger/utils/top_level_stats_utils.dart';
import 'package:smart_ledger/widgets/root_summary_card.dart';

void main() {
  group('RootAccountSummaryAggregationUtils', () {
    Transaction tx({
      required String id,
      required TransactionType type,
      required double amount,
      required DateTime date,
      SavingsAllocation? savingsAllocation,
      bool isRefund = false,
    }) {
      return Transaction(
        id: id,
        type: type,
        description: id,
        amount: amount,
        date: date,
        savingsAllocation: savingsAllocation,
        isRefund: isRefund,
      );
    }

    RootDashboardContext contextWithData() {
      final accountA = Account(name: 'A', createdAt: DateTime(2026));
      final accountB = Account(name: 'B', createdAt: DateTime(2026, 2));

      final txA = <Transaction>[
        tx(
          id: 'a-income',
          type: TransactionType.income,
          amount: 1000,
          date: DateTime(2026, 2),
        ),
        tx(
          id: 'a-expense',
          type: TransactionType.expense,
          amount: 300,
          date: DateTime(2026, 2, 2),
        ),
        tx(
          id: 'a-saving-asset',
          type: TransactionType.savings,
          amount: 120,
          savingsAllocation: SavingsAllocation.assetIncrease,
          date: DateTime(2026, 2, 3),
        ),
        tx(
          id: 'a-saving-expense',
          type: TransactionType.savings,
          amount: 50,
          savingsAllocation: SavingsAllocation.expense,
          date: DateTime(2026, 2, 4),
        ),
        tx(
          id: 'a-refund',
          type: TransactionType.refund,
          amount: 20,
          date: DateTime(2026, 2, 5),
        ),
      ];

      final txB = <Transaction>[
        tx(
          id: 'b-income',
          type: TransactionType.income,
          amount: 200,
          date: DateTime(2026, 2),
        ),
      ];

      final fixedEntries = <RootFixedCostEntry>[
        RootFixedCostEntry(
          accountName: 'A',
          cost: FixedCost(id: 'fc-1', name: 'rent', amount: 100),
        ),
      ];

      return RootDashboardContext(
        accounts: [accountA, accountB],
        transactionsByAccount: {'A': txA, 'B': txB},
        transactionAccountMap: {
          for (final t in [...txA, ...txB])
            t.id: t.id.startsWith('a-') ? 'A' : 'B',
        },
        allTransactions: [...txA, ...txB],
        summaryData: const RootSummaryData(
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
        ),
        allFixedCosts: fixedEntries,
        orphanAccountNames: const [],
        trackedAccountNames: const ['A', 'B'],
      );
    }

    test('buildAccountAggregates computes expected totals per account', () {
      final context = contextWithData();

      final result = RootAccountSummaryAggregationUtils.buildAccountAggregates(
        context,
      );

      final a = result.firstWhere((e) => e.name == 'A');
      final b = result.firstWhere((e) => e.name == 'B');

      expect(a.income, 1000);
      expect(a.expense, 350); // expense 300 + savings(expense) 50
      expect(a.savings, 120);
      expect(a.refund, 20);
      expect(a.fixedCost, 100);
      expect(a.net, 450); // 1000 + 20 - 350 - 120 - 100

      expect(b.income, 200);
      expect(b.expense, 0);
      expect(b.savings, 0);
      expect(b.refund, 0);
      expect(b.fixedCost, 0);
      expect(b.net, 200);
    });

    test('buildAccountAggregates sorts by net descending', () {
      final context = contextWithData();
      final result = RootAccountSummaryAggregationUtils.buildAccountAggregates(
        context,
      );

      expect(result.first.name, 'A');
      expect(result.last.name, 'B');
      expect(result.first.net, greaterThan(result.last.net));
    });
  });
}
