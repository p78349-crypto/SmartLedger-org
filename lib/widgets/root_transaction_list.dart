import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';
import '../navigation/app_routes.dart';
import '../utils/date_formats.dart';
import '../utils/number_formats.dart';
import 'state_placeholders.dart';

class RootTransactionList extends StatelessWidget {
  RootTransactionList({
    super.key,
    required this.transactions,
    required this.transactionAccountMap,
    required this.isFocused,
    NumberFormat? currencyFormat,
    DateFormat? dateFormat,
  }) : currencyFormat = currencyFormat ?? NumberFormats.currency,
       dateFormat = dateFormat ?? DateFormats.yMddot;

  final List<Transaction> transactions;
  final Map<String, String> transactionAccountMap;
  final bool isFocused;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (transactions.isEmpty) {
      return EmptyState(
        title: isFocused ? '거래 내역이 없습니다.' : '검색 결과 없음',
        message: isFocused ? '지출을 입력하거나 계정을 선택해보세요.' : '검색어를 변경하거나 기간을 넓혀보세요.',
        primaryLabel: isFocused ? '지출 입력' : null,
        onPrimary: isFocused ? () => Navigator.of(context).pop() : null,
        secondaryLabel: isFocused ? null : '검색 초기화',
        onSecondary: isFocused ? null : () => Navigator.of(context).maybePop(),
      );
    }

    return ListView.separated(
      itemCount: transactions.length,
      separatorBuilder: (context, _) => const Divider(),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final accountName = transactionAccountMap[tx.id] ?? '미분류';

        final amountColor = _colorForType(tx.type, theme);
        final dateLabel = dateFormat.format(tx.date);
        final memoLabel = tx.memo.isNotEmpty ? ' · ${tx.memo}' : '';
        final paymentLabel = tx.paymentMethod.isNotEmpty
            ? ' · ${tx.paymentMethod}'
            : '';

        return ListTile(
          leading: Icon(_iconForType(tx.type), color: amountColor),
          title: Text(tx.description),
          subtitle: Text('$dateLabel · $accountName$paymentLabel$memoLabel'),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx.sign}${currencyFormat.format(tx.amount)}원',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(tx.type.label, style: theme.textTheme.labelSmall),
            ],
          ),
          isThreeLine: tx.memo.isNotEmpty,
          onTap: accountName == '미분류'
              ? null
              : () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.transactionDetail,
                    arguments: TransactionDetailArgs(
                      accountName: accountName,
                      initialType: tx.type,
                    ),
                  );
                },
        );
      },
    );
  }

  IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.trending_up;
      case TransactionType.savings:
        return Icons.savings;
      case TransactionType.expense:
        return Icons.trending_down;
      case TransactionType.refund:
        return Icons.replay;
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
}
