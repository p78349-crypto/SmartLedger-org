part of 'account_stats_screen.dart';

/// 주간 점검 + 리포트 + 일별 타일.
extension AccountStatsWeekly on _AccountStatsScreenState {
  Widget _buildWeeklyCheckIcon(ThemeData theme) {
    return IconButton(
      icon: Icon(Icons.insights, color: theme.colorScheme.primary),
      tooltip: '주간 점검 (Weekly Checkup)',
      onPressed: _showWeeklyReport,
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.primaryContainer.withValues(
          alpha: 0.3,
        ),
      ),
    );
  }

  void _showWeeklyReport() async {
    final report = await SmartConsumingService().analyzeWeeklyStatus(
      widget.accountName,
    );
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        Color burnColor = scheme.primary;
        if (report.burnRate > 1.1) burnColor = scheme.error;
        if (report.burnRate < 0.9) burnColor = Colors.green;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.insights, color: scheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${report.currentWeek}주차 주간 리포트',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: burnColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: burnColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '소진 속도 (Burn Rate)',
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(report.burnRate * 100).toInt()}%',
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: burnColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.burnRate > 1.0
                                ? '예산보다 빨리 쓰고 있어요'
                                : '안정적인 페이스입니다',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: burnColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      report.burnRate > 1.0
                          ? Icons.local_fire_department_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 48,
                      color: burnColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                report.message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                report.subMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSimpleStatItem(
                      theme,
                      '주간 표준 예산',
                      _currencyFormat.format(report.weeklyBudget),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: scheme.outlineVariant,
                    ),
                    _buildSimpleStatItem(
                      theme,
                      '이번 주 권장 한도',
                      _currencyFormat.format(report.recommendedLimit),
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleStatItem(
    ThemeData theme,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlight ? theme.colorScheme.primary : null,
          ),
        ),
      ],
    );
  }
}
