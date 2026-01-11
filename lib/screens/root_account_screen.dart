import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/root_overview_service.dart';
import '../utils/date_formatter.dart';
import '../utils/dialog_utils.dart';
import '../utils/icon_catalog.dart';
import '../utils/number_formats.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/background_widget.dart';

class RootAccountScreen extends StatelessWidget {
  RootAccountScreen({
    super.key,
    required this.overview,
    required this.isLoading,
    required this.errorMessage,
    required this.searchController,
    required this.onRefresh,
    required this.onEnterAccount,
    required this.onDeleteAccount,
    required this.onCreateAccount,
    this.showInlineAccountControls = true,
    this.showSearchField = true,
    this.onOpenSearch,
    this.onOpenTrash,
    this.useScaffold = true,
  });

  final RootFinancialOverview? overview;
  final bool isLoading;
  final String? errorMessage;
  final TextEditingController searchController;
  final Future<void> Function() onRefresh;
  final void Function(String) onEnterAccount;
  final void Function(String) onDeleteAccount;
  final void Function() onCreateAccount;
  final bool showInlineAccountControls;
  final bool showSearchField;
  final VoidCallback? onOpenSearch;
  final VoidCallback? onOpenTrash;
  final bool useScaffold;

  final NumberFormat _numberFormat = NumberFormats.currency;
  final DateFormat _dateFormat = DateFormatter.defaultDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final query = searchController.text.trim().toLowerCase();
    final summaries = (overview?.accountSummaries ?? [])
        .where(
          (summary) => query.isEmpty
              ? true
              : summary.accountName.toLowerCase().contains(query),
        )
        .toList();
    final actionsSection = _buildAccountActions(context, theme);

    final content = SafeArea(
      child: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildAccountToolbar(context, theme),
            const SizedBox(height: 12),
            if (actionsSection != null) ...[
              actionsSection,
              const SizedBox(height: 16),
            ],
            if (errorMessage != null) _buildErrorCard(theme, errorMessage!),
            if (overview != null) ...[
              if (isLoading) const LinearProgressIndicator(),
              if (!isLoading) _buildSummarySection(theme, overview!),
              const SizedBox(height: 24),
              _buildAccountSection(theme, summaries, query, isLandscape),
            ] else if (isLoading) ...[
              const SizedBox(height: 120),
              const Center(child: CircularProgressIndicator()),
            ] else ...[
              _buildEmptyState(theme),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (!useScaffold) {
      return content;
    }

    return ValueListenableBuilder<Color>(
      valueListenable: BackgroundHelper.colorNotifier,
      builder: (context, bgColor, _) {
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(title: const Text('ROOT 계정 관리')),
          body: content,
        );
      },
    );
  }

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

