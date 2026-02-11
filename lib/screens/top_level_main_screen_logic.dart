part of 'top_level_main_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension TopLevelMainScreenLogic on _TopLevelMainScreenState {
  Future<void> _initializeServices() async {
    await NotificationService().initialize();
  }

  void _onFocusChange() {
    setState(() {
      isSearchFocused = searchFocusNode.hasFocus;
    });
  }

  void _onSearchChanged() {
    setState(() {});
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
}
