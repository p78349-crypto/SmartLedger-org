import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/income_split_service.dart';
import '../services/transaction_service.dart';
import '../utils/utils.dart';

class IncomeSplitStatusScreen extends StatefulWidget {
  final String accountName;

  const IncomeSplitStatusScreen({super.key, required this.accountName});

  @override
  State<IncomeSplitStatusScreen> createState() =>
      _IncomeSplitStatusScreenState();
}

class _IncomeSplitStatusScreenState extends State<IncomeSplitStatusScreen> {
  late final StreamSubscription<void> _splitSub;

  @override
  void initState() {
    super.initState();
    _splitSub = IncomeSplitService().onChange.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _splitSub.cancel();
    super.dispose();
  }

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

  List<_SplitAllocationData> _splitAllocations(
    IncomeSplit split,
    double totalExpense,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final investmentColor = Color.lerp(scheme.primary, scheme.tertiary, 0.55)!;
    final double totalAllocated =
        split.savingsAmount +
        split.budgetAmount +
        split.emergencyAmount +
        split.assetTransferAmount;

    final double unassigned = split.totalIncome - totalAllocated;

    return [
      _SplitAllocationData(
        label: '저축',
        planned: split.savingsAmount,
        actual: split.savingsAmount,
        color: scheme.primary,
        description: '저축으로 이동',
      ),
      _SplitAllocationData(
        label: '예산',
        planned: split.budgetAmount,
        actual: totalExpense,
        color: scheme.tertiary,
        description: '지출 예산 사용',
      ),
      _SplitAllocationData(
        label: '비상금',
        planned: split.emergencyAmount,
        actual: split.emergencyAmount,
        color: scheme.secondary,
        description: '비상금으로 적립',
      ),
      _SplitAllocationData(
        label: '투자',
        planned: split.assetTransferAmount,
        actual: split.assetTransferAmount,
        color: investmentColor,
        description: '투자 자산으로 이동',
      ),
      if (unassigned > 0)
        _SplitAllocationData(
          label: '미배정',
          planned: unassigned,
          actual: 0,
          color: scheme.outline,
          description: '아직 계획되지 않은 금액',
        ),
    ];
  }

  void _openIncomeSplitChart(IncomeSplit split, double totalExpense) {
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
                    '배분된 금액과 실제 집행 현황을 비교할 수 있어요. 지출을 입력할수록 예산 막대가 변화합니다.',
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
                                      final label = rodIndex == 0 ? '계획' : '집행';
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

  Widget _buildIncomeSplitOverview(IncomeSplit split, double totalExpense) {
    final scheme = Theme.of(context).colorScheme;
    final data = _splitAllocations(
      split,
      totalExpense,
    ).where((entry) => entry.planned > 0).toList();

    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('수입 배분 데이터가 없습니다.'),
        ),
      );
    }

    final totalPlanned = data.fold<double>(0, (sum, e) => sum + e.planned);
    final totalActual = data.fold<double>(0, (sum, e) => sum + e.actual);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, size: 18),
                const SizedBox(width: 8),
                const Text(
                  '수입 배분 현황',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _openIncomeSplitChart(split, totalExpense),
                  icon: const Icon(Icons.pie_chart_outline),
                  label: const Text('그래프로 보기'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...data.map((entry) {
              final percentOfPlan = totalPlanned > 0
                  ? (entry.planned / totalPlanned) * 100
                  : 0;
              final usageRatio = entry.planned > 0
                  ? (entry.actual / entry.planned)
                  : 0;
              final usagePercent = entry.planned > 0
                  ? (usageRatio.clamp(0, 1) * 100)
                  : 0;
              final difference = entry.actual - entry.planned;
              final isOver = difference > 0.01;
              final plannedValue = CurrencyFormatter.format(entry.planned);
              final actualValue = CurrencyFormatter.format(entry.actual);
              final diffValue = CurrencyFormatter.format(difference.abs());
              final diffLabel = difference >= 0 ? '초과' : '잔여';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: entry.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${percentOfPlan.toStringAsFixed(0)}% 배분',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '계획 $plannedValue',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          '집행 $actualValue',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOver ? scheme.error : scheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (entry.label == '예산')
                          Text(
                            '$diffLabel $diffValue',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: difference > 0
                                  ? scheme.error
                                  : scheme.primary,
                            ),
                          )
                        else
                          Text(
                            entry.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: entry.planned > 0
                            ? (entry.actual / entry.planned).clamp(0, 1)
                            : 0,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(entry.color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${usagePercent.toStringAsFixed(0)}% 집행',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOver ? scheme.error : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 배분 ${CurrencyFormatter.format(totalPlanned)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '총 집행 ${CurrencyFormatter.format(totalActual)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final split = IncomeSplitService().getSplit(widget.accountName);
    final transactions = TransactionService().getTransactions(
      widget.accountName,
    );

    double totalExpense = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.accountName} - 수입 배분')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: split == null
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('이번 달 수입 배분 내역이 없습니다.'),
                ),
              )
            : _buildIncomeSplitOverview(split, totalExpense),
      ),
    );
  }
}

class _SplitAllocationData {
  final String label;
  final double planned;
  final double actual;
  final Color color;
  final String description;

  _SplitAllocationData({
    required this.label,
    required this.planned,
    required this.actual,
    required this.color,
    required this.description,
  });
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
