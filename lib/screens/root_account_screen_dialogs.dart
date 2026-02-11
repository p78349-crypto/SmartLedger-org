part of 'root_account_screen.dart';

/// 통계표 다이얼로그
extension RootAccountScreenDialogs on RootAccountScreen {
  void _showStatsTable(BuildContext context, RootFinancialOverview data) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.table_chart, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              const Text('통계표 (Statistics Table)'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('계정')),
                    DataColumn(
                      label: Text('자산', textAlign: TextAlign.right),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('월 수입', textAlign: TextAlign.right),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('월 지출', textAlign: TextAlign.right),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('순이익', textAlign: TextAlign.right),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text('고정비', textAlign: TextAlign.right),
                      numeric: true,
                    ),
                  ],
                  rows: [
                    ...data.accountSummaries.map(
                      (s) => DataRow(
                        cells: [
                          DataCell(Text(s.accountName)),
                          DataCell(
                            Text(
                              _formatCurrency(s.totalAssets).replaceAll('원', ''),
                            ),
                          ),
                          DataCell(
                            Text(
                              _formatCurrency(s.monthlyIncome)
                                  .replaceAll('원', ''),
                            ),
                          ),
                          DataCell(
                            Text(
                              _formatCurrency(s.monthlyExpense)
                                  .replaceAll('원', ''),
                            ),
                          ),
                          DataCell(
                            Text(
                              _formatCurrency(s.monthlyNetCashFlow)
                                  .replaceAll('원', ''),
                              style: TextStyle(
                                color: s.monthlyNetCashFlow >= 0
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              _formatCurrency(s.totalFixedCosts)
                                  .replaceAll('원', ''),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataRow(
                      cells: [
                        const DataCell(
                          Text(
                            '합계',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(data.totalAssets),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(data.totalMonthlyIncome),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(data.totalMonthlyExpense),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(data.totalMonthlyNetCashFlow),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: data.totalMonthlyNetCashFlow >= 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            _formatCurrency(data.totalFixedCosts),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      selected: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }
}
