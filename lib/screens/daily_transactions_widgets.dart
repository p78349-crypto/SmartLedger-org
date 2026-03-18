import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../navigation/app_routes.dart';
import '../theme/app_colors.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/refund_utils.dart';

// Linter: avoid redundant argument value warnings in this UI file are non-actionable
// in some styleFrom uses (intentional explicit paddings); suppress the lint here.
// ignore_for_file: avoid_redundant_argument_values

/// Bottom action bar with quick-access buttons.
class DailyTransactionsBottomBar extends StatelessWidget {
  const DailyTransactionsBottomBar({super.key, required this.accountName});

  final String accountName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.transactionAddDetailed,
                      arguments: AccountArgs(accountName: accountName),
                    );
                  },
                  // padding intentionally specified for visual balance
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.pink.shade200, width: 1.0),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '개수 입력',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.shoppingPointsInput,
                      arguments: ShoppingPointsInputArgs(
                        accountName: accountName,
                      ),
                    );
                  },
                  // padding intentionally specified for visual balance
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.pink.shade200, width: 1.0),
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '포인트 입력',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.foodExpiry,
                      arguments: const FoodExpiryArgs(openUpsertOnStart: true),
                    );
                  },
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 6,
                    ),
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '식료품/생활용품 등록',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Date navigation header with daily totals summary.
class DailyTransactionDateHeader extends StatelessWidget {
  const DailyTransactionDateHeader({
    super.key,
    required this.selectedDay,
    required this.transactions,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrevDay,
    required this.onNextDay,
    required this.numberFormat,
  });

  final DateTime selectedDay;
  final List<Transaction> transactions;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback? onPrevDay;
  final VoidCallback? onNextDay;
  final NumberFormat numberFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final weekday = weekdayLabels[selectedDay.weekday - 1];
    final monthDay = DateFormatter.formatMonthDay(selectedDay);
    final formattedDate = '$monthDay ($weekday)';

    double totalIncome = 0;
    double totalExpense = 0;
    double totalSavings = 0;
    double totalRefund = 0;
    for (final t in transactions) {
      switch (t.type) {
        case TransactionType.income:
          totalIncome += t.amount;
          break;
        case TransactionType.expense:
          totalExpense += t.amount;
          break;
        case TransactionType.savings:
          totalSavings += t.amount;
          break;
        case TransactionType.refund:
          totalRefund += t.amount;
          break;
      }
    }

    final paymentTotals = <String, double>{};
    for (final t in transactions) {
      if (t.type != TransactionType.expense) continue;
      final method = t.paymentMethod.trim();
      if (method.isEmpty) continue;
      final amount = (t.cardChargedAmount ?? t.amount).abs();
      paymentTotals[method] = (paymentTotals[method] ?? 0) + amount;
    }

    String? paymentSummary;
    if (paymentTotals.isNotEmpty) {
      final sorted = paymentTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final parts = sorted.take(3).map((e) {
        final v = numberFormat.format(e.value);
        return '${e.key} $v';
      }).toList();
      paymentSummary = parts.join(' · ');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrevDay,
            icon: const Icon(IconCatalog.chevronLeft),
          ),
          Column(
            children: [
              Text(
                formattedDate,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (totalIncome > 0) ...[
                    const Text(
                      '수입 ',
                      style: TextStyle(color: AppColors.income, fontSize: 12),
                    ),
                    Text(
                      '+${numberFormat.format(totalIncome)}원',
                      style: const TextStyle(
                        color: AppColors.income,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (totalExpense > 0) ...[
                    const Text(
                      '지출 ',
                      style: TextStyle(color: AppColors.expense, fontSize: 12),
                    ),
                    Text(
                      '-${numberFormat.format(totalExpense)}원',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.expense,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (totalSavings > 0) ...[
                    const Text(
                      '예금 ',
                      style: TextStyle(color: AppColors.savings, fontSize: 12),
                    ),
                    Text(
                      '⊕${numberFormat.format(totalSavings)}원',
                      style: const TextStyle(
                        color: AppColors.savings,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (totalRefund > 0) ...[
                    const SizedBox(width: 12),
                    const Text(
                      '환급 ',
                      style: TextStyle(color: RefundUtils.color, fontSize: 12),
                    ),
                    Text(
                      '⊕${numberFormat.format(totalRefund)}원',
                      style: const TextStyle(
                        color: RefundUtils.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              if (paymentSummary != null) ...[
                const SizedBox(height: 6),
                Text(
                  '결제: $paymentSummary',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          IconButton(
            onPressed: onNextDay,
            icon: const Icon(IconCatalog.chevronRight),
          ),
        ],
      ),
    );
  }
}
