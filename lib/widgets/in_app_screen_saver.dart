import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
// intl removed: use DateFormatter for formatting
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';
import '../models/asset_move.dart';
import '../services/asset_move_service.dart';
import '../services/asset_service.dart';
import '../services/budget_service.dart';
import '../services/emergency_fund_service.dart';
import '../services/monthly_agg_cache_service.dart';
import '../services/transaction_service.dart';
import '../utils/asset_dashboard_utils.dart';
import '../utils/asset_flow_stats.dart';
import '../utils/date_formatter.dart';
import '../utils/icon_catalog.dart';
import '../utils/pref_keys.dart';

class InAppScreenSaver extends StatefulWidget {
  final String accountName;
  final String title;
  final VoidCallback onDismiss;

  const InAppScreenSaver({
    super.key,
    required this.accountName,
    required this.title,
    required this.onDismiss,
  });

  @override
  State<InAppScreenSaver> createState() => _InAppScreenSaverState();
}

class _InAppScreenSaverState extends State<InAppScreenSaver> {
  static const int _exitAuthMaxFailedAttempts = 5;
  static const Duration _exitAuthLockDuration = Duration(minutes: 10);
  static const Duration _clockTick = Duration(seconds: 1);
  static const Duration _dataRefreshTick = Duration(seconds: 15);

  Timer? _clockTimer;
  Timer? _refreshTimer;

  DateTime _now = DateTime.now();
  _DashboardData? _data;
  String? _error;
  bool _authInProgress = false;

  _ScreenSaverExposureConfig _exposure = const _ScreenSaverExposureConfig();
  String? _backgroundPhotoPath;

