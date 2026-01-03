import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/services/budget_service.dart';
import 'package:smart_ledger/services/income_split_service.dart';
import 'package:smart_ledger/services/monthly_agg_cache_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/utils.dart';
import 'package:smart_ledger/widgets/background_widget.dart';

class AccountHomeScreen extends StatefulWidget {
  final String accountName;
  const AccountHomeScreen({super.key, required this.accountName});

  @override
  State<AccountHomeScreen> createState() => _AccountHomeScreenState();
}

class _AccountHomeScreenState extends State<AccountHomeScreen> {
  late final StreamSubscription<void> _splitSub;

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
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: interval,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: Colors.grey[300],
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
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
                                          space: 8,
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
                                      final planned = budgets[category] ?? 0;
                                      final actual =
                                          categorySpending[category] ?? 0;
                                      final label = rodIndex == 0 ? '계획' : '지출';
                                      final value = rodIndex == 0
                                          ? planned
                                          : actual;
                                      final formattedValue =
                                          CurrencyFormatter.format(value);

                                      return BarTooltipItem(
                                        '$category\n$label: $formattedValue',
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
    final theme = Theme.of(context);
    return ElevatedButton.icon(
      onPressed: () =>
          _openCategoryUsageChart(categoryBudgets, categorySpending),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
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
  void initState() {
    super.initState();
    _splitSub = IncomeSplitService().onChange.listen((_) {
      if (mounted) setState(() {});
    });

    // Auto-generate monthly numeric caches (dirty months only, throttled).
    // This makes 1-month / 1-year stats ready without scanning large histories.
    unawaited(() async {
      await TransactionService().loadTransactions();
      if (!mounted) return;
      final txs = TransactionService().getTransactions(widget.accountName);
      await MonthlyAggCacheService().autoEnsureBuiltIfDirtyThrottled(
        accountName: widget.accountName,
        transactions: List<Transaction>.from(txs),
        includeQuickInput: false,
        // App-start path: lower frequency is fine.
        minIntervalSameMonth: const Duration(hours: 24),
      );
    }());
  }

  @override
  void dispose() {
    _splitSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentBudget = BudgetService().getBudget(widget.accountName);
    final account = AccountService().getAccountByName(widget.accountName);
    final monthEndAdjustment =
        (account?.carryoverAmount ?? 0) - (account?.overdraftAmount ?? 0);
    final transactions = TransactionService().getTransactions(
      widget.accountName,
    );

    // monthLabel and todayLabel removed — not used in this simplified view

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
    // usagePercentLabel and remainingPercentLabel removed (unused)
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
          appBar: AppBar(title: Text(widget.accountName)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  '총 지출',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormatter.format(totalExpense),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (plannedBudget > 0) ...[
              Builder(
                builder: (context) {
                  final scheme = Theme.of(context).colorScheme;
                  final overBudget = totalExpense > plannedBudget;
                  final progress = plannedBudget > 0
                      ? (totalExpense / plannedBudget)
                        .clamp(0.0, 1.0)
                        .toDouble()
                      : 0.0;
                  return LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      overBudget ? scheme.error : scheme.primary,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '예산: ${CurrencyFormatter.format(plannedBudget)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '남음: ${CurrencyFormatter.format(remainingBudget)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: remainingBudget < 0
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHigh
                      .withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '💡 팁',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '예산을 설정하면 지출을 더 효과적으로 관리할 수 있습니다.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (hasCategoryBudgets) ...[
              const SizedBox(height: 8),
              _buildCategoryUsageButton(categoryBudgets, categorySpending),
            ],
            const SizedBox(height: 200),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).pushNamed(
            AppRoutes.transactionAdd,
            arguments: TransactionAddArgs(accountName: widget.accountName),
          );
          if (mounted) setState(() {});
        },
        child: const Icon(Icons.add),
      ),
        );
      },
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
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}


