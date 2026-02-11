part of 'in_app_screen_saver.dart';
// ignore_for_file: invalid_use_of_protected_member

extension InAppScreenSaverLogic on _InAppScreenSaverState {
  void _initMain() {
    _startTimers();
    _loadExposureConfig();
    _loadBackgroundPhoto();
    _refreshData();
  }

  void _startTimers() {
    _clockTimer?.cancel();
    _refreshTimer?.cancel();

    _clockTimer = Timer.periodic(_clockTick, (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });

    _refreshTimer = Timer.periodic(_dataRefreshTick, (_) {
      _refreshData();
    });
  }

  Future<void> _loadBackgroundPhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final path = prefs.getString(
        PrefKeys.screenSaverLocalBackgroundImagePath,
      );
      if (path == null || path.trim().isEmpty) return;
      final file = File(path);
      if (!file.existsSync()) return;
      if (!mounted) return;
      setState(() => _backgroundPhotoPath = path);
    } catch (_) {
      // Ignore.
    }
  }

  Future<void> _loadExposureConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final config = _ScreenSaverExposureConfig(
        showAssetSummary:
            prefs.getBool(PrefKeys.screenSaverShowAssetSummary) ?? true,
        showCharts: prefs.getBool(PrefKeys.screenSaverShowCharts) ?? true,
        showBudget: prefs.getBool(PrefKeys.screenSaverShowBudget) ?? true,
        showEmergency: prefs.getBool(PrefKeys.screenSaverShowEmergency) ?? true,
        showSpending: prefs.getBool(PrefKeys.screenSaverShowSpending) ?? true,
        showRecent: prefs.getBool(PrefKeys.screenSaverShowRecent) ?? true,
        showAssetFlow: prefs.getBool(PrefKeys.screenSaverShowAssetFlow) ?? true,
      );
      if (!mounted) return;
      setState(() => _exposure = config);
    } catch (_) {
      // Keep defaults.
    }
  }

  Future<void> _refreshData() async {
    try {
      await AssetService().loadAssets();
      await TransactionService().loadTransactions();
      await BudgetService().loadBudgets();
      await EmergencyFundService().ensureLoaded();
      await AssetMoveService().loadMoves();

      final assets = AssetService().getAssets(widget.accountName);
      final txs = TransactionService().getTransactions(widget.accountName);
      final plannedBudget = BudgetService().getBudget(widget.accountName);
      final emergencyTxs = EmergencyFundService().getTransactions(
        widget.accountName,
      );
      final moves = AssetMoveService().getMoves(widget.accountName);

      unawaited(
        MonthlyAggCacheService().autoEnsureBuiltIfDirtyThrottled(
          accountName: widget.accountName,
          transactions: txs,
        ),
      );

      final summary = AssetManagementUtils.generateDashboardSummary(assets);
      final spending = _computeSpending(txs, now: DateTime.now());
      final emergency = _computeEmergency(emergencyTxs, now: DateTime.now());
      final recentTx = _computeRecentTransactions(txs);

      final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month);
      final end = DateTime.now();
      final flow = AssetFlowStats.compute(moves, start: startOfMonth, end: end);

      await _upsertMonthlyAssetSnapshot(
        accountName: widget.accountName,
        totalAssets: summary.totalAssets,
      );

      final trend = await _loadMonthlyAssetTrend(
        accountName: widget.accountName,
        months: 6,
      );

      if (!mounted) return;
      setState(() {
        _data = _DashboardData(
          assets: assets,
          dashboardSummary: summary,
          todayOutflowCount: spending.todayOutflowCount,
          monthOutflowCount: spending.monthOutflowCount,
          plannedBudget: plannedBudget,
          monthOutflow: spending.monthOutflow,
          emergencyBalance: emergency.balance,
          emergencyUsedThisMonth: emergency.usedThisMonth,
          recent: recentTx,
          assetFlow: flow,
          trend: trend,
        );
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _tryDismissWithAuth() async {
    if (_authInProgress) return;
    setState(() => _authInProgress = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final prefs = await SharedPreferences.getInstance();
      final lockedUntilMs = prefs.getInt(
        PrefKeys.screenSaverExitAuthLockedUntilMs,
      );
      if (lockedUntilMs != null) {
        final remainingMs =
            lockedUntilMs - DateTime.now().millisecondsSinceEpoch;
        if (remainingMs > 0) {
          final minutes = (remainingMs / 60000).ceil();
          if (mounted) {
            messenger?.showSnackBar(
              SnackBar(
                content: Text('보호기 종료 인증이 잠금 상태입니다. 약 $minutes분 후 다시 시도하세요'),
              ),
            );
          }
          return;
        } else {
          await prefs.remove(PrefKeys.screenSaverExitAuthLockedUntilMs);
          await prefs.remove(PrefKeys.screenSaverExitAuthFailedAttempts);
        }
      }

      final auth = LocalAuthentication();
      final canAuth =
          await auth.canCheckBiometrics || await auth.isDeviceSupported();

      if (!canAuth) {
        widget.onDismiss();
        return;
      }

      final ok = await auth.authenticate(
        localizedReason: '화면 보호기를 종료하려면 인증이 필요합니다',
      );
      if (ok) {
        await prefs.remove(PrefKeys.screenSaverExitAuthFailedAttempts);
        await prefs.remove(PrefKeys.screenSaverExitAuthLockedUntilMs);
        widget.onDismiss();
      } else {
        final current =
            prefs.getInt(PrefKeys.screenSaverExitAuthFailedAttempts) ?? 0;
        final next = current + 1;
        if (next >= _exitAuthMaxFailedAttempts) {
          await prefs.setInt(
            PrefKeys.screenSaverExitAuthLockedUntilMs,
            DateTime.now().add(_exitAuthLockDuration).millisecondsSinceEpoch,
          );
          await prefs.remove(PrefKeys.screenSaverExitAuthFailedAttempts);

          if (mounted) {
            messenger?.showSnackBar(
              const SnackBar(
                content: Text('보호기 종료 인증이 잠금 처리되었습니다. 10분 후 다시 시도하세요'),
              ),
            );
          }
        } else {
          await prefs.setInt(PrefKeys.screenSaverExitAuthFailedAttempts, next);
        }
      }
    } catch (_) {
      // Ignore and keep the screen saver shown.
    } finally {
      if (mounted) {
        setState(() => _authInProgress = false);
      }
    }
  }
}
