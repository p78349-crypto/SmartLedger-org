part of 'root_account_screen.dart';

/// 계정별 재무 현황 섹션 (가로/세로 모드)
extension RootAccountScreenAccounts on RootAccountScreen {
  Widget _buildAccountSection(
    ThemeData theme,
    List<AccountFinancialOverview> summaries,
    String query,
    bool isLandscape,
  ) {
    final labelByAccount = <String, String>{};
    int userIndex = 0;
    for (final s in summaries) {
      final name = s.accountName;
      if (name.trim().toUpperCase() == 'ROOT') {
        labelByAccount[name] = 'ROOT';
        continue;
      }
      userIndex++;
      if (userIndex == 1) {
        labelByAccount[name] = '유저1';
      } else if (userIndex == 2) {
        labelByAccount[name] = '유저2';
      }
    }

    if (summaries.isEmpty) {
      if (query.isNotEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('검색 결과가 없습니다.', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('"$query" 와 일치하는 계정명을 찾지 못했습니다.'),
              ],
            ),
          ),
        );
      }
      return _buildEmptyState(theme);
    }

    if (isLandscape) {
      return _buildLandscapeTable(theme, summaries, labelByAccount);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('계정별 재무 현황', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        ...summaries.map(
          (summary) => _AccountCard(
            summary: summary,
            formatCurrency: _formatCurrency,
            formatDate: _formatDate,
            onEnterAccount: onEnterAccount,
            onDeleteAccount: onDeleteAccount,
            showInlineManagementControls: showInlineAccountControls,
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeTable(
    ThemeData theme,
    List<AccountFinancialOverview> summaries,
    Map<String, String> labelByAccount,
  ) {
    const headerStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('계정별 재무 현황', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  '계정',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: headerStyle,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '자산',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: headerStyle,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '월 수입',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: headerStyle,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '월 지출',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: headerStyle,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '거래',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: headerStyle,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Text(
                  '최근 거래',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: headerStyle,
                ),
              ),
              SizedBox(width: 88),
            ],
          ),
        ),
        const Divider(height: 1),
        ...summaries.expand((summary) {
          return [
            _buildLandscapeRow(theme, summary, labelByAccount),
            const Divider(height: 1),
          ];
        }),
      ],
    );
  }

  Widget _buildLandscapeRow(
    ThemeData theme,
    AccountFinancialOverview summary,
    Map<String, String> labelByAccount,
  ) {
    final assetsText = _formatCurrency(summary.totalAssets);
    final incomeText = _formatCurrency(summary.monthlyIncome);
    final expenseText = _formatCurrency(summary.monthlyExpense);
    final txCountText = '${summary.transactionCount}건';
    final latestText = _formatDate(summary.latestTransactionDate);

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(IconCatalog.arrowForwardIos),
          tooltip: '계정으로 이동',
          onPressed: () => onEnterAccount(summary.accountName),
        ),
        if (showInlineAccountControls)
          IconButton(
            icon: const Icon(IconCatalog.deleteOutline),
            tooltip: '계정 삭제',
            onPressed: () => onDeleteAccount(summary.accountName),
          ),
      ],
    );

    return InkWell(
      onTap: () => onEnterAccount(summary.accountName),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      summary.accountName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (labelByAccount[summary.accountName] != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        labelByAccount[summary.accountName]!,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  assetsText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  incomeText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  expenseText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  txCountText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Text(
                latestText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            actions,
          ],
        ),
      ),
    );
  }
}
