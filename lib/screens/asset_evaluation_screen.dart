import 'package:flutter/material.dart';

import '../models/asset.dart';
import '../services/asset_move_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';

class AssetEvaluationScreen extends StatelessWidget {
  final String accountName;
  final Asset asset;

  const AssetEvaluationScreen({
    super.key,
    required this.accountName,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: AssetMoveService().loadMoves(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final theme = Theme.of(context);
        final moves = AssetMoveService().getMovesForAsset(
          accountName,
          asset.id,
        );
        if (moves.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: Text('${asset.name} 평가')),
            body: const Center(child: Text('이동 기록이 없어 평가할 수 없습니다.')),
          );
        }

        double totalIn = 0;
        double totalOut = 0;
        final historyItems = <Map<String, dynamic>>[];

        for (final move in moves) {
          final isIn = move.toAssetId == asset.id;
          final isOut = move.fromAssetId == asset.id;
          if (isIn) totalIn += move.amount;
          if (isOut) totalOut += move.amount;
          historyItems.add({
            'date': move.date,
            'type': move.type.label,
            'amount': move.amount,
            'isIncome': isIn,
            'memo': move.memo,
          });
        }

        final currentValue = asset.amount;
        final netProfit = (totalOut + currentValue) - totalIn;
        final returnRate = totalIn > 0 ? (netProfit / totalIn) * 100 : 0.0;
        final costBasis = asset.costBasis ?? 0;
        final hasCostBasis = asset.costBasis != null && asset.costBasis! > 0;
        final isDeposit = asset.category == AssetCategory.deposit;
        final profitColor = netProfit > 0
            ? Colors.green
            : (netProfit < 0
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface);
        final profitSign = netProfit > 0 ? '+' : '';
        final moveCount = moves.length;
        final lastMoveDate = moves.isNotEmpty
            ? moves.map((m) => m.date).reduce((a, b) => a.isAfter(b) ? a : b)
            : null;
        final targetAmount = asset.targetAmount;
        final targetProgress = targetAmount != null && targetAmount > 0
            ? (currentValue / targetAmount) * 100
            : null;
        final expectedRate = asset.expectedAnnualRatePct;
        final projectedValue = expectedRate != null
            ? currentValue * (1 + expectedRate / 100)
            : null;
        final debtAmount = asset.debtAmount ?? 0;
        final hasDebt = asset.debtAmount != null && asset.debtAmount! > 0;
        final maturityDate = asset.maturityDate;
        final daysToMaturity = maturityDate?.difference(DateTime.now()).inDays;
        final isMaturitySoon =
            daysToMaturity != null &&
            daysToMaturity >= 0 &&
            daysToMaturity <= 30;
        final alertThreshold = asset.alertThreshold;
        final isBelowThreshold =
            alertThreshold != null && currentValue < alertThreshold;

        return Scaffold(
          appBar: AppBar(title: Text('${asset.name} 평가')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '자산 평가 (성과 분석)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSectionTitle(theme, '현재 상태 (총액, 비중)'),
                const SizedBox(height: 8),
                _buildInfoCard(
                  theme,
                  rows: [
                    _MetricRow('현재 금액', CurrencyFormatter.format(currentValue)),
                    _MetricRow(
                      '카테고리',
                      '${asset.category.emoji} ${asset.category.label}',
                    ),
                    if (hasCostBasis)
                      _MetricRow('원가', CurrencyFormatter.format(costBasis)),
                    if (asset.monthlyIncome != null)
                      _MetricRow(
                        '월 수익',
                        CurrencyFormatter.format(asset.monthlyIncome!),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionTitle(theme, '흐름과 변화 (증감 추이, 수익률)'),
                const SizedBox(height: 8),
                _buildInfoCard(
                  theme,
                  rows: [
                    _MetricRow('이동 기록', '$moveCount건'),
                    if (lastMoveDate != null)
                      _MetricRow(
                        '최근 이동',
                        DateFormatter.defaultDate.format(lastMoveDate),
                      ),
                    _MetricRow(
                      '순수익',
                      '$profitSign${CurrencyFormatter.format(netProfit)}',
                      valueColor: profitColor,
                    ),
                    _MetricRow(
                      '손익률',
                      '$profitSign${returnRate.toStringAsFixed(2)}%',
                      valueColor: profitColor,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionTitle(theme, '위험 관리 (부채, 만기)'),
                const SizedBox(height: 8),
                _buildInfoCard(
                  theme,
                  rows: [
                    if (hasDebt)
                      _MetricRow(
                        '부채',
                        CurrencyFormatter.format(debtAmount),
                        valueColor: theme.colorScheme.error,
                      )
                    else
                      const _MetricRow('부채', '없음'),
                    if (maturityDate != null)
                      _MetricRow(
                        '만기일',
                        DateFormatter.defaultDate.format(maturityDate),
                        valueColor: isMaturitySoon
                            ? theme.colorScheme.error
                            : null,
                      )
                    else
                      const _MetricRow('만기일', '없음'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionTitle(theme, '목표와 계획 (달성률, 예측)'),
                const SizedBox(height: 8),
                _buildInfoCard(
                  theme,
                  rows: [
                    if (targetAmount != null)
                      _MetricRow('목표액', CurrencyFormatter.format(targetAmount)),
                    if (targetProgress != null)
                      _MetricRow(
                        '달성률',
                        '${targetProgress.toStringAsFixed(1)}%',
                      ),
                    if (expectedRate != null)
                      _MetricRow(
                        '예상 1년 후',
                        CurrencyFormatter.format(
                          projectedValue ?? currentValue,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionTitle(theme, '알림/인사이트 (임계값, 위험, 만기)'),
                const SizedBox(height: 8),
                _buildInfoCard(
                  theme,
                  rows: [
                    if (alertThreshold != null)
                      _MetricRow(
                        '경고 임계값',
                        CurrencyFormatter.format(alertThreshold),
                      ),
                    _MetricRow(
                      '임계값 상태',
                      isBelowThreshold ? '경고: 임계값 이하' : '정상',
                      valueColor: isBelowThreshold
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                    _MetricRow(
                      '만기 상태',
                      isMaturitySoon ? '주의: 만기 임박' : '정상',
                      valueColor: isMaturitySoon
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                  ],
                ),
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
                                      horizontal: 6,
                                      vertical: 2,
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
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(fontSize: 10),
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
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.3),
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
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalysisItem(ThemeData theme, String label, double amount) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          CurrencyFormatter.format(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoCard(ThemeData theme, {required List<_MetricRow> rows}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [for (final row in rows) _buildMetricRow(theme, row)],
      ),
    );
  }

  Widget _buildMetricRow(ThemeData theme, _MetricRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              row.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            row.value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: row.valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricRow(this.label, this.value, {this.valueColor});
}
