import 'package:smart_ledger/models/account.dart';
import 'package:smart_ledger/models/fixed_cost.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/services/fixed_cost_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/widgets/root_summary_card.dart';

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

    double totalIncome = 0;
    double totalExpense = 0;
    double totalSavings = 0;
    double totalRefund = 0;
    final outflows = <Transaction>[];

    double normalizedExpenseAmount(Transaction tx) {
      if (tx.type != TransactionType.expense) return 0;
      final amount = tx.amount.abs();
      return tx.isRefund ? -amount : amount;
    }

    for (final tx in allTransactions) {
      switch (tx.type) {
        case TransactionType.income:
          totalIncome += tx.amount;
          break;
        case TransactionType.expense:
          final expense = normalizedExpenseAmount(tx);
          totalExpense += expense;
          if (expense > 0) outflows.add(tx);
          break;
        case TransactionType.savings:
          totalSavings += tx.amount.abs();
          break;
        case TransactionType.refund:
          totalRefund += tx.amount;
          break;
      }
    }

    outflows.sort((a, b) {
      final d = b.date.compareTo(a.date);
      if (d != 0) return d;
      return b.amount.abs().compareTo(a.amount.abs());
    });

    final topTransactions = outflows.take(5).map((tx) {
      final accountName = transactionAccountMap[tx.id] ?? '미분류';
      return RootTransactionEntry(transaction: tx, accountName: accountName);
    }).toList();

    final hasFixedCosts = totalFixedCost > 0;

    final summaryData = RootSummaryData(
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

