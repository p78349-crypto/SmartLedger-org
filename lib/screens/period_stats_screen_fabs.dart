// ignore_for_file: invalid_use_of_protected_member
part of 'period_stats_screen.dart';

/// 기간별 통계 FAB 빌더 + 거래 목록 화면
extension PeriodStatsScreenFabs on _PeriodStatsScreenState {
  Widget _buildFloatingButtons(ThemeData theme) {
    return Transform.translate(
      offset: const Offset(0, 5),
      child: SizedBox(
        width: 232,
        height: 120,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Positioned(
              right: 0,
              bottom: 0,
              child: FloatingActionButton(
                heroTag: 'period_stats_trend',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.grey),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CategoryStatsScreen(
                        accountName: widget.accountName,
                        initialDate: _anchorDay,
                        periodType: widget.view,
                      ),
                    ),
                  );
                },
                backgroundColor: Colors.white,
                elevation: 4,
                child: Icon(
                  Icons.trending_up,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Positioned(
              right: 72,
              bottom: 0,
              child: FloatingActionButton(
                heroTag: 'period_stats_bar',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.grey),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CategoryStatsScreen(
                        accountName: widget.accountName,
                        isSubCategory: true,
                        initialDate: _anchorDay,
                        periodType: widget.view,
                      ),
                    ),
                  );
                },
                backgroundColor: Colors.white,
                elevation: 4,
                child: Icon(
                  Icons.bar_chart,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Positioned(
              right: 144,
              bottom: 0,
              child: FloatingActionButton(
                heroTag: 'period_stats_misc',
                onPressed: () => _showMiscPolicyDialog(context),
                backgroundColor: Colors.white,
                elevation: 4,
                child: Icon(
                  IconCatalog.autoGraph,
                  size: 24,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodTransactionsListScreen extends StatelessWidget {
  const _PeriodTransactionsListScreen({
    required this.title,
    required this.rangeLabel,
    required this.transactions,
  });

  final String title;
  final String rangeLabel;
  final List<Transaction> transactions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormatter.defaultDate;
    final currencyFormat = NumberFormats.currency;

    return ValueListenableBuilder<Color>(
      valueListenable: BackgroundHelper.colorNotifier,
      builder: (context, bgColor, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(title: Text(title)),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rangeLabel, style: theme.textTheme.titleSmall),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Text(
                          '해당 기간에 표시할 거래가 없습니다.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    : ListView.separated(
                        itemCount: transactions.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final icon = tx.type == TransactionType.income
                              ? Icons.trending_up
                              : tx.type == TransactionType.expense
                              ? Icons.trending_down
                              : Icons.savings;

                          final color = tx.type == TransactionType.income
                              ? theme.colorScheme.primary
                              : tx.type == TransactionType.expense
                              ? theme.colorScheme.error
                              : (Colors.amber[700] ??
                                    theme.colorScheme.secondary);

                          final amountText =
                              '${tx.sign}'
                              '${currencyFormat.format(tx.amount.abs())}원';

                          return ListTile(
                            leading: Icon(icon, color: color),
                            title: Text(tx.description),
                            subtitle: Text(
                              '${dateFormat.format(tx.date)} · ${tx.memo}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Text(amountText),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
