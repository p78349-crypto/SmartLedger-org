part of 'account_stats_screen.dart';

/// 연간(Year) 통계 뷰.
extension AccountStatsYearView on _AccountStatsScreenState {
  Widget _buildYearView(List<Transaction> transactions, ThemeData theme) {
    final cache = _monthlyAggCache;
    final canUseAgg = cache != null && cache.months.isNotEmpty;

    final summary = canUseAgg
        ? () {
            double income = 0, expenseOnly = 0, savings = 0;
            for (var month = 1; month <= 12; month++) {
              final ym = MonthlyAggCacheService.yearMonthOf(
                DateTime(_currentYear, month),
              );
              final bucket = cache.months[ym];
              if (bucket == null) continue;
              income += bucket.incomeAmount;
              expenseOnly += bucket.expenseAggAmount;
              savings += bucket.savingsTotalAmount;
            }
            final fixedMonthly = _fixedCostTotalForMonth(
              DateTime(_currentYear),
            );
            final fixedYearly = _fixedCosts.isEmpty ? 0.0 : fixedMonthly * 12;
            final hasFixed = _fixedCosts.isNotEmpty;
            final includeFixed = hasFixed && _includeFixedCosts;
            final expenseDisplay =
                expenseOnly + (includeFixed ? fixedYearly : 0.0);
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
          }()
        : _calculateYearlySummary(transactions, _currentYear);

    final fixedMonthlyTotal = _fixedCostTotalForMonth(DateTime(_currentYear));

    final monthSummaries = List.generate(12, (index) {
      final month = index + 1;
      if (canUseAgg) {
        final ym = MonthlyAggCacheService.yearMonthOf(
          DateTime(_currentYear, month),
        );
        final bucket = cache.months[ym];
        final baseTotal = bucket?.amountForType(_currentType) ?? 0.0;
        final addFixed =
            _includeFixedCosts &&
            _fixedCosts.isNotEmpty &&
            _currentType == TransactionType.expense;
        final total = baseTotal + (addFixed ? fixedMonthlyTotal : 0.0);
        final count = bucket?.countForType(_currentType) ?? 0;
        return MonthlySummary(
          month: DateTime(_currentYear, month),
          total: total,
          count: count,
        );
      }
      final yearlyTxs = transactions.where(
        (tx) => tx.date.year == _currentYear,
      );
      final monthTxs = yearlyTxs.where(
        (tx) =>
            _shouldAggregateForType(tx, _currentType) && tx.date.month == month,
      );
      var total = _sumAmounts(monthTxs);
      if (_includeFixedCosts &&
          _fixedCosts.isNotEmpty &&
          _currentType == TransactionType.expense) {
        total += fixedMonthlyTotal;
      }
      return MonthlySummary(
        month: DateTime(_currentYear, month),
        total: total,
        count: monthTxs.length,
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildYearNavigator(theme),
        const SizedBox(height: 16),
        StatsSummaryGrid(children: _buildSummaryCards(summary, theme)),
        const SizedBox(height: 24),
        Text('월별 ${_typeLabel()}', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: monthSummaries
                  .map(
                    (s) => ListTile(
                      title: Text(_shortMonthFormat.format(s.month)),
                      subtitle: Text('${s.count}건'),
                      trailing: Text(
                        _formatAmountByType(s.total, _currentType),
                        style: TextStyle(color: _typeColor(theme)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        if (_fixedCosts.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildFixedCostSection(theme, annual: true),
        ],
      ],
    );
  }
}
