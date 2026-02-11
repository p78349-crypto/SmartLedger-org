// ignore_for_file: invalid_use_of_protected_member
part of 'account_stats_screen.dart';

/// 10년 뷰 + 차트 뷰 + 차트 셀렉터.
extension AccountStatsDecadeChart on _AccountStatsScreenState {
  Widget _buildDecadeView(List<Transaction> transactions, ThemeData theme) {
    const totalMonths = 120;
    final range = _rangeForMonths(totalMonths);
    final aggSummary =
        _tryCalculateRangeSummaryFromMonthlyAgg(range, totalMonths);
    final canUseAgg = aggSummary != null && _monthlyAggCache != null;

    final rangeTransactions = canUseAgg
        ? const <Transaction>[]
        : transactions
              .where((tx) =>
                  !tx.date.isBefore(range.start) &&
                  !tx.date.isAfter(range.end))
              .toList();

    final summary = aggSummary ??
        _calculateRangeSummary(rangeTransactions, totalMonths);

    final startYear = range.start.year;
    final endYear = range.end.year;

    final yearSummaries = <YearSummary>[];
    for (var year = startYear; year <= endYear; year++) {
      if (canUseAgg) {
        double total = 0;
        int count = 0;
        for (var month = 1; month <= 12; month++) {
          final dt = DateTime(year, month);
          if (dt.isBefore(range.start) || dt.isAfter(range.end)) continue;
          final ym = MonthlyAggCacheService.yearMonthOf(dt);
          final bucket = _monthlyAggCache!.months[ym];
          if (bucket == null) continue;
          total += bucket.amountForType(_currentType);
          count += bucket.countForType(_currentType);
        }
        if (_includeFixedCosts &&
            _fixedCosts.isNotEmpty &&
            _currentType == TransactionType.expense) {
          total += _fixedCostTotalForMonth(DateTime(year)) *
              _monthsInYearWithinRange(year, range.start, range.end);
        }
        yearSummaries.add(
            YearSummary(year: year, total: total, count: count));
        continue;
      }
      final yearTxs = rangeTransactions.where((tx) =>
          tx.date.year == year &&
          _shouldAggregateForType(tx, _currentType));
      var total = _sumAmounts(yearTxs);
      if (_includeFixedCosts &&
          _fixedCosts.isNotEmpty &&
          _currentType == TransactionType.expense) {
        total += _fixedCostTotalForMonth(DateTime(year)) *
            _monthsInYearWithinRange(year, range.start, range.end);
      }
      yearSummaries.add(YearSummary(
          year: year, total: total, count: yearTxs.length));
    }

    final filtered = _showEmptyYears
        ? yearSummaries
        : yearSummaries
              .where((s) => s.total != 0 || s.count != 0)
              .toList();
    final infoMsg = _showEmptyYears
        ? '모든 연도를 표시하는 중입니다.'
        : '거래가 있는 연도만 표시합니다.';
    final rangeLabel = _formatRangeLabel(range.start, range.end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildYearNavigator(theme,
            label: '$startYear년 ~ $endYear년'),
        const SizedBox(height: 8),
        Center(
          child: Text(rangeLabel,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ),
        const SizedBox(height: 16),
        StatsSummaryGrid(children: _buildSummaryCards(summary, theme)),
        const SizedBox(height: 24),
        Text('연도별 ${_typeLabel()}', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: Text(infoMsg,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ),
          TextButton(
            onPressed: () =>
                setState(() => _showEmptyYears = !_showEmptyYears),
            child: Text(
                _showEmptyYears ? '기록 없는 연도 숨기기' : '기록 없는 연도 표시'),
          ),
        ]),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                  '표시할 연도가 없습니다. '
                  '기록 없는 연도를 표시하려면 버튼을 눌러주세요.',
                  style: theme.textTheme.bodyMedium),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: filtered
                    .map((s) => ListTile(
                          title: Text('${s.year}년'),
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

  List<DateTime> _chartMonths() {
    return List.generate(12, (i) {
      final offset = 11 - i;
      return DateTime(
          _chartAnchorMonth.year, _chartAnchorMonth.month - offset);
    });
  }

  List<ChartPoint> _chartPointsForType(
    List<Transaction> transactions,
    TransactionType type,
    List<DateTime> months,
  ) {
    return months.map((month) {
      final monthTxs = transactions.where((tx) =>
          tx.type == type &&
          tx.date.year == month.year &&
          tx.date.month == month.month);
      var total = _sumAmounts(monthTxs);
      if (_includeFixedCosts &&
          _fixedCosts.isNotEmpty &&
          type == TransactionType.expense) {
        total += _fixedCostTotalForMonth(month);
      }
      return ChartPoint(month: month, total: total);
    }).toList();
  }

  Widget _buildChartView(
      List<Transaction> transactions, ThemeData theme) {
    final months = _chartMonths();
    final points =
        _chartPointsForType(transactions, _currentType, months);
    final maxValue = points.fold<double>(
        0, (prev, p) => p.total > prev ? p.total : prev);
    final hasData = points.any((p) => p.total > 0);
    final safeMax = maxValue == 0 ? 1.0 : maxValue;
    final rangeStart = months.first;
    final rangeEnd = months.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartNavigator(theme, rangeStart, rangeEnd),
        const SizedBox(height: 16),
        _buildChartDisplaySelector(),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 260,
              child: hasData
                  ? _buildChartForDisplay(
                      points, theme, safeMax, _currentType)
                  : _buildNoChartData(theme),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartDisplaySelector() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: ChartDisplayType.values
          .map((d) => ChoiceChip(
                label: Text(_chartDisplayLabel(d)),
                selected: _chartDisplay == d,
                onSelected: (sel) {
                  if (!sel) return;
                  setState(() => _chartDisplay = d);
                },
              ))
          .toList(),
    );
  }
}
