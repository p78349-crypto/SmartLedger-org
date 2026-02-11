part of 'chart_detail_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Build UI for [_ChartDetailScreenState].
extension ChartDetailScreenBuild on _ChartDetailScreenState {
  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('$_typeLabel 그래프')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final chartData = _getChartData();
    final maxValue = chartData.fold<double>(
      0,
      (max, entry) => entry.value > max ? entry.value : max,
    );
    final hasData = chartData.any((entry) => entry.value > 0);
    final safeMax = maxValue == 0 ? 1.0 : maxValue;

    return Scaffold(
      appBar: AppBar(
        title: Text('$_typeLabel 그래프'),
        actions: [
          if (_fixedCosts.isNotEmpty &&
              widget.transactionType == TransactionType.expense)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text(
                  StatsLabels.fixedCostLabel,
                  style: TextStyle(fontSize: 12),
                ),
                showCheckmark: false,
                selected: _includeFixedCosts,
                onSelected: (selected) {
                  setState(() => _includeFixedCosts = selected);
                },
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 기간 네비게이터
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousPeriod,
                ),
                Text(
                  chartData.isEmpty
                      ? '데이터 없음'
                      : '${_rangeMonthFormat.format(chartData.first.key)} ~ '
                            '${_rangeMonthFormat.format(chartData.last.key)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextPeriod,
                ),
              ],
            ),
          ),

          // 차트 타입 선택
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('막대'),
                  selected: _chartType == ChartType.bar,
                  onSelected: (selected) {
                    if (selected) setState(() => _chartType = ChartType.bar);
                  },
                ),
                ChoiceChip(
                  label: const Text('선'),
                  selected: _chartType == ChartType.line,
                  onSelected: (selected) {
                    if (selected) setState(() => _chartType = ChartType.line);
                  },
                ),
                ChoiceChip(
                  label: const Text('파이'),
                  selected: _chartType == ChartType.pie,
                  onSelected: (selected) {
                    if (selected) setState(() => _chartType = ChartType.pie);
                  },
                ),
              ],
            ),
          ),

          // 차트
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 300,
                        child: hasData
                            ? _buildChart(
                                chartData,
                                theme,
                                safeMax,
                                _getTypeColor(theme),
                              )
                            : Center(
                                child: Text(
                                  '이 기간에 $_typeLabel 데이터가 없습니다.',
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: chartData
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        _rangeMonthFormat.format(entry.key),
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: chartData.isEmpty
                                              ? 0
                                              : entry.value / safeMax,
                                          backgroundColor: theme
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          color: _getTypeColor(theme),
                                          minHeight: 8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${_currencyFormat.format(entry.value)}원',
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
