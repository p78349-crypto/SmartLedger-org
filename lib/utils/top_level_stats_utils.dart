import '../models/account.dart';
import '../models/fixed_cost.dart';
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../services/fixed_cost_service.dart';
import '../services/transaction_service.dart';
import '../utils/transaction_aggregation_utils.dart';
import '../widgets/root_summary_card.dart';

/// RootDashboardContext groups raw data and precomputed summary for the UI.
class RootDashboardContext {
  const RootDashboardContext({
    required this.accounts,
    required this.transactionsByAccount,
    required this.transactionAccountMap,
    required this.allTransactions,
    required this.summaryData,
    required this.allFixedCosts,
    required this.orphanAccountNames,
    required this.trackedAccountNames,
  });

  final List<Account> accounts;
  final Map<String, List<Transaction>> transactionsByAccount;
  final Map<String, String> transactionAccountMap;
  final List<Transaction> allTransactions;
  // Type imported from root_summary_card.dart.
  final RootSummaryData summaryData;
  final List<RootFixedCostEntry> allFixedCosts;
  final List<String> orphanAccountNames;
  final List<String> trackedAccountNames;
}

class TopLevelStatsUtils {
  static List<RootTransactionEntry> buildTopOutflowEntries({
    required List<Transaction> allTransactions,
    required Map<String, String> transactionAccountMap,
    int limit = 5,
  }) {
    final outflows = allTransactions
        .where(TransactionAggregationUtils.isExpenseLikeOutflow)
        .toList();

    outflows.sort((a, b) {
      final d = b.date.compareTo(a.date);
      if (d != 0) return d;
      return TransactionAggregationUtils.outflowAmount(
        b,
      ).compareTo(TransactionAggregationUtils.outflowAmount(a));
    });

    return outflows.take(limit).map((tx) {
      final accountName = transactionAccountMap[tx.id] ?? '미분류';
      return RootTransactionEntry(transaction: tx, accountName: accountName);
    }).toList();
  }

  static RootSummaryData buildSummaryData({
    required List<Transaction> allTransactions,
    required Map<String, String> transactionAccountMap,
    required double totalFixedCost,
    required List<RootFixedCostEntry> fixedCostEntries,
  }) {
    double totalIncome = 0;
    double totalExpense = 0;
    double totalSavings = 0;
    double totalRefund = 0;
    for (final tx in allTransactions) {
      switch (tx.type) {
        case TransactionType.income:
          totalIncome += tx.amount;
          break;
        case TransactionType.expense:
          final expense = TransactionAggregationUtils.outflowAmount(tx);
          totalExpense += expense;
          break;
        case TransactionType.savings:
          if (TransactionAggregationUtils.isSavingsCountedAsExpense(tx)) {
            totalExpense += TransactionAggregationUtils.outflowAmount(tx);
          } else {
            totalSavings += tx.amount.abs();
          }
          break;
        case TransactionType.refund:
          totalRefund += tx.amount;
          break;
      }
    }

    final topTransactions = buildTopOutflowEntries(
      allTransactions: allTransactions,
      transactionAccountMap: transactionAccountMap,
    );

    final hasFixedCosts = totalFixedCost > 0;

    return RootSummaryData(
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalSavings: totalSavings,
      totalRefund: totalRefund,
      totalFixedCost: totalFixedCost,
      totalExpenseWithFixed: hasFixedCosts
          ? totalExpense + totalFixedCost
          : totalExpense,
      netDisplay:
          totalIncome -
          (hasFixedCosts ? totalExpense + totalFixedCost : totalExpense),
      hasFixedCosts: hasFixedCosts,
      topTransactions: topTransactions,
      topFixedCosts: hasFixedCosts
          ? fixedCostEntries.take(5).toList()
          : const <RootFixedCostEntry>[],
    );
  }

  static RootDashboardContext buildDashboardContext() {
    final accountService = AccountService();
    final transactionService = TransactionService();
    final fixedCostService = FixedCostService();

    final accounts = List<Account>.from(accountService.accounts);
    final orderedAccountNames = accounts
        .map((account) => account.name)
        .toList();
    final knownAccountNames = orderedAccountNames.toSet();

    final additionalAccountNames =
        <String>{
          ...transactionService.getAllAccountNames(),
          ...fixedCostService.getTrackedAccountNames(),
        }..removeWhere(
          (name) => name.trim().isEmpty || knownAccountNames.contains(name),
        );

    final aggregatedAccountNames = <String>[
      ...orderedAccountNames,
      ...additionalAccountNames,
    ];

    final transactionsByAccount = <String, List<Transaction>>{};
    final transactionAccountMap = <String, String>{};
    final allTransactions = <Transaction>[];
    final fixedCostEntries = <RootFixedCostEntry>[];
    final effectiveAccountNames = <String>[];
    final orphanAccountNames = <String>[];

    double totalFixedCost = 0;

    for (final accountName in aggregatedAccountNames) {
      final transactions = List<Transaction>.from(
        transactionService.getTransactions(accountName),
      );
      final fixedCosts = List<FixedCost>.from(
        fixedCostService.getFixedCosts(accountName),
      );

      final hasExplicitAccount = knownAccountNames.contains(accountName);
      final hasData = transactions.isNotEmpty || fixedCosts.isNotEmpty;

      if (!hasExplicitAccount && !hasData) continue;

      if (!hasExplicitAccount) orphanAccountNames.add(accountName);

      transactionsByAccount[accountName] = transactions;
      for (final tx in transactions) {
        transactionAccountMap[tx.id] = accountName;
      }
      allTransactions.addAll(transactions);

      for (final cost in fixedCosts) {
        totalFixedCost += cost.amount;
        fixedCostEntries.add(
          RootFixedCostEntry(cost: cost, accountName: accountName),
        );
      }

      effectiveAccountNames.add(accountName);
    }

    final summaryData = buildSummaryData(
      allTransactions: allTransactions,
      transactionAccountMap: transactionAccountMap,
      totalFixedCost: totalFixedCost,
      fixedCostEntries: fixedCostEntries,
    );

    return RootDashboardContext(
      accounts: accounts,
      transactionsByAccount: transactionsByAccount,
      transactionAccountMap: transactionAccountMap,
      allTransactions: allTransactions,
      summaryData: summaryData,
      allFixedCosts: fixedCostEntries,
      orphanAccountNames: orphanAccountNames,
      trackedAccountNames: effectiveAccountNames,
    );
  }
}
