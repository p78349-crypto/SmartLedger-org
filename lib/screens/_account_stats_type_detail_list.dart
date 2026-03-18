part of 'account_stats_screen.dart';

/// 유형별 상세 – 카테고리 목록 (ExpansionTile).
extension AccountStatsTypeDetailList on _AccountStatsScreenState {
  List<Widget> _buildTypeDetailCategoryList(
    List<MapEntry<String, double>> sortedCategories,
    Map<String, List<Transaction>> categoryTransactions,
    double total,
    TransactionType type,
    ThemeData theme,
  ) {
    if (sortedCategories.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '${_typeLabel(type)} 거래가 없습니다.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ];
    }
    return sortedCategories.map((entry) {
      final pct = total > 0 ? (entry.value / total * 100) : 0.0;
      final txList = categoryTransactions[entry.key] ?? [];

      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: _typeColorFor(type, theme).withValues(alpha: 0.2),
            child: Icon(
              type == TransactionType.expense
                  ? Icons.remove_circle_outline
                  : (type == TransactionType.income
                        ? Icons.add_circle_outline
                        : Icons.savings_outlined),
              color: _typeColorFor(type, theme),
            ),
          ),
          title: Text(
            entry.key,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: pct / 100,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: _typeColorFor(type, theme),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text('${pct.toStringAsFixed(1)}%'),
            ],
          ),
          trailing: Text(
            '${_currencyFormat.format(entry.value)}원',
            style: TextStyle(
              color: _typeColorFor(type, theme),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          children: txList.map((tx) {
            final refunds = TransactionService().getRefundsForTransaction(
              widget.accountName,
              tx.id,
            );
            final totalRefunded = refunds.fold<double>(
              0.0,
              (sum, r) => sum + r.amount.abs(),
            );
            final hasRefund = refunds.isNotEmpty;
            final subDetail = [
              if (tx.subCategory != null && tx.subCategory!.isNotEmpty)
                tx.subCategory,
              if (tx.detailCategory != null && tx.detailCategory!.isNotEmpty)
                tx.detailCategory,
            ].join(' > ');

            return ListTile(
              dense: true,
              leading: tx.isRefund
                  ? const Icon(Icons.replay, size: 16, color: Colors.green)
                  : null,
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_dateFormat.format(tx.date)} '
                          '${tx.description}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: hasRefund
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (subDetail.isNotEmpty)
                          Text(
                            subDetail,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasRefund)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(51),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '반품',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green[700],
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: hasRefund
                  ? Text(
                      '환불: ${_currencyFormat.format(totalRefunded)}원',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                        fontSize: 11,
                      ),
                    )
                  : null,
              trailing: Text(
                '${_currencyFormat.format(tx.amount.abs())}원',
                style: TextStyle(
                  color: _typeColorFor(type, theme),
                  decoration: hasRefund ? TextDecoration.lineThrough : null,
                ),
              ),
              onTap: !tx.isRefund
                  ? () => _showTransactionActionDialog(tx, type, theme)
                  : null,
            );
          }).toList(),
        ),
      );
    }).toList();
  }
}
