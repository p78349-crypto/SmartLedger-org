// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../models/fixed_cost.dart';
import '../models/transaction.dart';
import 'account_create_screen.dart';
import 'account_main_screen.dart';
import 'account_select_screen.dart';
import '../services/account_service.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/transaction_service.dart';
import '../services/user_pref_service.dart';
import '../theme/app_colors.dart';
import '../utils/backup_password_bootstrapper.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/number_formats.dart';
import '../utils/refund_utils.dart';
import '../utils/snackbar_utils.dart';
import '../utils/top_level_stats_utils.dart';
import '../widgets/month_end_carryover_dialog.dart';
import '../widgets/root_summary_card.dart';
import '../widgets/root_transaction_list.dart';

class TopLevelMainScreen extends StatefulWidget {
  const TopLevelMainScreen({super.key});

  @override
  State<TopLevelMainScreen> createState() => _TopLevelMainScreenState();
}

class _TopLevelMainScreenState extends State<TopLevelMainScreen> {
  // (duplicate quick-tile implementation removed)

  late TextEditingController searchController;
  late FocusNode searchFocusNode;
  List<Transaction> searchResults = [];
  bool isSearchFocused = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController()..addListener(_onSearchChanged);
    searchFocusNode = FocusNode()..addListener(_onFocusChange);
    _initializeServices();
    _initialLoad();
  }

  Future<void> _initializeServices() async {
    await NotificationService().initialize();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      isSearchFocused = searchFocusNode.hasFocus;
    });
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Widget _buildAccountControlButtons() {
    final accounts = AccountService().accounts;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final result = await navigator.push<String>(
              MaterialPageRoute(
                builder: (context) => const AccountCreateScreen(),
              ),
            );
            if (result != null && result.isNotEmpty) {
              await UserPrefService.setLastAccountName(result);
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => AccountMainScreen(accountName: result),
                ),
                (route) => false,
              );
            }
          },
          child: const Text('새 계정'),
        ),
        ElevatedButton(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final accs = accounts.map((a) => a.name).toList();
            final selected = await navigator.push<String>(
              MaterialPageRoute(
                builder: (context) => AccountSelectScreen(accounts: accs),
              ),
            );
            if (selected != null && selected.isNotEmpty) {
              if (!mounted) return;
              await BackupPasswordBootstrapper
                  .ensureBackupPasswordConfiguredOnEntry(
                context,
              );
              await BackupService().autoBackupIfNeeded(selected);
              if (!mounted) return;
              await UserPrefService.setLastAccountName(selected);
              if (!mounted) return;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) =>
                      AccountMainScreen(accountName: selected),
                ),
                (route) => false,
              );
            }
          },
          child: const Text('선택'),
        ),
        ElevatedButton(
          onPressed: _showMonthEndDialogForAllAccounts,
          child: const Text('월말 정산'),
        ),
        // Account management button removed to avoid UI obstruction.
      ],
    );
  }

  void _checkMonthEnd() {
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;

    // 매달 마지막 날 또는 그 다음날에 체크
    if (now.day == lastDayOfMonth || now.day == 1) {
      final accounts = AccountService().accounts;

      for (final account in accounts) {
        // 마지막 이월 날짜가 이번달이 아니면 다이얼로그 표시
        final lastCarryover = account.lastCarryoverDate;
        if (lastCarryover == null ||
            lastCarryover.month != now.month ||
            lastCarryover.year != now.year) {
          _showMonthEndDialog(account);
          break; // 한 번에 하나씩만 표시
        }
      }
    }
  }

  void _showMonthEndDialog(Account account) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MonthEndCarryoverDialog(
        account: account,
        onSaved: () {
          // 다음 계정의 다이얼로그가 필요하면 표시
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _checkMonthEnd();
            }
          });
        },
      ),
    );
  }

  void _showMonthEndDialogForAllAccounts() {
    final accounts = AccountService().accounts;
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('등록된 계정이 없습니다.')));
      return;
    }

    // 첫 번째 계정부터 시작
    int currentIndex = 0;

    void showNextDialog() {
      if (!mounted) return;
      if (currentIndex >= accounts.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('모든 계정의 월말 정산이 완료되었습니다.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => MonthEndCarryoverDialog(
          account: accounts[currentIndex],
          onSaved: () {
            currentIndex++;
            showNextDialog();
          },
        ),
      );
    }

    showNextDialog();
  }

  Future<void> _initialLoad() async {
    try {
      await _loadRootData();
    } catch (error, stackTrace) {
      debugPrint('ROOT dashboard load failure: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _isLoadingData = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        SnackbarUtils.showError(
          context,
          'ROOT 데이터 로드 중 문제가 발생했습니다. 다시 시도해 주세요.',
        );
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoadingData = false;
    });
    // 월말 체크
    _checkMonthEnd();
  }

  Future<void> _loadRootData() {
    return Future.wait([
      AccountService().loadAccounts(),
      TransactionService().loadTransactions(),
      CurrencyFormatter.initCurrencyUnit(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(IconCatalog.adminPanelSettings, color: Colors.amber),
              SizedBox(width: 8),
              Text('ROOT 관리자(전체 계정)'),
            ],
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final dashboard = TopLevelStatsUtils.buildDashboardContext();
    final currencyFormat = NumberFormats.currency;

    void doSearch(String query) {
      final allTx = dashboard.allTransactions;
      setState(() {
        if (isSearchFocused) {
          searchResults = List<Transaction>.from(allTx);
          return;
        }
        if (query.isEmpty) {
          searchResults = [];
          return;
        }

        final q = query;
        searchResults = allTx.where((t) {
          final memo = t.memo;
          final method = t.paymentMethod;
          return t.description.contains(q) ||
              (memo.isNotEmpty && memo.contains(q)) ||
              (method.isNotEmpty && method.contains(q)) ||
              t.amount.toString().contains(q);
        }).toList();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(IconCatalog.adminPanelSettings, color: Colors.amber),
            SizedBox(width: 8),
            Text('ROOT 관리자(전체 계정)'),
          ],
        ),
        actions: const [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RootSummaryCard(
              data: dashboard.summaryData,
              onViewDetail: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        TopLevelStatsDetailScreen(dashboard: dashboard),
                  ),
                );
              },
            ),
            if (dashboard.orphanAccountNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '삭제된 계정에서 남아있는 거래·고정비 데이터가 발견되었습니다: '
                      '${dashboard.orphanAccountNames.join(', ')}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    decoration: const InputDecoration(
                      labelText: '거래 검색 (설명, 메모, 금액, 지불수단)',
                      prefixIcon: Icon(IconCatalog.search, size: 26),
                    ),
                    onChanged: doSearch,
                  ),
                ),
                IconButton(
                  icon: const Icon(IconCatalog.clear),
                  onPressed: () {
                    searchController.clear();
                    doSearch('');
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (isSearchFocused) {
                    return RootTransactionList(
                      transactions: searchResults,
                      transactionAccountMap: dashboard.transactionAccountMap,
                      isFocused: true,
                      currencyFormat: currencyFormat,
                    );
                  }
                  if (searchController.text.isEmpty) {
                    return const Center(child: Text('검색어를 입력하세요.'));
                  }
                  return RootTransactionList(
                    transactions: searchResults,
                    transactionAccountMap: dashboard.transactionAccountMap,
                    isFocused: false,
                    currencyFormat: currencyFormat,
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_buildAccountControlButtons()],
            ),
          ],
        ),
      ),
    );
  }
}

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
          Card(
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
                    valueColor:
                        Colors.amber[800] ?? theme.colorScheme.secondary,
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
                    final accountName = summary.name.isEmpty
                        ? '미분류'
                        : summary.name;
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
          const SizedBox(height: 16),
          Text('상위 지출·예금', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (topOutflows.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('표시할 거래가 없습니다.'),
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
                            flex: 5,
                            child: Text(
                              '내용',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Text(
                              '계정 · 날짜 · 결제',
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
                              '금액',
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
                  ...topOutflows.take(20).map((tx) {
                    final accountName = accountById[tx.id] ?? '미분류';
                    final paymentPart = tx.paymentMethod.isNotEmpty
                        ? ' · ${tx.paymentMethod}'
                        : '';
                    final datePart = dateFormat.format(tx.date);
                    final subtitle = '$accountName · $datePart$paymentPart';
                    final amount = _formatAmountByType(
                      currencyFormat,
                      tx.amount,
                      tx.type,
                    );

                    if (isLandscape) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _iconForType(tx.type),
                              size: 18,
                              color: _colorForType(tx.type, theme),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 5,
                              child: Text(
                                tx.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: Text(
                                subtitle,
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
                                amount,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListTile(
                      leading: Icon(
                        _iconForType(tx.type),
                        color: _colorForType(tx.type, theme),
                      ),
                      title: Text(tx.description),
                      subtitle: Text(subtitle),
                      trailing: Text(amount),
                    );
                  }),
                ],
              ),
            ),
          if (hasFixedCosts) ...[
            const SizedBox(height: 16),
            Text('등록된 고정비용', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  if (isLandscape)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              '항목',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 6,
                            child: Text(
                              '계정 · 정보',
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
                              '금액',
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
                  ...allFixedCosts.take(30).map((entry) {
                    final accountName = entry.accountName.isEmpty
                        ? '미분류'
                        : entry.accountName;
                    final subtitle =
                        '$accountName · ${_fixedCostSubtitle(entry.cost)}';
                    final amount = _formatAmountByType(
                      currencyFormat,
                      entry.cost.amount,
                      TransactionType.expense,
                    );

                    if (isLandscape) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            const Icon(IconCatalog.receiptLong, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 4,
                              child: Text(
                                entry.cost.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Expanded(
                              flex: 6,
                              child: Text(
                                subtitle,
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
                                amount,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListTile(
                      leading: const Icon(IconCatalog.receiptLong),
                      title: Text(entry.cost.name),
                      subtitle: Text(subtitle),
                      trailing: Text(amount),
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildSummaryRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
          ),
        ],
      ),
    );
  }

  static String _formatCurrency(
    NumberFormat format,
    double value, {
    bool includeSign = false,
  }) {
    final formatted = format.format(value.abs());
    if (!includeSign) {
      return '$formatted원';
    }
    if (value > 0) {
      return '+$formatted원';
    }
    if (value < 0) {
      return '-$formatted원';
    }
    return '$formatted원';
  }

  static String _formatAmountByType(
    NumberFormat format,
    double value,
    TransactionType type,
  ) {
    final formatted = format.format(value.abs());
    return '${type.sign}$formatted원';
  }

  static IconData _iconForType(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return IconCatalog.trendingUp;
      case TransactionType.savings:
        return IconCatalog.savings;
      case TransactionType.expense:
        return IconCatalog.trendingDown;
      case TransactionType.refund:
        return RefundUtils.icon;
    }
  }

  static Color _colorForType(TransactionType type, ThemeData theme) {
    switch (type) {
      case TransactionType.income:
        return theme.colorScheme.primary;
      case TransactionType.savings:
        return Colors.amber[700] ?? theme.colorScheme.secondary;
      case TransactionType.expense:
        return theme.colorScheme.error;
      case TransactionType.refund:
        return RefundUtils.color;
    }
  }

  static String _fixedCostSubtitle(FixedCost cost) {
    final parts = <String>[];
    if (cost.paymentMethod.isNotEmpty) {
      parts.add(cost.paymentMethod);
    }
    if (cost.vendor != null && cost.vendor!.trim().isNotEmpty) {
      parts.add(cost.vendor!.trim());
    }
    if (cost.dueDay != null) {
      parts.add('매월 ${cost.dueDay}일');
    }
    if (cost.memo != null && cost.memo!.trim().isNotEmpty) {
      parts.add(cost.memo!.trim());
    }
    if (parts.isEmpty) {
      return '추가 정보 없음';
    }
    return parts.join(' · ');
  }
}

class _AccountAggregate {
  const _AccountAggregate({
    required this.name,
    required this.income,
    required this.expense,
    required this.savings,
    required this.refund,
    required this.fixedCost,
  });

  final String name;
  final double income;
  final double expense;
  final double savings;
  final double refund;
  final double fixedCost;

  double get net => income + refund - expense - savings - fixedCost;
}
