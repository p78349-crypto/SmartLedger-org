part of 'account_stats_screen.dart';

/// 요약 계산 및 카드 빌드.
extension AccountStatsSummary on _AccountStatsScreenState {
  SummaryTotals _calculateMonthlySummary(
    List<Transaction> monthlyTransactions,
    DateTime month,
  ) {
    double income = 0, expenseOnly = 0, savings = 0;
    for (final tx in monthlyTransactions) {
      switch (tx.type) {
        case TransactionType.income:
        case TransactionType.refund:
          income += tx.amount;
          break;
        case TransactionType.expense:
          expenseOnly += tx.amount;
          break;
        case TransactionType.savings:
          savings += tx.amount;
          if (_isSavingsCountedAsExpense(tx)) expenseOnly += tx.amount;
          break;
      }
    }
    final fixedCost = _fixedCostTotalForMonth(month);
    final hasFixed = _fixedCosts.isNotEmpty;
    final includeFixed = hasFixed && _includeFixedCosts;
    final expenseDisplay = expenseOnly + (includeFixed ? fixedCost : 0.0);
    final net = income - expenseDisplay;
    final expenseTitle = includeFixed ? '지출(고정비 포함)' : '지출';
    final fixedCostTitle = hasFixed && !_includeFixedCosts
        ? '고정비용(미포함)'
        : '고정비용';
    return SummaryTotals(
      income: income,
      expense: expenseOnly,
      savings: savings,
      fixedCost: fixedCost,
      expenseDisplay: expenseDisplay,
      net: net,
      expenseTitle: expenseTitle,
      fixedCostTitle: fixedCostTitle,
    );
  }

  SummaryTotals _calculateYearlySummary(
    List<Transaction> yearlyTransactions,
    int year,
  ) {
    double income = 0, expenseOnly = 0, savings = 0;
    for (final tx in yearlyTransactions) {
      switch (tx.type) {
        case TransactionType.income:
        case TransactionType.refund:
          income += tx.amount;
          break;
        case TransactionType.expense:
          expenseOnly += tx.amount;
          break;
        case TransactionType.savings:
          savings += tx.amount;
          if (_isSavingsCountedAsExpense(tx)) expenseOnly += tx.amount;
          break;
      }
    }
    final fixedMonthly = _fixedCostTotalForMonth(DateTime(year));
    final fixedYearly = _fixedCosts.isEmpty ? 0.0 : fixedMonthly * 12;
    final hasFixed = _fixedCosts.isNotEmpty;
    final includeFixed = hasFixed && _includeFixedCosts;
    final expenseDisplay = expenseOnly + (includeFixed ? fixedYearly : 0.0);
    final net = income - expenseDisplay;
    final expenseTitle = includeFixed ? '지출(고정비 포함)' : '지출';
    final fixedCostTitle = hasFixed && !_includeFixedCosts
        ? '연간 고정비용(미포함)'
        : '연간 고정비용';
    return SummaryTotals(
      income: income,
      expense: expenseOnly,
      savings: savings,
      fixedCost: fixedYearly,
      expenseDisplay: expenseDisplay,
      net: net,
      expenseTitle: expenseTitle,
      fixedCostTitle: fixedCostTitle,
    );
  }

  SummaryTotals _calculateRangeSummary(
    List<Transaction> rangeTransactions,
    int months,
  ) {
    double income = 0, expenseOnly = 0, savings = 0;
    for (final tx in rangeTransactions) {
      switch (tx.type) {
        case TransactionType.income:
        case TransactionType.refund:
          income += tx.amount;
          break;
        case TransactionType.expense:
          expenseOnly += tx.amount;
          break;
        case TransactionType.savings:
          savings += tx.amount;
          if (_isSavingsCountedAsExpense(tx)) expenseOnly += tx.amount;
          break;
      }
    }
    final monthlyFixed = _fixedCostTotalForMonth(_currentMonth);
    final fixedTotal = _fixedCosts.isEmpty ? 0.0 : monthlyFixed * months;
    final hasFixed = _fixedCosts.isNotEmpty;
    final includeFixed = hasFixed && _includeFixedCosts;
    final expenseDisplay = expenseOnly + (includeFixed ? fixedTotal : 0.0);
    final net = income - expenseDisplay;
    final baseTitle = _fixedCostTitleForMonths(months);
    final fixedCostTitle = hasFixed && !_includeFixedCosts
        ? '$baseTitle(미포함)'
        : baseTitle;
    final expenseTitle = includeFixed ? '지출(고정비 포함)' : '지출';
    return SummaryTotals(
      income: income,
      expense: expenseOnly,
      savings: savings,
      fixedCost: fixedTotal,
      expenseDisplay: expenseDisplay,
      net: net,
      expenseTitle: expenseTitle,
      fixedCostTitle: fixedCostTitle,
    );
  }

  List<Transaction> _transactionsForMonth(
    List<Transaction> transactions,
    DateTime month,
  ) => transactions
      .where((tx) => tx.date.year == month.year && tx.date.month == month.month)
      .toList();

  DateTimeRange _rangeForMonths(int months) {
    final start = DateTime(
      _currentMonth.year,
      _currentMonth.month - (months - 1),
    );
    final end = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    return DateTimeRange(start: start, end: end);
  }

  String _formatRangeLabel(DateTime start, DateTime end) =>
      '${_dateFormat.format(start)} ~ ${_dateFormat.format(end)}';

  int _monthsInYearWithinRange(
    int year,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    var count = 0;
    for (var month = 1; month <= 12; month++) {
      final monthStart = DateTime(year, month);
      final monthEnd = DateTime(year, month + 1, 0);
      if (!monthEnd.isBefore(rangeStart) && !monthStart.isAfter(rangeEnd)) {
        count += 1;
      }
    }
    return count;
  }

  String _fixedCostTitleForMonths(int months) {
    switch (months) {
      case 1:
        return '고정비용';
      case 3:
        return '3개월 고정비용';
      case 6:
        return '6개월 고정비용';
      case 12:
        return '연간 고정비용';
      case 120:
        return '10년 고정비용';
      default:
        return '고정비용';
    }
  }

  List<StatsSummaryCard> _buildSummaryCards(
    SummaryTotals summary,
    ThemeData theme,
  ) {
    final cards = <StatsSummaryCard>[
      StatsSummaryCard(
        icon: Icons.trending_up,
        title: '수입',
        value: _formatCurrency(summary.income),
        valueColor: theme.colorScheme.primary,
      ),
      StatsSummaryCard(
        icon: Icons.savings,
        title: AppStrings.transactionTypeSavings,
        value: _formatAmountByType(summary.savings, TransactionType.savings),
        valueColor: Colors.amber[800],
      ),
      StatsSummaryCard(
        icon: Icons.trending_down,
        title: summary.expenseTitle,
        value: _formatAmountByType(
          summary.expenseDisplay,
          TransactionType.expense,
        ),
        valueColor: theme.colorScheme.error,
      ),
    ];
    if (_fixedCosts.isNotEmpty) {
      cards.add(
        StatsSummaryCard(
          icon: Icons.receipt_long,
          title: summary.fixedCostTitle,
          value: _formatAmountByType(
            summary.fixedCost,
            TransactionType.expense,
          ),
          valueColor: theme.colorScheme.secondary,
        ),
      );
    }
    final remaining = summary.income - summary.expenseDisplay;
    cards.add(
      StatsSummaryCard(
        icon: Icons.savings_outlined,
        title: '여유자금',
        value: _formatCurrency(remaining, includeSign: true),
        valueColor: remaining >= 0 ? Colors.green : Colors.red,
      ),
    );
    return cards;
  }
}