  @override
  void initState() {
    super.initState();
    _startTimers();
    _loadExposureConfig();
    _loadBackgroundPhoto();
    _refreshData();
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

  @override
  void dispose() {
    _clockTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
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

      // Pre-generate monthly numeric caches (dirty months only).
      // This keeps month/year stats fast even with large datasets.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 820;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: Stack(
          children: [
            if (_backgroundPhotoPath != null)
              Positioned.fill(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    scheme.surface.withValues(alpha: 0.78),
                    BlendMode.srcATop,
                  ),
                  child: Image.file(
                    File(_backgroundPhotoPath!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _tryDismissWithAuth,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _HeaderBar(title: widget.title, now: _now),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _error != null
                          ? _ErrorPanel(message: _error!, onRetry: _refreshData)
                          : (_data == null
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : isWide
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: 280,
                                        child: _LeftPanel(
                                          data: _data!,
                                          exposure: _exposure,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _CenterPanel(
                                          data: _data!,
                                          exposure: _exposure,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 280,
                                        child: _RightPanel(
                                          data: _data!,
                                          exposure: _exposure,
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView(
                                    children: [
                                      _CenterPanel(
                                        data: _data!,
                                        exposure: _exposure,
                                      ),
                                      const SizedBox(height: 12),
                                      _LeftPanel(
                                        data: _data!,
                                        exposure: _exposure,
                                      ),
                                      const SizedBox(height: 12),
                                      _RightPanel(
                                        data: _data!,
                                        exposure: _exposure,
                                      ),
                                    ],
                                  )),
                    ),
                    const SizedBox(height: 12),
                    _FooterBar(
                      authInProgress: _authInProgress,
                      onQuickReturn: _tryDismissWithAuth,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final String title;
  final DateTime now;

  const _HeaderBar({required this.title, required this.now});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateText = DateFormatter.dateWithWeekdayTimeSeconds.format(now);

    return Row(
      children: [
        Icon(IconCatalog.shieldOutlined, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          dateText,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FooterBar extends StatelessWidget {
  final bool authInProgress;
  final VoidCallback onQuickReturn;

  const _FooterBar({required this.authInProgress, required this.onQuickReturn});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        Icon(IconCatalog.lockOutline, color: scheme.onSurfaceVariant, size: 18),
        const SizedBox(width: 6),
        Text(
          '보호 모드',
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: authInProgress ? null : onQuickReturn,
          icon: const Icon(IconCatalog.verifiedUserOutlined),
          label: Text(authInProgress ? '인증 중...' : '빠른 복귀'),
        ),
      ],
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('데이터를 불러오지 못했습니다', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              message,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

class _LeftPanel extends StatelessWidget {
  final _DashboardData data;
  final _ScreenSaverExposureConfig exposure;
  const _LeftPanel({required this.data, required this.exposure});

  @override
  Widget build(BuildContext context) {
    final showBudget = exposure.showBudget;
    final showEmergency = exposure.showEmergency;

    return Column(
      children: [
        if (showBudget)
          _BudgetCard(planned: data.plannedBudget, used: data.monthOutflow),
        if (showBudget && showEmergency) const SizedBox(height: 12),
        if (showEmergency)
          _EmergencyCard(
            balance: data.emergencyBalance,
            usedThisMonth: data.emergencyUsedThisMonth,
          ),
      ],
    );
  }
}

class _CenterPanel extends StatelessWidget {
  final _DashboardData data;
  final _ScreenSaverExposureConfig exposure;
  const _CenterPanel({required this.data, required this.exposure});

  @override
  Widget build(BuildContext context) {
    final showAssetSummary = exposure.showAssetSummary;
    final showCharts = exposure.showCharts;

    return Column(
      children: [
        if (showAssetSummary) _AssetTotalsCard(summary: data.dashboardSummary),
        if (showAssetSummary && showCharts) const SizedBox(height: 12),
        if (showCharts)
          Expanded(
            child: Row(
              children: [
                Expanded(child: _AllocationChartCard(assets: data.assets)),
                const SizedBox(width: 12),
                Expanded(child: _TrendChartCard(points: data.trend)),
              ],
            ),
          )
        else
          const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}

class _RightPanel extends StatelessWidget {
  final _DashboardData data;
  final _ScreenSaverExposureConfig exposure;
  const _RightPanel({required this.data, required this.exposure});

  @override
  Widget build(BuildContext context) {
    final showSpending = exposure.showSpending;
    final showRecent = exposure.showRecent;
    final showAssetFlow = exposure.showAssetFlow;

    return Column(
      children: [
        if (showSpending)
          _SpendingCard(
            todayCount: data.todayOutflowCount,
            monthCount: data.monthOutflowCount,
          ),
        if (showSpending && showRecent) const SizedBox(height: 12),
        if (showRecent) _RecentTransactionsCard(recent: data.recent),
        if ((showSpending || showRecent) && showAssetFlow)
          const SizedBox(height: 12),
        if (showAssetFlow) _AssetFlowCard(flow: data.assetFlow),
      ],
    );
  }
}

class _ScreenSaverExposureConfig {
  final bool showAssetSummary;
  final bool showCharts;
  final bool showBudget;
  final bool showEmergency;
  final bool showSpending;
  final bool showRecent;
  final bool showAssetFlow;

  const _ScreenSaverExposureConfig({
    this.showAssetSummary = true,
    this.showCharts = true,
    this.showBudget = true,
    this.showEmergency = true,
    this.showSpending = true,
    this.showRecent = true,
    this.showAssetFlow = true,
  });
}

class _CardShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _CardShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _AssetTotalsCard extends StatelessWidget {
  final DashboardSummary summary;
  const _AssetTotalsCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '총 자산',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '보호됨',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '손익',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        summary.totalProfitLoss > 0
                            ? IconCatalog.trendingUp
                            : (summary.totalProfitLoss < 0
                                  ? IconCatalog.trendingDown
                                  : IconCatalog.remove),
                        color: summary.profitLossColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        summary.profitLossLabel,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: summary.profitLossColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '비율 보호됨',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllocationChartCard extends StatelessWidget {
  final List<Asset> assets;

  const _AllocationChartCard({required this.assets});

  @override
  Widget build(BuildContext context) {
    final totals = <AssetCategory, double>{
      for (final c in AssetCategory.values) c: 0,
    };
    for (final a in assets) {
      totals[a.category] = (totals[a.category] ?? 0) + a.amount;
    }
    final nonZero = totals.entries.where((e) => e.value > 0).toList();
    final sum = nonZero.fold<double>(0, (s, e) => s + e.value);

    return _CardShell(
      title: '자산 배분',
      child: SizedBox(
        height: 220,
        child: sum == 0
            ? const Center(child: Text('데이터 없음'))
            : PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 46,
                  sections: nonZero
                      .map((e) {
                        final color = Color(e.key.color);
                        final value = e.value;
                        return PieChartSectionData(
                          color: color,
                          value: value,
                          title: '',
                          radius: 64,
                        );
                      })
                      .toList(growable: false),
                ),
              ),
      ),
    );
  }
}

class _TrendChartCard extends StatelessWidget {
  final List<_TrendPoint> points;
  const _TrendChartCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (points.isEmpty) {
      return const _CardShell(title: '월별 자산 추이', child: Text('데이터 없음'));
    }

    // Normalize values into 0..100 so the chart shows *shape* only.
    final ys = <double>[for (final p in points) p.totalAssets];
    final minRaw = ys.reduce((a, b) => a < b ? a : b);
    final maxRaw = ys.reduce((a, b) => a > b ? a : b);
    final span = (maxRaw - minRaw).abs();

    double normalize(double v) {
      if (span == 0) return 50;
      return ((v - minRaw) / span) * 100;
    }

    return _CardShell(
      title: '월별 자산 추이',
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: 100,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= points.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        points[i].label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: scheme.primary,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: scheme.primary.withValues(alpha: 0.12),
                ),
                spots: [
                  for (var i = 0; i < points.length; i++)
                    FlSpot(i.toDouble(), normalize(points[i].totalAssets)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final double planned;
  final double used;
  const _BudgetCard({required this.planned, required this.used});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final pct = planned <= 0 ? 0.0 : (used / planned).clamp(0.0, 2.0);
    return _CardShell(
      title: '예산',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이번달 사용률',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: planned <= 0 ? 0 : pct.clamp(0.0, 1.0),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            planned <= 0 ? '계획 예산이 설정되지 않았습니다' : '지출 금액은 보호됩니다',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  final double balance;
  final double usedThisMonth;

  const _EmergencyCard({required this.balance, required this.usedThisMonth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _CardShell(
      title: '비상금',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '잔액 보호됨',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            usedThisMonth > 0 ? '이번달 사용 기록 있음' : '이번달 사용 기록 없음',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpendingCard extends StatelessWidget {
  final int todayCount;
  final int monthCount;

  const _SpendingCard({required this.todayCount, required this.monthCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _CardShell(
      title: '지출 요약',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '오늘',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$todayCount건',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '이번달',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                '$monthCount건',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '금액은 보호됩니다',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  final _RecentTxSummary recent;
  const _RecentTransactionsCard({required this.recent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _CardShell(
      title: '최근 거래',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 7일 거래 요약(금액 보호)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TinyStat(
                  label: '지출건수',
                  value: '${recent.outflowCount7d}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TinyStat(
                  label: '수입건수',
                  value: '${recent.inflowCount7d}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssetFlowCard extends StatelessWidget {
  final AssetFlowStats flow;
  const _AssetFlowCard({required this.flow});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return _CardShell(
      title: '자산 흐름(이번달)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '유입/유출은 보호됩니다(건수만 표시)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TinyStat(
                  label: '매도',
                  value: '${flow.countByType[AssetMoveType.sale] ?? 0}건',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TinyStat(
                  label: '매수',
                  value: '${flow.countByType[AssetMoveType.purchase] ?? 0}건',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _TinyStat(
            label: '예금',
            value: '${flow.countByType[AssetMoveType.deposit] ?? 0}건',
          ),
        ],
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  final String label;
  final String value;
  const _TinyStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardData {
  final List<Asset> assets;
  final DashboardSummary dashboardSummary;
  final int todayOutflowCount;
  final int monthOutflowCount;
  final double plannedBudget;
  final double monthOutflow;
  final double emergencyBalance;
  final double emergencyUsedThisMonth;
  final _RecentTxSummary recent;
  final AssetFlowStats assetFlow;
  final List<_TrendPoint> trend;

  const _DashboardData({
    required this.assets,
    required this.dashboardSummary,
    required this.todayOutflowCount,
    required this.monthOutflowCount,
    required this.plannedBudget,
    required this.monthOutflow,
    required this.emergencyBalance,
    required this.emergencyUsedThisMonth,
    required this.recent,
    required this.assetFlow,
    required this.trend,
  });
}

class _SpendingStats {
  final double todayOutflow;
  final double monthOutflow;
  final int todayOutflowCount;
  final int monthOutflowCount;
  const _SpendingStats({
    required this.todayOutflow,
    required this.monthOutflow,
    required this.todayOutflowCount,
    required this.monthOutflowCount,
  });
}

_SpendingStats _computeSpending(List<dynamic> txs, {required DateTime now}) {
  double todayOutflow = 0;
  double monthOutflow = 0;
  int todayOutflowCount = 0;
  int monthOutflowCount = 0;

  for (final raw in txs) {
    final tx = raw as dynamic;
    if (tx.sign != '-') continue;
    final amount = (tx.amount as num).toDouble().abs();
    final d = tx.date as DateTime;
    if (d.year == now.year && d.month == now.month) {
      monthOutflow += amount;
      monthOutflowCount++;
    }
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      todayOutflow += amount;
      todayOutflowCount++;
    }
  }

  return _SpendingStats(
    todayOutflow: todayOutflow,
    monthOutflow: monthOutflow,
    todayOutflowCount: todayOutflowCount,
    monthOutflowCount: monthOutflowCount,
  );
}

class _EmergencyStats {
  final double balance;
  final double usedThisMonth;
  const _EmergencyStats({required this.balance, required this.usedThisMonth});
}

_EmergencyStats _computeEmergency(List<dynamic> txs, {required DateTime now}) {
  double balance = 0;
  double usedThisMonth = 0;
  for (final raw in txs) {
    final t = raw as dynamic;
    final amount = (t.amount as num).toDouble();
    final d = t.date as DateTime;
    balance += amount;
    if (d.year == now.year && d.month == now.month && amount < 0) {
      usedThisMonth += amount.abs();
    }
  }
  return _EmergencyStats(balance: balance, usedThisMonth: usedThisMonth);
}

class _RecentTxSummary {
  final double outflow7d;
  final double inflow7d;
  final int outflowCount7d;
  final int inflowCount7d;
  const _RecentTxSummary({
    required this.outflow7d,
    required this.inflow7d,
    required this.outflowCount7d,
    required this.inflowCount7d,
  });
}

_RecentTxSummary _computeRecentTransactions(List<dynamic> txs) {
  final now = DateTime.now();
  final start = now.subtract(const Duration(days: 7));

  double outflow = 0;
  double inflow = 0;
  int outflowCount = 0;
  int inflowCount = 0;

  for (final raw in txs) {
    final tx = raw as dynamic;
    final d = tx.date as DateTime;
    if (d.isBefore(start)) continue;
    final amount = (tx.amount as num).toDouble().abs();
    if (tx.sign == '-') {
      outflow += amount;
      outflowCount++;
    } else if (tx.sign == '+') {
      inflow += amount;
      inflowCount++;
    }
  }

  return _RecentTxSummary(
    outflow7d: outflow,
    inflow7d: inflow,
    outflowCount7d: outflowCount,
    inflowCount7d: inflowCount,
  );
}

class _TrendPoint {
  final String monthKey;
  final String label;
  final double totalAssets;
  const _TrendPoint({
    required this.monthKey,
    required this.label,
    required this.totalAssets,
  });
}

Future<void> _upsertMonthlyAssetSnapshot({
  required String accountName,
  required double totalAssets,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(PrefKeys.assetMonthlySnapshots);
  final Map<String, dynamic> root = raw != null && raw.isNotEmpty
      ? (jsonDecode(raw) as Map<String, dynamic>)
      : <String, dynamic>{};

  final key = DateFormatter.yearMonth.format(DateTime.now());
  final account = Map<String, dynamic>.from(root[accountName] as Map? ?? {});
  // Store a coarse-rounded value to avoid retaining sensitive precision.
  final rounded = (totalAssets / 10000000).round() * 10000000;
  account[key] = rounded;
  root[accountName] = account;

  await prefs.setString(PrefKeys.assetMonthlySnapshots, jsonEncode(root));
}

Future<List<_TrendPoint>> _loadMonthlyAssetTrend({
  required String accountName,
  required int months,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(PrefKeys.assetMonthlySnapshots);
  if (raw == null || raw.isEmpty) {
    // No history: show a flat baseline with the latest known value.
    return const <_TrendPoint>[];
  }
  final decoded = jsonDecode(raw);
  if (decoded is! Map) return const <_TrendPoint>[];
  final account = decoded[accountName];
  if (account is! Map) return const <_TrendPoint>[];

  final now = DateTime.now();
  final points = <_TrendPoint>[];
  for (var i = months - 1; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i);
    final key = DateFormatter.yearMonth.format(d);
    final label = DateFormatter.shortMonth.format(d);
    final rawValue = account[key];
    final value = rawValue is num ? rawValue.toDouble() : 0.0;
    points.add(_TrendPoint(monthKey: key, label: label, totalAssets: value));
  }
  return points;
}
