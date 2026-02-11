part of 'account_stats_screen.dart';

/// 분기/반기 뷰 + 일별 타일.
extension AccountStatsMultiMonth on _AccountStatsScreenState {
  Widget _buildMultiMonthView(
    List<Transaction> transactions, ThemeData theme, int months,
  ) {
    final range = _rangeForMonths(months);
    final aggSummary =
        _tryCalculateRangeSummaryFromMonthlyAgg(range, months);
    final canUseAgg = aggSummary != null && _monthlyAggCache != null;

    final summary = aggSummary ??
        (() {
          final rangeTransactions = transactions
              .where((tx) =>
                  !tx.date.isBefore(range.start) &&
                  !tx.date.isAfter(range.end))
              .toList();
          return _calculateRangeSummary(rangeTransactions, months);
        })();

    final monthSummaries = canUseAgg
        ? List.generate(months, (index) {
            final monthDate = DateTime(
                _currentMonth.year, _currentMonth.month - index);
            final ym = MonthlyAggCacheService.yearMonthOf(monthDate);
            final bucket = _monthlyAggCache!.months[ym];
            final baseTotal =
                bucket?.amountForType(_currentType) ?? 0.0;
            final baseCount =
                bucket?.countForType(_currentType) ?? 0;
            var total = baseTotal;
            if (_includeFixedCosts &&
                _fixedCosts.isNotEmpty &&
                _currentType == TransactionType.expense) {
              total += _fixedCostTotalForMonth(monthDate);
            }
            return MonthlySummary(
                month: DateTime(monthDate.year, monthDate.month),
                total: total,
                count: baseCount);
          }).reversed.toList()
        : () {
            final rangeTransactions = transactions
                .where((tx) =>
                    !tx.date.isBefore(range.start) &&
                    !tx.date.isAfter(range.end))
                .toList();
            return List.generate(months, (index) {
              final monthDate = DateTime(
                  _currentMonth.year, _currentMonth.month - index);
              final monthTransactions = rangeTransactions.where((tx) =>
                  tx.date.year == monthDate.year &&
                  tx.date.month == monthDate.month &&
                  _shouldAggregateForType(tx, _currentType));
              var total = _sumAmounts(monthTransactions);
              if (_includeFixedCosts &&
                  _fixedCosts.isNotEmpty &&
                  _currentType == TransactionType.expense) {
                total += _fixedCostTotalForMonth(monthDate);
              }
              return MonthlySummary(
                  month: DateTime(monthDate.year, monthDate.month),
                  total: total,
                  count: monthTransactions.length);
            }).reversed.toList();
          }();

    final rangeLabel = _formatRangeLabel(range.start, range.end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthNavigator(theme),
        const SizedBox(height: 8),
        Center(
          child: Text(rangeLabel,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ),
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
                  .map((s) => ListTile(
                        title: Text(_shortMonthFormat.format(s.month)),
                        subtitle: Text('${s.count}건'),
                        trailing: Text(
                          _formatAmountByType(s.total, _currentType),
                          style: TextStyle(color: _typeColor(theme))),
                      ))
                  .toList(),
            ),
          ),
        ),
        if (_fixedCosts.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildFixedCostSection(theme),
        ],
      ],
    );
  }

  Widget _buildDailyTile(
    DateTime day, List<Transaction> transactions, ThemeData theme,
  ) {
    final scheme = theme.colorScheme;
    final total = _sumAmounts(transactions);
    final typeColor = _typeColor(theme);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          title: Text(_dayLabelFormat.format(day),
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text(
            '합계 ${_formatAmountByType(total, _currentType)}',
            style: TextStyle(
                color: typeColor,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
          children: [
            const Divider(height: 1, indent: 20, endIndent: 20),
            ...transactions.map((tx) => ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 24),
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _colorForTransaction(tx.type, theme)
                          .withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                    child: Icon(_iconForType(tx.type),
                        size: 16,
                        color: _colorForTransaction(tx.type, theme)),
                  ),
                  title: Text(tx.description,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500)),
                  subtitle: Text(_dateFormat.format(tx.date),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant)),
                  trailing: Text(_formatSignedAmount(tx),
                      style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              _colorForTransaction(tx.type, theme))),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
