part of 'root_account_screen.dart';

/// 요약 카드, 계정 카드, 정보 행 위젯 및 메뉴 열거형
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.theme,
    required this.width,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final ThemeData theme;
  final double width;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: valueColor ?? theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: valueColor ?? theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.summary,
    required this.formatCurrency,
    required this.formatDate,
    required this.onEnterAccount,
    required this.onDeleteAccount,
    required this.showInlineManagementControls,
  });

  final AccountFinancialOverview summary;
  final String Function(double) formatCurrency;
  final String Function(DateTime?) formatDate;
  final void Function(String) onEnterAccount;
  final void Function(String) onDeleteAccount;
  final bool showInlineManagementControls;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    summary.accountName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(IconCatalog.arrowForwardIos),
                  tooltip: '계정으로 이동',
                  onPressed: () => onEnterAccount(summary.accountName),
                ),
                if (showInlineManagementControls) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(IconCatalog.deleteOutline),
                    tooltip: '계정 삭제',
                    onPressed: () => onDeleteAccount(summary.accountName),
                  ),
                ],
              ],
            ),
            const Divider(),
            const SizedBox(height: 4),
            _InfoRow(
              label: '자산',
              value: formatCurrency(summary.totalAssets),
              icon: IconCatalog.accountBalanceWalletOutlined,
            ),
            _InfoRow(
              label: '월 수입',
              value: formatCurrency(summary.monthlyIncome),
              icon: IconCatalog.trendingUp,
              valueColor: theme.colorScheme.primary,
            ),
            _InfoRow(
              label: '월 지출',
              value: formatCurrency(summary.monthlyExpense),
              icon: IconCatalog.trendingDown,
              valueColor: theme.colorScheme.error,
            ),
            if (summary.monthlyIncome != 0)
              _InfoRow(
                label: '월 순이익',
                value: formatCurrency(summary.monthlyNetCashFlow),
                icon: IconCatalog.autoGraph,
                valueColor: summary.monthlyNetCashFlow >= 0
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
            _InfoRow(
              label: '고정비',
              value: formatCurrency(summary.totalFixedCosts),
              icon: IconCatalog.paymentsOutlined,
            ),
            _InfoRow(
              label: '거래 건수',
              value: '${summary.transactionCount}건',
              icon: IconCatalog.receiptLong,
            ),
            _InfoRow(
              label: '최근 거래',
              value: formatDate(summary.latestTransactionDate),
              icon: IconCatalog.schedule,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor ?? theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

enum _AccountMenuAction { create, delete, trash }
