// ignore_for_file: invalid_use_of_protected_member
part of 'budget_status_screen.dart';

extension BudgetStatusScreenChart on _BudgetStatusScreenState {
  double _calculateAxisInterval(double maxValue) {
    if (maxValue <= 0) {
      return 1;
    }

    final rawInterval = maxValue / 4;
    double magnitude = 1;

    for (var i = 0; i < 10 && rawInterval / magnitude > 10; i++) {
      magnitude *= 10;
    }

    for (var i = 0; i < 10 && rawInterval / magnitude < 1; i++) {
      magnitude /= 10;
    }

    final normalized = rawInterval / magnitude;
    double niceNormalized;
    if (normalized <= 1) {
      niceNormalized = 1;
    } else if (normalized <= 2) {
      niceNormalized = 2;
    } else if (normalized <= 5) {
      niceNormalized = 5;
    } else {
      niceNormalized = 10;
    }

    return niceNormalized * magnitude;
  }

  void _openCategoryUsageChart(
    Map<String, double> categoryBudgets,
    Map<String, double> categorySpending,
  ) {
    final budgets = Map<String, double>.from(categoryBudgets)
      ..removeWhere((_, value) => value <= 0);

    if (budgets.isEmpty) {
      if (!mounted) return;
      SnackbarUtils.showInfo(context, '배분된 카테고리 예산이 없어요. 수입 배분에서 먼저 설정해주세요.');
      return;
    }

    final categories = budgets.keys.toList()
      ..sort((a, b) => budgets[b]!.compareTo(budgets[a]!));

    double maxValue = 0;
    for (final category in categories) {
      final planned = budgets[category] ?? 0;
      final actual = categorySpending[category] ?? 0;
      maxValue = math.max(maxValue, math.max(planned, actual));
    }

    final adjustedMaxY = maxValue <= 0 ? 1.0 : maxValue * 1.15;
    final interval = _calculateAxisInterval(adjustedMaxY);
    final scheme = Theme.of(context).colorScheme;
    final barGroups = List<BarChartGroupData>.generate(categories.length, (
      index,
    ) {
      final category = categories[index];
      final planned = budgets[category] ?? 0;
      final actual = categorySpending[category] ?? 0;
      return BarChartGroupData(
        x: index,
        barsSpace: 12,
        barRods: [
          BarChartRodData(
            toY: planned,
            color: scheme.primary,
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: actual,
            color: scheme.tertiary,
            width: 14,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          widthFactor: 1,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const horizontalPadding = 16.0;
                final availableWidth =
                    constraints.maxWidth - (horizontalPadding * 2);
                final chartWidth = math.max(
                  availableWidth,
                  categories.length * 110.0,
                );

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    24 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              '카테고리 예산 사용량',
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
                        '수입 배분에서 설정한 카테고리별 예산 대비 실제 지출을 한눈에 확인하세요.',
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _LegendDot(color: scheme.primary, label: '계획 예산'),
                          const SizedBox(width: 16),
                          _LegendDot(color: scheme.tertiary, label: '실제 지출'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 320,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: chartWidth,
                            child: BarChart(
                              BarChartData(
                                maxY: adjustedMaxY,
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
                                        if (index < 0 ||
                                            index >= categories.length) {
                                          return const SizedBox.shrink();
                                        }
                                        final label = categories[index];
                                        return SideTitleWidget(
                                          meta: meta,
                                          child: SizedBox(
                                            width: 80,
                                            child: Text(
                                              label,
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
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
                                          final category =
                                              categories[group.x.toInt()];
                                          final planned =
                                              budgets[category] ?? 0;
                                          final actual =
                                              categorySpending[category] ?? 0;
                                          final label = rodIndex == 0
                                              ? '계획'
                                              : '지출';
                                          final value = rodIndex == 0
                                              ? planned
                                              : actual;
                                          final formattedValue =
                                              CurrencyFormatter.format(value);
                                          return BarTooltipItem(
                                            '$category\n'
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
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryUsageButton(
    Map<String, double> categoryBudgets,
    Map<String, double> categorySpending,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return ElevatedButton.icon(
      onPressed: () =>
          _openCategoryUsageChart(categoryBudgets, categorySpending),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.bar_chart_rounded),
      label: const Text(
        '카테고리 예산 사용량 그래프 보기',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
