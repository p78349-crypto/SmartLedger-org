part of 'root_account_screen.dart';

/// 요약 카드, 에러 카드, 빈 상태 UI
extension RootAccountScreenSummary on RootAccountScreen {
  Widget _buildErrorCard(ThemeData theme, String message) {
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(IconCatalog.errorOutline, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(ThemeData theme, RootFinancialOverview data) {
    final refMonthPad = data.referenceMonth.month.toString().padLeft(2, '0');
    final monthLabel = '${data.referenceMonth.year}.$refMonthPad 기준';
    const spacing = 8.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        double cardWidth;
        if (maxWidth >= 720) {
          cardWidth = (maxWidth - (spacing * 2)) / 3;
        } else if (maxWidth >= 480) {
          cardWidth = (maxWidth - spacing) / 2;
        } else {
          cardWidth = maxWidth;
        }

        final summaryCards = <Widget>[
          _SummaryCard(
            icon: IconCatalog.accountBalanceWallet,
            title: '총 자산',
            value: _formatCurrency(data.totalAssets),
            theme: theme,
            width: cardWidth,
          ),
          _SummaryCard(
            icon: IconCatalog.trendingUp,
            title: '월 수입',
            value: _formatCurrency(data.totalMonthlyIncome),
            theme: theme,
            valueColor: theme.colorScheme.primary,
            width: cardWidth,
          ),
          _SummaryCard(
            icon: IconCatalog.trendingDown,
            title: '월 지출',
            value: _formatCurrency(data.totalMonthlyExpense),
            theme: theme,
            valueColor: theme.colorScheme.error,
            width: cardWidth,
          ),
          _SummaryCard(
            icon: IconCatalog.payments,
            title: '총 고정비',
            value: _formatCurrency(data.totalFixedCosts),
            theme: theme,
            width: cardWidth,
          ),
        ];

        if (data.totalMonthlyIncome != 0) {
          summaryCards.add(
            _SummaryCard(
              icon: IconCatalog.calculate,
              title: '월 순이익',
              value: _formatCurrency(data.totalMonthlyNetCashFlow),
              theme: theme,
              valueColor: data.totalMonthlyNetCashFlow >= 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
              width: cardWidth,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('전체 요약', style: theme.textTheme.titleMedium),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.table_chart),
                      tooltip: '통계표 보기',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showStatsTable(context, data),
                    ),
                  ],
                ),
                Text(monthLabel, style: theme.textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: spacing),
            Wrap(spacing: spacing, runSpacing: spacing, children: summaryCards),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              IconCatalog.accountTreeOutlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text('등록된 계정이 없습니다.', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('새 계정을 생성하거나 데이터를 가져오세요.'),
          ],
        ),
      ),
    );
  }
}
