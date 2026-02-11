// ignore_for_file: invalid_use_of_protected_member

part of 'period_detail_stats_screen.dart';

/// 기간 네비게이터·요약 카드·거래 목록 UI
extension PeriodDetailStatsUi on _PeriodDetailStatsScreenState {
  Widget buildPeriodNavigator(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: previousPeriod,
          ),
          Text(
            getCurrentPeriodLabel(context),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: nextPeriod,
          ),
        ],
      ),
    );
  }

  Widget buildSummaryCard(
    ThemeData theme,
    List<Transaction> transactions,
    double total,
    double average,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('총 $typeLabel', style: theme.textTheme.titleMedium),
              Text(
                '${_currencyFormat.format(total)}원',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('거래 건수', style: theme.textTheme.bodyMedium),
              Text(
                '${transactions.length}건',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (transactions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('평균 금액', style: theme.textTheme.bodyMedium),
                Text(
                  '${_currencyFormat.format(average)}원',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget buildTransactionListPortrait(
    ThemeData theme,
    List<Transaction> transactions,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: transactions.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final tx = transactions[index];
        final amountLabel = '${_currencyFormat.format(tx.amount)}원';
        return ListTile(
          leading: Icon(
            getIconForType(widget.transactionType),
            color: getColorForType(widget.transactionType, theme),
          ),
          title: Text(tx.description),
          subtitle: Text(_dateFormat.format(tx.date)),
          trailing: Text(
            amountLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: getColorForType(widget.transactionType, theme),
            ),
          ),
        );
      },
    );
  }

  Widget buildTransactionListLandscape(
    ThemeData theme,
    List<Transaction> transactions,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  '날짜',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 7,
                child: Text(
                  '내용',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  '금액',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final color = getColorForType(widget.transactionType, theme);
              final amountLabel = '${_currencyFormat.format(tx.amount)}원';
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      getIconForType(widget.transactionType),
                      size: 18,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(
                        _dateFormat.format(tx.date),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      flex: 7,
                      child: Text(
                        tx.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        amountLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData getIconForType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return Icons.remove_circle_outline;
      case TransactionType.income:
        return Icons.add_circle_outline;
      case TransactionType.savings:
        return Icons.savings_outlined;
      case TransactionType.refund:
        return RefundUtils.icon;
    }
  }

  Color getColorForType(TransactionType type, ThemeData theme) {
    switch (type) {
      case TransactionType.expense:
        return theme.colorScheme.error;
      case TransactionType.income:
        return theme.colorScheme.primary;
      case TransactionType.savings:
        return theme.colorScheme.tertiary;
      case TransactionType.refund:
        return RefundUtils.color;
    }
  }
}
