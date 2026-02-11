part of 'in_app_screen_saver.dart';

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
