part of 'income_split_status_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension IncomeSplitChartModal on _IncomeSplitStatusScreenState {
  void openIncomeSplitChart(IncomeSplit split, double totalExpense) {
    final scheme = Theme.of(context).colorScheme;
    final data = _splitAllocations(
      split,
      totalExpense,
    ).where((entry) => entry.planned > 0).toList();

    if (data.isEmpty) {
      if (!mounted) return;
      SnackbarUtils.showInfo(context, '표시할 수입 배분 데이터가 없습니다.');
      return;
    }

    final totalPlanned = data.fold<double>(
      0,
      (sum, item) => sum + item.planned,
    );
    final totalActual = data.fold<double>(0, (sum, item) => sum + item.actual);
    final totalPlannedLabel = CurrencyFormatter.format(totalPlanned);
    final totalActualLabel = CurrencyFormatter.format(totalActual);

    final barGroups = List<BarChartGroupData>.generate(data.length, (index) {
      final entry = data[index];
      return BarChartGroupData(
        x: index,
        barsSpace: 12,
        barRods: [
          BarChartRodData(
            toY: entry.planned,
            color: entry.color,
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: entry.actual,
            color: entry.color.withValues(alpha: 0.4),
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    final maxValue = data.fold<double>(0, (max, entry) {
      return math.max(max, math.max(entry.planned, entry.actual));
    });
    final maxY = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    final interval = _calculateAxisInterval(maxY);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final mediaWidth = MediaQuery.of(context).size.width - 32;
        final chartWidth = math.max(mediaWidth, data.length * 80.0);

        return FractionallySizedBox(
          heightFactor: 0.9,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '수입 배분 그래프',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '배분된 금액과 실제 집행 현황을 비교할 수 있어요. '
                    '지출을 입력할수록 예산 막대가 변화합니다.',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _LegendDot(color: scheme.primary, label: '계획 금액'),
                      const SizedBox(width: 16),
                      _LegendDot(
                        color: scheme.primary.withValues(alpha: 0.4),
                        label: '집행 금액',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 280,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth,
                        child: BarChart(
                          BarChartData(
                            maxY: maxY,
                            minY: 0,
                            barGroups: barGroups,
                            alignment: BarChartAlignment.spaceAround,
                            gridData: FlGridData(
                              drawVerticalLine: false,
                              horizontalInterval: interval,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: scheme.outlineVariant,
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(),
                              rightTitles: const AxisTitles(),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 56,
                                  interval: interval,
                                  getTitlesWidget: (value, meta) {
                                    if (value < 0) {
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      CurrencyFormatter.format(
                                        value,
                                        showUnit: false,
                                      ),
                                      style: const TextStyle(fontSize: 11),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 60,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= data.length) {
                                      return const SizedBox.shrink();
                                    }
                                    final label = data[index].label;
                                    return SideTitleWidget(
                                      meta: meta,
                                      child: SizedBox(
                                        width: 70,
                                        child: Text(
                                          label,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                      final entry = data[group.x.toInt()];
                                      final label =
                                          rodIndex == 0 ? '계획' : '집행';
                                      final value = rodIndex == 0
                                          ? entry.planned
                                          : entry.actual;
                                      final formattedValue =
                                          CurrencyFormatter.format(value);
                                      return BarTooltipItem(
                                        '${entry.label}\n'
                                        '$label: $formattedValue',
                                        const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      );
                                    },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '총 계획 $totalPlannedLabel',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '총 집행 $totalActualLabel',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: data.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = data[index];
                        final diff = entry.actual - entry.planned;
                        final plannedLabel = CurrencyFormatter.format(
                          entry.planned,
                        );
                        final actualLabel = CurrencyFormatter.format(
                          entry.actual,
                        );
                        final diffLabel = CurrencyFormatter.format(diff.abs());
                        final diffPrefix = diff > 0 ? '초과' : '잔여';
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            entry.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '계획 $plannedLabel · 집행 $actualLabel',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: diff.abs() < 0.01
                              ? Text(
                                  '완료',
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Text(
                                  '$diffPrefix $diffLabel',
                                  style: TextStyle(
                                    color: diff > 0
                                        ? scheme.error
                                        : scheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
