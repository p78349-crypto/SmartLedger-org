import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../services/budget_service.dart';
import '../services/income_split_service.dart';
import '../services/transaction_service.dart';
import '../utils/date_formats.dart';
import '../utils/utils.dart';
import '../widgets/background_widget.dart';

class BudgetStatusScreen extends StatefulWidget {
  final String accountName;
  const BudgetStatusScreen({super.key, required this.accountName});

  @override
  State<BudgetStatusScreen> createState() => _BudgetStatusScreenState();
}

class _BudgetStatusScreenState extends State<BudgetStatusScreen> {
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentBudget = BudgetService().getBudget(widget.accountName);
    final account = AccountService().getAccountByName(widget.accountName);
    final monthEndAdjustment =
        (account?.carryoverAmount ?? 0) - (account?.overdraftAmount ?? 0);
    final transactions = TransactionService().getTransactions(
      widget.accountName,
    );

    final monthLabel = DateFormats.yMLabel.format(DateTime.now());
    final today = DateTime.now();
    final todayLabel = '${today.day}일 오늘의 지출';

    double totalExpense = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        totalExpense += tx.amount;
      }
    }

    final split = IncomeSplitService().getSplit(widget.accountName);
    final plannedBudget = currentBudget > 0
        ? currentBudget
        : split?.budgetAmount ?? 0;
    final effectivePlannedBudget = plannedBudget + monthEndAdjustment;
    final remainingBudget = effectivePlannedBudget - totalExpense;
    final usagePercentLabel = effectivePlannedBudget > 0
        ? ((totalExpense / effectivePlannedBudget) * 100).toStringAsFixed(0)
        : '0';
    final remainingPercentLabel = effectivePlannedBudget > 0
        ? ((remainingBudget / effectivePlannedBudget) * 100).toStringAsFixed(0)
        : '0';
    final categoryBudgets = split?.categoryBudgets ?? const <String, double>{};
    final hasCategoryBudgets = categoryBudgets.isNotEmpty;
    final Map<String, double> categorySpending = <String, double>{};
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        final category = tx.mainCategory.isNotEmpty
            ? tx.mainCategory
            : Transaction.defaultMainCategory;
        categorySpending[category] =
            (categorySpending[category] ?? 0) + tx.amount;
      }
    }

    return ValueListenableBuilder<Color>(
      valueListenable: BackgroundHelper.colorNotifier,
      builder: (context, bgColor, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(title: Text('${widget.accountName} - 예산 현황')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      monthLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        todayLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: monthLabel.length * 10.0),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primaryContainer,
                        Theme.of(context).colorScheme.primary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이번 달 예산',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(effectivePlannedBudget),
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              '사용',
                              CurrencyFormatter.format(totalExpense),
                              '$usagePercentLabel%',
                              scheme.onPrimary.withValues(alpha: 0.88),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: scheme.onPrimary.withValues(alpha: 0.3),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              '잔여',
                              CurrencyFormatter.format(remainingBudget),
                              '$remainingPercentLabel%',
                              scheme.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (hasCategoryBudgets)
                  _buildCategoryUsageButton(categoryBudgets, categorySpending),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String title,
    String amount,
    String percentage,
    Color textColor,
  ) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          percentage,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
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
