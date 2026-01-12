library;

import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../navigation/app_routes.dart';
import 'account_home_screen.dart';
import 'account_stats_screen.dart';
import 'asset_tab_screen.dart';
import 'fixed_cost_tab_screen.dart';
import 'root_account_manager_page.dart';
import '../services/account_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/period_utils.dart' as period;
import '../utils/stats_labels.dart';
import '../utils/user_main_actions.dart';
import '../widgets/month_end_carryover_dialog.dart';

part 'home_tab_screen_navigation.dart';
part 'home_tab_screen_menus.dart';

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
