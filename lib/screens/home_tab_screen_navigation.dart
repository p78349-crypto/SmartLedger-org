part of 'home_tab_screen.dart';

extension _HomeTabNavigation on _HomeTabScreenState {
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
        onAccountSelected: (name) {
          _switchAccount(name, initialIndex: 0);
        },
        onOpenSearch: _openSearch,
        onOpenTrash: _openTrash,
      ),
    ];
  }

  Widget _createStatsScreen() {
    return AccountStatsScreen(
      key: ValueKey(
        'stats-${widget.accountName}-$_statsRefreshToken',
      ),
      accountName: widget.accountName,
      embed: true,
    );
  }

  void _refreshStatsScreen() {
    _statsRefreshToken++;
    _screens[1] = _createStatsScreen();
  }

  Future<void> _switchAccount(
    String selected, {
    int? initialIndex,
  }) async {
    final navigator = Navigator.of(context);
    final rawIndex = initialIndex ??
        (_currentIndex >= _HomeTabScreenState._tabTitles.length - 1
            ? 0
            : _currentIndex);
    final maxUserTabIndex = _HomeTabScreenState._tabTitles.length - 2;
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
    return _HomeTabScreenState._tabTitles[index];
  }
}