  Widget _buildAccountToolbar(BuildContext context, ThemeData theme) {
    final accounts = overview?.accountSummaries ?? [];
    final canDelete = accounts.length > 1;

    final menuItems = <PopupMenuEntry<_AccountMenuAction>>[
      const PopupMenuItem(
        value: _AccountMenuAction.create,
        child: Row(
          children: [Icon(IconCatalog.add), SizedBox(width: 12), Text('계정 추가')],
        ),
      ),
      PopupMenuItem(
        value: _AccountMenuAction.delete,
        enabled: canDelete,
        child: const Row(
          children: [
            Icon(IconCatalog.deleteOutline),
            SizedBox(width: 12),
            Text('계정 삭제'),
          ],
        ),
      ),
      PopupMenuItem(
        value: _AccountMenuAction.trash,
        enabled: onOpenTrash != null,
        child: const Row(
          children: [
            Icon(IconCatalog.deleteSweepOutlined),
            SizedBox(width: 12),
            Text('휴지통'),
          ],
        ),
      ),
    ];

    return Row(
      children: [
        if (onOpenSearch != null)
          OutlinedButton.icon(
            onPressed: onOpenSearch,
            icon: const Icon(IconCatalog.search),
            label: const Text('검색 열기'),
          ),
        if (onOpenSearch != null) const SizedBox(width: 8),
        const Spacer(),
        PopupMenuButton<_AccountMenuAction>(
          tooltip: '계정 관리',
          onSelected: (action) => _handleToolbarAction(context, action),
          itemBuilder: (context) => menuItems,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('계정 관리', style: theme.textTheme.titleMedium),
              const SizedBox(width: 4),
              const Icon(IconCatalog.expandMore),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildAccountActions(BuildContext context, ThemeData theme) {
    if (!showSearchField) {
      return null;
    }

    return TextField(
      controller: searchController,
      decoration: InputDecoration(
        labelText: '계정 검색',
        hintText: '계정명을 입력하세요',
        prefixIcon: const Icon(IconCatalog.search),
        suffixIcon: searchController.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(IconCatalog.close),
                tooltip: '검색어 지우기',
                onPressed: () {
                  searchController.clear();
                  FocusScope.of(context).unfocus();
                },
              ),
      ),
    );
  }

  Future<void> _handleToolbarAction(
    BuildContext context,
    _AccountMenuAction action,
  ) async {
    switch (action) {
      case _AccountMenuAction.create:
        onCreateAccount();
        break;
      case _AccountMenuAction.delete:
        await _showDeleteAccountSheet(context);
        break;
      case _AccountMenuAction.trash:
        onOpenTrash?.call();
        break;
    }
  }

  Future<void> _showDeleteAccountSheet(BuildContext context) async {
    final accounts = overview?.accountSummaries ?? [];
    if (accounts.isEmpty) {
      SnackbarUtils.showWarning(context, '삭제할 계정이 없습니다.');
      return;
    }

    if (accounts.length <= 1) {
      SnackbarUtils.showWarning(context, '최소 하나의 계정은 유지해야 합니다.');
      return;
    }

    final labelByAccount = <String, String>{};
    int userIndex = 0;
    for (final a in accounts) {
      final name = a.accountName;
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

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.6;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '삭제할 계정을 선택하세요',
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: accounts.length,
                    separatorBuilder: (context, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      final label = labelByAccount[account.accountName];
                      return ListTile(
                        title: Text(account.accountName),
                        subtitle: Text(
                          '자산 ${_formatCurrency(account.totalAssets)} · '
                          '거래 ${account.transactionCount}건',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (label != null)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  label,
                                  style: Theme.of(
                                    sheetContext,
                                  ).textTheme.labelMedium,
                                ),
                              ),
                            const Icon(IconCatalog.deleteOutline),
                          ],
                        ),
                        onTap: () =>
                            Navigator.of(sheetContext).pop(account.accountName),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!context.mounted) {
      return;
    }

    if (selected == null) {
      return;
    }

    final confirmed = await DialogUtils.showConfirmDialog(
      context,
      title: '계정 삭제',
      message: '"$selected" 계정을 휴지통으로 이동할까요?',
      confirmText: '삭제',
      isDangerous: true,
    );

    if (!context.mounted) {
      return;
    }

    if (confirmed) {
      onDeleteAccount(selected);
    }
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

            return [
              InkWell(
                onTap: () => onEnterAccount(summary.accountName),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
              ),
              const Divider(height: 1),
            ];
          }),
        ],
      );
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
                              _formatCurrency(
                                s.totalAssets,
                              ).replaceAll('원', ''),
                            ),
                          ),
                          DataCell(
                            Text(
                              _formatCurrency(
                                s.monthlyIncome,
                              ).replaceAll('원', ''),
                            ),
                          ),
                          DataCell(
                            Text(
                              _formatCurrency(
                                s.monthlyExpense,
                              ).replaceAll('원', ''),
                            ),
                          ),
                          DataCell(
                            Text(
                              _formatCurrency(
                                s.monthlyNetCashFlow,
                              ).replaceAll('원', ''),
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
                              _formatCurrency(
                                s.totalFixedCosts,
                              ).replaceAll('원', ''),
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

  String _formatCurrency(double value) {
    final sign = value < 0 ? '-' : '';
    final formatted = _numberFormat.format(value.abs());
    return '$sign$formatted원';
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '거래 내역 없음';
    }
    return _dateFormat.format(value);
  }
}

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
