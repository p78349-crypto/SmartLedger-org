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

part 'budget_status_screen_chart.dart';

class BudgetStatusScreen extends StatefulWidget {
  final String accountName;
  const BudgetStatusScreen({super.key, required this.accountName});

  @override
  State<BudgetStatusScreen> createState() => _BudgetStatusScreenState();
}

class _BudgetStatusScreenState extends State<BudgetStatusScreen> {
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
      } else if (tx.type == TransactionType.refund) {
        totalExpense -= tx.amount;
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
      } else if (tx.type == TransactionType.refund) {
        final category = tx.mainCategory.isNotEmpty
            ? tx.mainCategory
            : Transaction.defaultMainCategory;
        categorySpending[category] =
            (categorySpending[category] ?? 0) - tx.amount;
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
