// ignore_for_file: invalid_use_of_protected_member
part of 'home_tab_screen.dart';

extension _HomeTabMenus on _HomeTabScreenState {
  Widget _buildStatsMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(IconCatalog.menu),
      onSelected: (value) {
        if (value == 'fixed_cost_stats') {
          Navigator.of(context).pushNamed(
            AppRoutes.fixedCostStats,
            arguments: AccountArgs(accountName: widget.accountName),
          );
        } else if (value == 'decade') {
          setState(() {
            _currentIndex = 1;
            _screens[1] = AccountStatsScreen(
              key: ValueKey(
                'stats-${widget.accountName}-decade',
              ),
              accountName: widget.accountName,
              embed: true,
              initialView: 'decade',
              initialRangeView: 'decade',
            );
          });
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(
          value: 'fixed_cost_stats',
          child: Row(
            children: [
              Icon(IconCatalog.barChart, size: 20),
              SizedBox(width: 8),
              Text(StatsLabels.fixedCostStats),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'decade',
          child: Row(
            children: [
              const Icon(IconCatalog.dateRange, size: 20),
              const SizedBox(width: 8),
              Text(
                period.PeriodUtils.getPeriodLabel(
                  period.PeriodType.decade,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openAssetDrawerNamedRoute(
    BuildContext parentContext,
    String routeName, {
    Object? arguments,
  }) {
    final navigator = Navigator.of(parentContext);
    navigator.pop();
    if (!mounted) return;
    navigator.pushNamed(routeName, arguments: arguments);
  }

  Widget _buildAssetDrawer(BuildContext parentContext) {
    final theme = Theme.of(parentContext);
    final onPrimary = theme.colorScheme.onPrimaryContainer;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '자산 메뉴',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.accountName} 계정',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: onPrimary,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(IconCatalog.dashboardCustomizeOutlined),
              title: const Text('자산 대시보드'),
              subtitle: const Text('전체 자산 흐름을 확인'),
              onTap: () => _openAssetDrawerNamedRoute(
                parentContext,
                AppRoutes.assetDashboard,
                arguments: AccountArgs(accountName: widget.accountName),
              ),
            ),
            ListTile(
              leading: const Icon(IconCatalog.pieChartOutline),
              title: const Text('자산 배분 통계'),
              subtitle: const Text('카테고리별 자산 구성을 분석'),
              onTap: () => _openAssetDrawerNamedRoute(
                parentContext,
                AppRoutes.assetAllocation,
                arguments: AccountArgs(accountName: widget.accountName),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(IconCatalog.quickreplyOutlined),
              title: const Text('간단 자산 입력'),
              onTap: () => _openAssetDrawerNamedRoute(
                parentContext,
                AppRoutes.assetSimpleInput,
                arguments: AccountArgs(accountName: widget.accountName),
              ),
            ),
            ListTile(
              leading: const Icon(IconCatalog.factCheckOutlined),
              title: const Text('상세 자산 입력'),
              onTap: () => _openAssetDrawerNamedRoute(
                parentContext,
                AppRoutes.assetDetailInput,
                arguments: AccountArgs(accountName: widget.accountName),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAccountActions() {
    return [
      IconButton(
        icon: const Icon(IconCatalog.deleteOutline),
        tooltip: '휴지통',
        onPressed: _openTrash,
      ),
      Tooltip(
        message: '메뉴 열기',
        child: PopupMenuButton<String>(
          icon: const Icon(IconCatalog.moreVert),
          onSelected: (value) async {
            if (value == 'transaction_details') {
              await _openTransactionDetails(TransactionType.expense);
            } else if (value == 'income_details') {
              await _openTransactionDetails(TransactionType.income);
            } else if (value == 'income') {
              await UserMainActions.openIncomeSplit(
                Navigator.of(context),
                account: widget.accountName,
              );
            } else if (value == 'carryover') {
              _openCarryoverDialog();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'transaction_details',
              child: Row(
                children: [
                  Icon(
                    IconCatalog.listAlt,
                    size: 20,
                    color: Colors.deepPurple,
                  ),
                  SizedBox(width: 8),
                  Text(StatsLabels.expenseDetails),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'income_details',
              child: Row(
                children: [
                  Icon(
                    IconCatalog.accountBalanceWallet,
                    size: 20,
                    color: Colors.green,
                  ),
                  SizedBox(width: 8),
                  Text(StatsLabels.incomeDetails),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'income',
              child: Row(
                children: [
                  Tooltip(
                    message: StatsLabels.incomeDistributionTooltip,
                    child: Icon(
                      IconCatalog.payment,
                      size: 20,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(StatsLabels.incomeDistributionMenu),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'carryover',
              child: Row(
                children: [
                  Icon(
                    IconCatalog.arrowForward,
                    size: 20,
                    color: Colors.purple,
                  ),
                  SizedBox(width: 8),
                  Text(StatsLabels.carryover),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Future<void> _openTransactionDetails(TransactionType type) async {
    try {
      if (!mounted) return;
      final result = await UserMainActions.openTransactionDetail(
        Navigator.of(context),
        account: widget.accountName,
        initialType: type,
      );
      if (result == true && mounted) {
        setState(() {
          _screens = _buildScreens();
        });
      }
    } catch (e, stackTrace) {
      debugPrint('거래 상세내역 화면 열기 오류: $e');
      debugPrint('스택 트레이스: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('화면을 열 수 없습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openCarryoverDialog() {
    final accounts = AccountService().getAccountByName(
      widget.accountName,
    );
    if (accounts == null || !mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => MonthEndCarryoverDialog(
        account: accounts,
        onSaved: () {},
      ),
    );
  }
}
