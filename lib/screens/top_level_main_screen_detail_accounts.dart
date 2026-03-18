part of 'top_level_main_screen.dart';

extension TopLevelDetailAccounts on TopLevelStatsDetailScreen {
  List<Widget> _buildAccountSummariesSection({
    required ThemeData theme,
    required bool isLandscape,
    required NumberFormat currencyFormat,
    required List<_AccountAggregate> accountSummaries,
  }) {
    return [
      const SizedBox(height: 16),
      Text('계정별 현황', style: theme.textTheme.titleMedium),
      const SizedBox(height: 8),
      if (accountSummaries.isEmpty)
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('등록된 계정이 없습니다.'),
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
                        flex: 3,
                        child: Text(
                          '계정',
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
                          '요약',
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
                          '순이익',
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
              ...accountSummaries.map((summary) {
                final accountName = summary.name.isEmpty ? '미분류' : summary.name;
                final incomeLabel = _formatCurrency(
                  currencyFormat,
                  summary.income,
                );
                final expenseLabelStr = _formatAmountByType(
                  currencyFormat,
                  summary.expense,
                  TransactionType.expense,
                );
                final savingsLabel = _formatAmountByType(
                  currencyFormat,
                  summary.savings,
                  TransactionType.savings,
                );

                final detailParts = [
                  '수입 $incomeLabel',
                  '지출 $expenseLabelStr',
                  '예금 $savingsLabel',
                ];
                if (summary.refund > 0) {
                  final refundLabel = _formatAmountByType(
                    currencyFormat,
                    summary.refund,
                    TransactionType.refund,
                  );
                  detailParts.add('반품 $refundLabel');
                }
                if (summary.fixedCost > 0) {
                  final fixedCostLabel = _formatAmountByType(
                    currencyFormat,
                    summary.fixedCost,
                    TransactionType.expense,
                  );
                  detailParts.add('고정비 $fixedCostLabel');
                }
                final netLabel = _formatCurrency(
                  currencyFormat,
                  summary.net,
                  includeSign: true,
                );
                final detailText = detailParts.join(' · ');

                if (isLandscape) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Text(
                            accountName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Expanded(
                          flex: 7,
                          child: Text(
                            detailText,
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
                            netLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: TextStyle(
                              color: summary.net >= 0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListTile(
                  title: Text(accountName),
                  subtitle: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodySmall,
                      children: [
                        for (var i = 0; i < detailParts.length; i++)
                          ...(() {
                            final part = detailParts[i];
                            if (part.startsWith('예금')) {
                              const label = '예금';
                              final value = part.substring(label.length);
                              return [
                                const TextSpan(
                                  text: label,
                                  style: TextStyle(
                                    color: AppColors.savingsText,
                                  ),
                                ),
                                TextSpan(text: value),
                                if (i < detailParts.length - 1)
                                  const TextSpan(text: ' · '),
                              ];
                            }
                            return [
                              TextSpan(text: part),
                              if (i < detailParts.length - 1)
                                const TextSpan(text: ' · '),
                            ];
                          })(),
                      ],
                    ),
                  ),
                  trailing: Text(
                    netLabel,
                    style: TextStyle(
                      color: summary.net >= 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
    ];
  }
}
