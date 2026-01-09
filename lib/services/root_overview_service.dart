import '../models/account.dart';
import '../models/asset.dart';
import '../models/fixed_cost.dart';
import '../models/transaction.dart';
import 'account_service.dart';
import 'asset_service.dart';
import 'fixed_cost_service.dart';
import 'transaction_service.dart';

class AccountFinancialOverview {
  final String accountName;
  final double totalAssets;
  final double totalFixedCosts;
  final double monthlyIncome;
  final double monthlyExpense;
  final int transactionCount;
  final DateTime? latestTransactionDate;

  const AccountFinancialOverview({
    required this.accountName,
    required this.totalAssets,
    required this.totalFixedCosts,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.transactionCount,
    required this.latestTransactionDate,
  });

  double get monthlyNetCashFlow => monthlyIncome - monthlyExpense;
}

class RootFinancialOverview {
  final DateTime referenceMonth;
  final double totalAssets;
  final double totalFixedCosts;
  final double totalMonthlyIncome;
  final double totalMonthlyExpense;
  final List<AccountFinancialOverview> accountSummaries;

  const RootFinancialOverview({
    required this.referenceMonth,
    required this.totalAssets,
    required this.totalFixedCosts,
    required this.totalMonthlyIncome,
    required this.totalMonthlyExpense,
    required this.accountSummaries,
  });

  double get totalMonthlyNetCashFlow =>
      totalMonthlyIncome - totalMonthlyExpense;
  int get accountCount => accountSummaries.length;
}

class RootOverviewService {
  Future<RootFinancialOverview> buildOverview({DateTime? referenceDate}) async {
    final target = referenceDate ?? DateTime.now();
    final monthAnchor = DateTime(target.year, target.month);

    await Future.wait([
      AccountService().loadAccounts(),
      TransactionService().loadTransactions(),
      AssetService().loadAssets(),
      FixedCostService().loadFixedCosts(),
    ]);

    final orderedAccounts = List<Account>.from(AccountService().accounts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final orderedAccountNames = orderedAccounts
        .map((account) => account.name)
        .toList();

    final extraAccountNames = <String>{
      ...TransactionService().getAllAccountNames(),
      ...AssetService().getTrackedAccountNames(),
      ...FixedCostService().getTrackedAccountNames(),
    }..removeWhere(orderedAccountNames.contains);

    final accountNames = <String>[
      ...orderedAccountNames,
      ...extraAccountNames.toList()..sort(),
    ];

    final summaries = <AccountFinancialOverview>[];
    for (final accountName in accountNames) {
      final transactions = TransactionService().getTransactions(accountName);
      final assets = AssetService().getAssets(accountName);
      final fixedCosts = FixedCostService().getFixedCosts(accountName);

      final monthlyIncome = _sumMonthlyTransactions(
        transactions,
        monthAnchor,
        const [TransactionType.income],
      );
      final monthlyExpense = _sumMonthlyTransactions(
        transactions,
        monthAnchor,
        const [TransactionType.expense, TransactionType.savings],
      );
      final totalAssets = _sumAssets(assets);
      final totalFixedCosts = _sumFixedCosts(fixedCosts);
      final latestTransactionDate = _latestTransactionDate(transactions);

      summaries.add(
        AccountFinancialOverview(
          accountName: accountName,
          totalAssets: totalAssets,
          totalFixedCosts: totalFixedCosts,
          monthlyIncome: monthlyIncome,
          monthlyExpense: monthlyExpense,
          transactionCount: transactions.length,
          latestTransactionDate: latestTransactionDate,
        ),
      );
    }

    final totalAssets = summaries.fold<double>(
      0,
      (sum, s) => sum + s.totalAssets,
    );
    final totalFixedCosts = summaries.fold<double>(
      0,
      (sum, s) => sum + s.totalFixedCosts,
    );
    final totalMonthlyIncome = summaries.fold<double>(
      0,
      (sum, s) => sum + s.monthlyIncome,
    );
    final totalMonthlyExpense = summaries.fold<double>(
      0,
      (sum, s) => sum + s.monthlyExpense,
    );

    return RootFinancialOverview(
      referenceMonth: monthAnchor,
      totalAssets: totalAssets,
      totalFixedCosts: totalFixedCosts,
      totalMonthlyIncome: totalMonthlyIncome,
      totalMonthlyExpense: totalMonthlyExpense,
      accountSummaries: summaries,
    );
  }

  double _sumMonthlyTransactions(
    List<Transaction> transactions,
    DateTime monthAnchor,
    Iterable<TransactionType> types,
  ) {
    final typeSet = types.toSet();
    return transactions
        .where(
          (t) => typeSet.contains(t.type) && _isSameMonth(t.date, monthAnchor),
        )
        .fold<double>(0, (sum, t) => sum + t.amount);
  }

  bool _isSameMonth(DateTime date, DateTime anchor) {
    return date.year == anchor.year && date.month == anchor.month;
  }

  double _sumAssets(List<Asset> assets) {
    return assets.fold<double>(0, (sum, asset) => sum + asset.amount);
  }

  double _sumFixedCosts(List<FixedCost> costs) {
    return costs.fold<double>(0, (sum, cost) => sum + cost.amount);
  }

  DateTime? _latestTransactionDate(List<Transaction> transactions) {
    if (transactions.isEmpty) {
      return null;
    }
    DateTime latest = transactions.first.date;
    for (final transaction in transactions.skip(1)) {
      if (transaction.date.isAfter(latest)) {
        latest = transaction.date;
      }
    }
    return latest;
  }
}
