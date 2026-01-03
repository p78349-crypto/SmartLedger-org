import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_ledger/models/fixed_cost.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/theme/app_colors.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/utils.dart';

class RootSummaryData {
  const RootSummaryData({
    required this.totalIncome,
    required this.totalExpense,
    required this.totalSavings,
    required this.totalRefund,
    required this.totalFixedCost,
    required this.totalExpenseWithFixed,
    required this.netDisplay,
    required this.hasFixedCosts,
    required this.topTransactions,
    required this.topFixedCosts,
    this.remainingAmount = 0,
  });

  final double totalIncome;
  final double totalExpense;
  final double totalSavings;
  final double totalRefund;
  final double totalFixedCost;
  final double totalExpenseWithFixed;
  final double netDisplay;
  final bool hasFixedCosts;
  final List<RootTransactionEntry> topTransactions;
  final List<RootFixedCostEntry> topFixedCosts;
  final double remainingAmount;
}

class RootTransactionEntry {
  const RootTransactionEntry({
    required this.transaction,
    required this.accountName,
  });

  final Transaction transaction;
  final String accountName;
}

class RootFixedCostEntry {
  const RootFixedCostEntry({required this.cost, required this.accountName});

  final FixedCost cost;
  final String accountName;
}

class RootSummaryCard extends StatelessWidget {
  const RootSummaryCard({
    super.key,
    required this.data,
    required this.onViewDetail,
  });

  final RootSummaryData data;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormats.custom('#,###');

    Color netColor() {
      if (data.netDisplay >= 0) {
        return theme.colorScheme.primary;
      }
      return theme.colorScheme.error;
    }

    Color incomeColor() => theme.colorScheme.primary;
    Color expenseColor() => theme.colorScheme.error;
    Color savingsColor() => Colors.amber[700] ?? theme.colorScheme.secondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('전체 계정 수입/지출 통계', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _SummaryItem(
                  label: '수입',
                  value: CurrencyFormatter.formatSigned(data.totalIncome),
                  color: incomeColor(),
                ),
                _SummaryItem(
                  label: '지출',
                  value: CurrencyFormatter.formatOutflow(
                    data.hasFixedCosts
                        ? data.totalExpenseWithFixed
                        : data.totalExpense,
                  ),
                  color: expenseColor(),
                ),
                if (data.hasFixedCosts)
                  _SummaryItem(
                    label: '고정비',
                    value: CurrencyFormatter.formatOutflow(data.totalFixedCost),
                    color: theme.colorScheme.secondary,
                  ),
                _SummaryItem(
                  label: '예금',
                  value: CurrencyFormatter.formatSigned(data.totalSavings),
                  color: savingsColor(),
                ),
                if (data.totalRefund > 0)
                  _SummaryItem(
                    label: '반품',
                    value: CurrencyFormatter.formatSigned(data.totalRefund),
                    color: Colors.green[700] ?? theme.colorScheme.primary,
                  ),
                _SummaryItem(
                  label: '남은 돈',
                  value: CurrencyFormatter.formatSigned(data.remainingAmount),
                  color: netColor(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('전체 지출·예금 상위 5개', style: theme.textTheme.titleSmall),
            if (data.topTransactions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('표시할 거래가 없습니다.'),
              )
            else
              ...data.topTransactions.map(
                (entry) => _buildTransactionTile(entry, currencyFormat),
              ),
            if (data.hasFixedCosts) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text('등록된 고정비용 상위 5개', style: theme.textTheme.titleSmall),
              if (data.topFixedCosts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text('등록된 고정비용이 없습니다.'),
                )
              else
                ...data.topFixedCosts.map((entry) {
                  final accountLabel = entry.accountName.isEmpty
                      ? '미분류'
                      : entry.accountName;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      IconCatalog.receiptLong,
                      color: theme.colorScheme.secondary,
                    ),
                    title: Text(entry.cost.name),
                    subtitle: Text(
                      '$accountLabel · ${_fixedCostSubtitle(entry.cost)}',
                    ),
                    trailing: Text(
                      CurrencyFormatter.formatOutflow(entry.cost.amount),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  );
                }),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onViewDetail,
                child: const Text('자세히 보기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(
    RootTransactionEntry entry,
    NumberFormat currencyFormat,
  ) {
    final tx = entry.transaction;
    final accountName = entry.accountName.isEmpty ? '미분류' : entry.accountName;
    final dateStr = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
    final memoPart = tx.memo.isNotEmpty ? ', ${tx.memo}' : '';
    final subtitle = '$dateStr ($accountName$memoPart)';
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return ListTile(
          dense: true,
          leading: Icon(
            _iconForType(tx.type),
            color: _colorForType(tx.type, theme),
          ),
          title: Text(tx.description),
          subtitle: Text(subtitle),
          trailing: Text(
            '${tx.sign}${currencyFormat.format(tx.amount.abs())}원',
          ),
        );
      },
    );
  }

  IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return IconCatalog.trendingUp;
      case TransactionType.savings:
        return IconCatalog.savings;
      case TransactionType.expense:
        return IconCatalog.trendingDown;
      case TransactionType.refund:
        return IconCatalog.refund;
    }
  }

  Color _colorForType(TransactionType type, ThemeData theme) {
    switch (type) {
      case TransactionType.income:
        return theme.colorScheme.primary;
      case TransactionType.savings:
        return Colors.amber[700] ?? theme.colorScheme.secondary;
      case TransactionType.expense:
        return theme.colorScheme.error;
      case TransactionType.refund:
        return Colors.green;
    }
  }

  String _fixedCostSubtitle(FixedCost cost) {
    final parts = <String>[];
    if (cost.paymentMethod.isNotEmpty) {
      parts.add(cost.paymentMethod);
    }
    if (cost.vendor != null && cost.vendor!.trim().isNotEmpty) {
      parts.add(cost.vendor!.trim());
    }
    if (cost.dueDay != null) {
      parts.add('매월 ${cost.dueDay}일');
    }
    if (cost.memo != null && cost.memo!.trim().isNotEmpty) {
      parts.add(cost.memo!.trim());
    }
    if (parts.isEmpty) {
      return '추가 정보 없음';
    }
    return parts.join(' · ');
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: label == '예금'
                ? AppColors.savingsText
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
