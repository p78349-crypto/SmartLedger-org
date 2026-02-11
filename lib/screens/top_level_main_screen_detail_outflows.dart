part of 'top_level_main_screen.dart';

extension TopLevelDetailOutflows on TopLevelStatsDetailScreen {
  List<Widget> _buildTopOutflowsSection({
    required ThemeData theme,
    required bool isLandscape,
    required NumberFormat currencyFormat,
    required DateFormat dateFormat,
    required List<Transaction> topOutflows,
    required Map<String, String> accountById,
  }) {
    return [
      const SizedBox(height: 16),
      Text('상위 지출·예금', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      if (topOutflows.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('표시할 거래가 없습니다.'),
          ),
        )
      else
        Card(
          child: Column(
            children: [
              if (isLandscape)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
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
                        flex: 6,
                        child: Text(
                          '계정 · 날짜 · 결제',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
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
              ...topOutflows.take(20).map((tx) {
                final accountName = accountById[tx.id] ?? '미분류';
                final paymentPart = tx.paymentMethod.isNotEmpty
                    ? ' · ${tx.paymentMethod}'
                    : '';
                final datePart = dateFormat.format(tx.date);
                final subtitle = '$accountName · $datePart$paymentPart';
                final amount = _formatAmountByType(
                  currencyFormat,
                  tx.amount,
                  tx.type,
                );

                if (isLandscape) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _iconForType(tx.type),
                          size: 18,
                          color: _colorForType(tx.type, theme),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 5,
                          child: Text(
                            tx.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 6,
                          child: Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            amount,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListTile(
                  leading: Icon(
                    _iconForType(tx.type),
                    color: _colorForType(tx.type, theme),
                  ),
                  title: Text(tx.description),
                  subtitle: Text(subtitle),
                  trailing: Text(amount),
                );
              }),
            ],
          ),
        ),
    ];
  }

  List<Widget> _buildFixedCostsSection({
    required ThemeData theme,
    required bool isLandscape,
    required NumberFormat currencyFormat,
    required List<RootFixedCostEntry> allFixedCosts,
  }) {
    return [
      const SizedBox(height: 16),
      Text('등록된 고정비용', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      Card(
        child: Column(
          children: [
            if (isLandscape)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        '항목',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text(
                        '계정 · 정보',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
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
            ...allFixedCosts.take(30).map((entry) {
              final accountName = entry.accountName.isEmpty
                  ? '미분류'
                  : entry.accountName;
              final subtitle =
                  '$accountName · ${_fixedCostSubtitle(entry.cost)}';
              final amount = _formatAmountByType(
                currencyFormat,
                entry.cost.amount,
                TransactionType.expense,
              );

              if (isLandscape) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(IconCatalog.receiptLong, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: Text(
                          entry.cost.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        flex: 6,
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          amount,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListTile(
                leading: const Icon(IconCatalog.receiptLong),
                title: Text(entry.cost.name),
                subtitle: Text(subtitle),
                trailing: Text(amount),
              );
            }),
          ],
        ),
      ),
    ];
  }
}
