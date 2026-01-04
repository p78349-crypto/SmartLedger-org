import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:smart_ledger/models/fixed_cost.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/fixed_cost_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/date_formatter.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/refund_utils.dart';
import 'package:smart_ledger/utils/stats_labels.dart';

enum ChartType { bar, line, pie }

class ChartDetailScreen extends StatefulWidget {
  final String accountName;
  final TransactionType transactionType;

  const ChartDetailScreen({
    super.key,
    required this.accountName,
    required this.transactionType,
  });

  @override
  State<ChartDetailScreen> createState() => _ChartDetailScreenState();
}

class _ChartDetailScreenState extends State<ChartDetailScreen> {
  final NumberFormat _currencyFormat = NumberFormats.currency;
  final NumberFormat _compactNumberFormat = NumberFormats.currencyCompactKo;
  final DateFormat _rangeMonthFormat = DateFormatter.rangeMonth;

  ChartType _chartType = ChartType.bar;
  DateTime _anchorMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = true;
  List<FixedCost> _fixedCosts = const [];
  bool _includeFixedCosts = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await TransactionService().loadTransactions();
    await FixedCostService().loadFixedCosts();
    final costs = FixedCostService().getFixedCosts(widget.accountName);
    if (!mounted) return;
    setState(() {
      _fixedCosts = costs;
      _isLoading = false;
    });
  }

  String get _typeLabel {
    switch (widget.transactionType) {
      case TransactionType.expense:
        return '지출';
      case TransactionType.income:
        return '수입';
      case TransactionType.savings:
        return '예금';
      case TransactionType.refund:
        return '반품';
    }
  }

  Color _getTypeColor(ThemeData theme) {
    switch (widget.transactionType) {
      case TransactionType.expense:
        return theme.colorScheme.error;
      case TransactionType.income:
        return theme.colorScheme.primary;
      case TransactionType.savings:
        return Colors.amber[800]!;
      case TransactionType.refund:
        return RefundUtils.color;
    }
  }

  List<DateTime> _getChartMonths() {
    final service = TransactionService();
    final transactions = service.getTransactions(widget.accountName);

    if (transactions.isNotEmpty) {
      final sortedTransactions = transactions.toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      final firstTransactionDate = sortedTransactions.first.date;
      final firstMonth = DateTime(
        firstTransactionDate.year,
        firstTransactionDate.month,
      );

      final currentMonth = _anchorMonth;

      final monthsDiff =
          (currentMonth.year - firstMonth.year) * 12 +
          (currentMonth.month - firstMonth.month) +
          1;

      final displayMonths = monthsDiff > 12 ? 12 : monthsDiff;

      return List.generate(displayMonths, (index) {
        final offset = displayMonths - 1 - index;
        return DateTime(currentMonth.year, currentMonth.month - offset);
      });
    }

    return List.generate(12, (index) {
      final offset = 11 - index;
      return DateTime(_anchorMonth.year, _anchorMonth.month - offset);
    });
  }

  List<MapEntry<DateTime, double>> _getChartData() {
    final months = _getChartMonths();
    final service = TransactionService();
    final transactions = service.getTransactions(widget.accountName);

    return months.map((month) {
      final monthTransactions = transactions.where(
        (tx) =>
            tx.type == widget.transactionType &&
            tx.date.year == month.year &&
            tx.date.month == month.month,
      );

      var total = monthTransactions.fold<double>(
        0.0,
        (sum, tx) => sum + tx.amount,
      );

      if (_includeFixedCosts &&
          _fixedCosts.isNotEmpty &&
          widget.transactionType == TransactionType.expense) {
        final monthlyCost = _fixedCosts.fold<double>(
          0.0,
          (sum, fc) => sum + fc.amount,
        );
        total += monthlyCost;
      }

      return MapEntry(month, total);
    }).toList();
  }

  void _previousPeriod() {
    setState(() {
      _anchorMonth = DateTime(_anchorMonth.year, _anchorMonth.month - 1);
    });
  }

  void _nextPeriod() {
    setState(() {
      _anchorMonth = DateTime(_anchorMonth.year, _anchorMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
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

  Widget _buildChart(
    List<MapEntry<DateTime, double>> data,
    ThemeData theme,
    double maxValue,
    Color color,
  ) {
    switch (_chartType) {
      case ChartType.bar:
        return _buildBarChart(data, theme, maxValue, color);
      case ChartType.line:
        return _buildLineChart(data, theme, maxValue, color);
      case ChartType.pie:
        return _buildPieChart(data, theme, color);
    }
  }

  Widget _buildBarChart(
    List<MapEntry<DateTime, double>> data,
    ThemeData theme,
    double maxValue,
    Color color,
  ) {
    final groups = data
        .asMap()
        .entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: color,
                borderRadius: BorderRadius.circular(4),
                width: 14,
              ),
            ],
          ),
        )
        .toList();

    return BarChart(
      BarChartData(
        barGroups: groups,
        maxY: maxValue * 1.1,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${_currencyFormat.format(rod.toY)}원',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compactNumberFormat.format(value),
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  final month = data[value.toInt()].key;
                  return Text(
                    '${month.month}월',
                    style: theme.textTheme.bodySmall,
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxValue / 5,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildLineChart(
    List<MapEntry<DateTime, double>> data,
    ThemeData theme,
    double maxValue,
    Color color,
  ) {
    final spots = data
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
        .toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
        maxY: maxValue * 1.1,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${_currencyFormat.format(spot.y)}원',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compactNumberFormat.format(value),
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  final month = data[value.toInt()].key;
                  return Text(
                    '${month.month}월',
                    style: theme.textTheme.bodySmall,
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxValue / 5,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildPieChart(
    List<MapEntry<DateTime, double>> data,
    ThemeData theme,
    Color baseColor,
  ) {
    final filteredData = data.where((entry) => entry.value > 0).toList();

    if (filteredData.isEmpty) {
      return Center(
        child: Text(
          '표시할 데이터가 없습니다.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final sections = filteredData.asMap().entries.map((entry) {
      final index = entry.key;
      final monthData = entry.value;
      final sectionColor = Color.fromARGB(
        255,
        math.max(0, math.min(255, (baseColor.r * 255).round() + (index * 20))),
        math.max(0, math.min(255, (baseColor.g * 255).round() - (index * 10))),
        math.max(0, math.min(255, (baseColor.b * 255).round() + (index * 15))),
      );

      return PieChartSectionData(
        value: monthData.value,
        title: '${monthData.key.month}월',
        radius: 100,
        color: sectionColor,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
        ),
      ),
    );
  }
}
