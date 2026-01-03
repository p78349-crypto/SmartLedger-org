import 'package:flutter/material.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/screens/account_home_screen.dart';
import 'package:smart_ledger/screens/account_stats_screen.dart';
import 'package:smart_ledger/screens/asset_tab_screen.dart';
import 'package:smart_ledger/screens/fixed_cost_tab_screen.dart';
import 'package:smart_ledger/screens/root_account_manager_page.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/period_utils.dart' as period;
import 'package:smart_ledger/utils/stats_labels.dart';
import 'package:smart_ledger/utils/user_main_actions.dart';
import 'package:smart_ledger/widgets/month_end_carryover_dialog.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({
    super.key,
    required this.accountName,
    this.initialIndex = 0,
  });

  final String accountName;
  final int initialIndex;

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  static const List<String> _tabTitles = ['거래', '통계', '자산', '고정비', 'ROOT'];

  late int _currentIndex;
  int _statsRefreshToken = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = _normalizeIndex(widget.initialIndex);
    _screens = _buildScreens();
  }

  @override
  void didUpdateWidget(covariant HomeTabScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.accountName != widget.accountName) {
      _screens = _buildScreens();
    }
  }

  int _normalizeIndex(int value) {
    if (value < 0) {
      return 0;
    }
    if (value >= _tabTitles.length) {
      return _tabTitles.length - 1;
    }
    return value;
  }

  void _openSearch() {
    UserMainActions.openSearch(
      Navigator.of(context),
      account: widget.accountName,
    );
  }

  void _openTrash() {
    UserMainActions.openTrash(Navigator.of(context));
  }

  List<Widget> _buildScreens() {
    return [
      AccountHomeScreen(accountName: widget.accountName),
      _createStatsScreen(),
      AssetTabScreen(
        accountName: widget.accountName,
        showAccountHeading: false,
      ),
      FixedCostTabScreen(accountName: widget.accountName),
      RootAccountManagerPage(
        embed: true,
        onAccountSelected: (name) => _switchAccount(name, initialIndex: 0),
        onOpenSearch: _openSearch,
        onOpenTrash: _openTrash,
      ),
    ];
  }

  Widget _createStatsScreen() {
    return AccountStatsScreen(
      key: ValueKey('stats-${widget.accountName}-$_statsRefreshToken'),
      accountName: widget.accountName,
      embed: true,
    );
  }

  void _refreshStatsScreen() {
    _statsRefreshToken++;
    _screens[1] = _createStatsScreen();
  }

  Future<void> _switchAccount(String selected, {int? initialIndex}) async {
    final navigator = Navigator.of(context);
    final rawIndex =
        initialIndex ??
        (_currentIndex >= _tabTitles.length - 1 ? 0 : _currentIndex);
    final maxUserTabIndex = _tabTitles.length - 2;
    final targetIndex = rawIndex < 0
        ? 0
        : rawIndex > maxUserTabIndex
        ? maxUserTabIndex
        : rawIndex;

    await UserMainActions.persistAccountSelection(context, selected);
    if (!mounted) return;

    navigator.pushNamedAndRemoveUntil(
      AppRoutes.accountMain,
      (route) => false,
      arguments: AccountMainArgs(
        accountName: selected,
        initialIndex: targetIndex,
      ),
    );
  }

  String _titleForIndex(int index) {
    if (index == 2) {
      return '${widget.accountName}님의 자산';
    }
    return _tabTitles[index];
  }

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
              key: ValueKey('stats-${widget.accountName}-decade'),
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
              Text(period.PeriodUtils.getPeriodLabel(period.PeriodType.decade)),
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
              // 거래 상세내역 화면 (지출)
              try {
                if (!mounted) return;
                final result = await UserMainActions.openTransactionDetail(
                  Navigator.of(context),
                  account: widget.accountName,
                  initialType: TransactionType.expense,
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
            } else if (value == 'income_details') {
              // 수입 상세내역 화면
              try {
                if (!mounted) return;
                final result = await UserMainActions.openTransactionDetail(
                  Navigator.of(context),
                  account: widget.accountName,
                  initialType: TransactionType.income,
                );
                if (result == true && mounted) {
                  setState(() {
                    _screens = _buildScreens();
                  });
                }
              } catch (e, stackTrace) {
                debugPrint('수입 상세내역 화면 열기 오류: $e');
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
            } else if (value == 'income') {
              // 수입배분
              await UserMainActions.openIncomeSplit(
                Navigator.of(context),
                account: widget.accountName,
              );
            } else if (value == 'carryover') {
              // 이월
              final accounts = AccountService().getAccountByName(
                widget.accountName,
              );
              if (accounts != null && mounted) {
                showDialog(
                  context: context,
                  builder: (context) => MonthEndCarryoverDialog(
                    account: accounts,
                    onSaved: () {},
                  ),
                );
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'transaction_details',
              child: Row(
                children: [
                  Icon(IconCatalog.listAlt, size: 20, color: Colors.deepPurple),
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

  @override
  Widget build(BuildContext context) {
    final canPop =
        ModalRoute.of(context)?.canPop ?? Navigator.of(context).canPop();
    final isRootTab = _currentIndex == _tabTitles.length - 1;
    final isStatsTab = _currentIndex == 1; // 통계 탭
    final titleText = isRootTab ? null : _titleForIndex(_currentIndex);

    return PopScope(
      canPop: !canPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (navigator.canPop()) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          leading: canPop
              ? IconButton(
                  icon: const Icon(IconCatalog.arrowBack),
                  tooltip: '메인으로 돌아가기',
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                )
              : (isStatsTab
                    ? _buildStatsMenuButton(context)
                    : (_currentIndex == 2
                          ? Builder(
                              builder: (ctx) => IconButton(
                                icon: const Icon(IconCatalog.menu),
                                tooltip: '자산 메뉴 열기',
                                onPressed: () {
                                  Scaffold.of(ctx).openDrawer();
                                },
                              ),
                            )
                          : null)),
          title: isRootTab
              ? const Text('ROOT 관리자')
              : Text(titleText ?? '${widget.accountName}님 가계부'),
          actions: isRootTab ? const [] : _buildAccountActions(),
        ),
        drawer: _currentIndex == 2 ? _buildAssetDrawer(context) : null,
        body: IndexedStack(index: _currentIndex, children: _screens),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            setState(() {
              _currentIndex = i;
              if (i == 1) {
                _refreshStatsScreen();
              }
            });
          },
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(IconCatalog.list), label: '거래'),
            BottomNavigationBarItem(
              icon: Icon(IconCatalog.barChart),
              label: '통계',
            ),
            BottomNavigationBarItem(
              icon: Icon(IconCatalog.accountBalanceWallet),
              label: '자산',
            ),
            BottomNavigationBarItem(
              icon: Icon(IconCatalog.payments),
              label: '고정비',
            ),
            BottomNavigationBarItem(
              icon: Icon(IconCatalog.adminPanelSettings),
              label: 'ROOT',
            ),
          ],
        ),
      ),
    );
  }
}

