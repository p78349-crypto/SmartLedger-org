import '../utils/top_level_stats_utils.dart';
import '../utils/transaction_aggregation_utils.dart';
import '../models/transaction.dart';

class AccountAggregateSummary {
  const AccountAggregateSummary({
    required this.name,
    required this.income,
    required this.expense,
    required this.savings,
    required this.refund,
    required this.fixedCost,
  });

  final String name;
  final double income;
  final double expense;
  final double savings;
  final double refund;
  final double fixedCost;

  double get net => income + refund - expense - savings - fixedCost;
}

class RootAccountSummaryAggregationUtils {
  static List<AccountAggregateSummary> buildAccountAggregates(
    RootDashboardContext context,
  ) {
    final summaries = <AccountAggregateSummary>[];

    for (final accountName in context.trackedAccountNames) {
      final transactions = context.transactionsByAccount[accountName] ?? [];
      double income = 0;
      double expense = 0;
      double savings = 0;
      double refund = 0;

      for (final tx in transactions) {
        switch (tx.type) {
          case TransactionType.income:
            income += tx.amount;
            break;
          case TransactionType.expense:
            expense += TransactionAggregationUtils.outflowAmount(tx);
            break;
          case TransactionType.savings:
            if (TransactionAggregationUtils.isSavingsCountedAsExpense(tx)) {
              expense += TransactionAggregationUtils.outflowAmount(tx);
            } else {
              savings += tx.amount.abs();
            }
            break;
          case TransactionType.refund:
            refund += tx.amount;
            break;
        }
      }

      final fixedCost = context.allFixedCosts
          .where((fc) => fc.accountName == accountName)
          .fold<double>(0, (sum, fc) => sum + fc.cost.amount);

      summaries.add(
        AccountAggregateSummary(
          name: accountName,
          income: income,
          expense: expense,
          savings: savings,
          refund: refund,
          fixedCost: fixedCost,
        ),
      );
    }

    summaries.sort((a, b) => b.net.compareTo(a.net));
    return summaries;
  }
}
