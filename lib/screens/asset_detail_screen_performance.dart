part of 'asset_detail_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

/// 자산 성과/이력 분석 (New Feature)
/// - 예금: 납입액 vs 수령액 -> 이자 계산
/// - 투자: 총 매수 vs 총 매도 -> 수익률 계산
/// - 기록: 메모를 강조하여 전략 수립 보조
extension AssetDetailPerformance on _AssetDetailScreenState {
  Widget _buildPerformanceAnalysis(ThemeData theme) {
    final moves = AssetMoveService().getMovesForAsset(
      widget.accountName,
      widget.asset.id,
    );

    // 1. 데이터 집계
    double totalIn = 0; // 총 투입 (매수/이체입금/예금납입)
    double totalOut = 0; // 총 회수 (매도/이체출금/만기수령)
    final historyItems = <Map<String, dynamic>>[];

    for (var m in moves) {
      final isIn = m.toAssetId == widget.asset.id;
      final isOut = m.fromAssetId == widget.asset.id;
      if (isIn) totalIn += m.amount;
      if (isOut) totalOut += m.amount;
      historyItems.add({
        'date': m.date,
        'type': m.type.label,
        'amount': m.amount,
        'isIncome': isIn,
        'memo': m.memo,
      });
    }

    final currentValue = _currentAsset.amount;
    final netProfit = (totalOut + currentValue) - totalIn;
    final returnRate = totalIn > 0 ? (netProfit / totalIn) * 100 : 0.0;
    final isDeposit = widget.asset.category == AssetCategory.deposit;

    if (moves.isEmpty) return const SizedBox.shrink();

    final profitColor = netProfit > 0
        ? Colors.green
        : (netProfit < 0
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface);
    final profitSign = netProfit > 0 ? '+' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isDeposit ? Icons.savings_outlined : Icons.show_chart,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              isDeposit ? '예금/적금 성과 분석' : '투자 성과 리포트',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 성과 요약 카드
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAnalysisItem(
                    theme,
                    isDeposit ? '총 납입원금' : '총 매수금액',
                    totalIn,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  _buildAnalysisItem(
                    theme,
                    isDeposit ? '총 수령액(+평가액)' : '총 매도액(+평가액)',
                    totalOut + currentValue,
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '순수익 (ROI)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$profitSign${CurrencyFormatter.format(netProfit)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: profitColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$profitSign${returnRate.toStringAsFixed(2)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: profitColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (netProfit < 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '손실이 발생했습니다. 아래 기록의 메모를 확인하여 전략을 점검하세요.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '히스토리 및 전략 노트',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: historyItems.length,
          separatorBuilder: (context, i) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = historyItems[historyItems.length - 1 - index];
            final date = item['date'] as DateTime;
            final isAssetIn = item['isIncome'] as bool;
            final amountColor = isAssetIn
                ? theme.colorScheme.primary
                : theme.colorScheme.error;
            final prefix = isAssetIn ? '+ ' : '- ';
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            DateFormatter.defaultDate.format(date),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isAssetIn
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isAssetIn
                                  ? (isDeposit ? '납입' : '매수')
                                  : (isDeposit ? '출금/만기' : '매도'),
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '$prefix${CurrencyFormatter.format(item['amount'])}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (item['memo'] != null &&
                      (item['memo'] as String).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.edit_note, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['memo'],
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
