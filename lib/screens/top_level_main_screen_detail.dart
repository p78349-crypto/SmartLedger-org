part of 'top_level_main_screen.dart';

class TopLevelStatsDetailScreen extends StatelessWidget {
  const TopLevelStatsDetailScreen({super.key, required this.dashboard});

  final RootDashboardContext dashboard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final currencyFormat = NumberFormats.currency;
    final dateFormat = DateFormatter.defaultDate;

    final transactionsByAccount = dashboard.transactionsByAccount;
    final accountById = dashboard.transactionAccountMap;
    final summary = dashboard.summaryData;

    final accountFixedCostTotals = <String, double>{};
    for (final entry in dashboard.allFixedCosts) {
      accountFixedCostTotals.update(
        entry.accountName,
        (value) => value + entry.cost.amount,
        ifAbsent: () => entry.cost.amount,
      );
    }

    final hasFixedCosts = summary.hasFixedCosts;
    final totalFixedCost = summary.totalFixedCost;
    final totalExpenseDisplay = hasFixedCosts
        ? summary.totalExpenseWithFixed
        : summary.totalExpense;
    final expenseLabel = hasFixedCosts ? '총 지출(고정비 포함)' : '총 지출';
    final netTotal = summary.netDisplay;

    final accountSummaries = dashboard.trackedAccountNames.map((accountName) {
      final accountTransactions =
          transactionsByAccount[accountName] ?? const <Transaction>[];
      double income = 0;
      double expense = 0;
      double savings = 0;
      double refund = 0;
      for (final tx in accountTransactions) {
        switch (tx.type) {
          case TransactionType.income:
            income += tx.amount;
            break;
          case TransactionType.expense:
            // 환불은 음수로 저장되어 있어 자동으로 차감됨
            expense += tx.amount;
            break;
          case TransactionType.savings:
            savings += tx.amount;
            break;
          case TransactionType.refund:
            refund += tx.amount;
            break;
        }
      }
      final fixedCost = accountFixedCostTotals[accountName] ?? 0;
      return _AccountAggregate(
        name: accountName,
        income: income,
        expense: expense,
        savings: savings,
        refund: refund,
        fixedCost: fixedCost,
      );
    }).toList()..sort((a, b) => b.net.compareTo(a.net));

    final topOutflows =
        dashboard.allTransactions
            .where((tx) => tx.type != TransactionType.income)
            .toList()
          ..sort((a, b) => b.amount.compareTo(a.amount));

    final totalIncome = summary.totalIncome;
    final totalSavings = summary.totalSavings;
    final allFixedCosts = dashboard.allFixedCosts;

    return Scaffold(
      appBar: AppBar(title: const Text('전체 통계 상세')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('요약', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          _buildSummaryCard(
            theme: theme,
            currencyFormat: currencyFormat,
            totalIncome: totalIncome,
            expenseLabel: expenseLabel,
            totalExpenseDisplay: totalExpenseDisplay,
            totalSavings: totalSavings,
            hasFixedCosts: hasFixedCosts,
            totalFixedCost: totalFixedCost,
            netTotal: netTotal,
          ),
          const SizedBox(height: 12),
          if (dashboard.orphanAccountNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '다음 계정에 잔여 데이터가 남아 있습니다: '
                  '${dashboard.orphanAccountNames.join(', ')}. '
                  '계정 삭제 후 데이터가 유지된 경우 정리해 주세요.',
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          ],
          ..._buildAccountSummariesSection(
            theme: theme,
            isLandscape: isLandscape,
            currencyFormat: currencyFormat,
            accountSummaries: accountSummaries,
          ),
          ..._buildTopOutflowsSection(
            theme: theme,
            isLandscape: isLandscape,
            currencyFormat: currencyFormat,
            dateFormat: dateFormat,
            topOutflows: topOutflows,
            accountById: accountById,
          ),
          if (hasFixedCosts)
            ..._buildFixedCostsSection(
              theme: theme,
              isLandscape: isLandscape,
              currencyFormat: currencyFormat,
              allFixedCosts: allFixedCosts,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required ThemeData theme,
    required NumberFormat currencyFormat,
    required double totalIncome,
    required String expenseLabel,
    required double totalExpenseDisplay,
    required double totalSavings,
    required bool hasFixedCosts,
    required double totalFixedCost,
    required double netTotal,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(
              label: '총 수입',
              value: _formatCurrency(currencyFormat, totalIncome),
              valueColor: theme.colorScheme.primary,
            ),
            _buildSummaryRow(
              label: expenseLabel,
              value: _formatAmountByType(
                currencyFormat,
                totalExpenseDisplay,
                TransactionType.expense,
              ),
              valueColor: theme.colorScheme.error,
            ),
            _buildSummaryRow(
              label: '총 예금',
              value: _formatAmountByType(
                currencyFormat,
                totalSavings,
                TransactionType.savings,
              ),
              valueColor: Colors.amber[800] ?? theme.colorScheme.secondary,
            ),
            if (hasFixedCosts)
              _buildSummaryRow(
                label: '총 고정비용(월)',
                value: _formatAmountByType(
                  currencyFormat,
                  totalFixedCost,
                  TransactionType.expense,
                ),
                valueColor: theme.colorScheme.secondary,
              ),
            const Divider(height: 24),
            _buildSummaryRow(
              label: '순이익',
              value: _formatCurrency(
                currencyFormat,
                netTotal,
                includeSign: true,
              ),
              valueColor: netTotal >= 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
          ],
        ),
      ),
    );
  }
}
