// ignore_for_file: invalid_use_of_protected_member

part of 'points_motivation_stats_screen.dart';

extension PointsMotivationStatsContentSection
    on _PointsMotivationStatsScreenState {
  Widget _buildContent(ThemeData theme) {
    final scheme = theme.colorScheme;
    final now = DateTime.now();
    final todayLabel = DateFormat('yyyy-MM-dd').format(now);

    final selected = _horizons[_selectedIndex];

    final totalRecent = PointsStatsUtils.sumTotal(_recentByCategory);
    final projectedByCategory = PointsStatsUtils.projectByCategory(
      _recentByCategory,
      lookbackDays: _lookbackDaysForRate,
      horizonDays: selected.days,
    );

    final projectedTotal = PointsStatsUtils.sumTotal(projectedByCategory);
    final hasProjectedData = projectedTotal > 0;

    // Dynamic headline based on the selected horizon.
    final fvTotalHeadline = _futureValueOfRecurringSavings(
      totalRecent,
      lookbackDays: _lookbackDaysForRate,
      horizonDays: selected.days,
      annualRatePct: _investAnnualRatePct,
    );
    final fvScaleHeadline = (projectedTotal > 0)
        ? (fvTotalHeadline / projectedTotal)
        : 0.0;
    final fvByCategoryHeadline = <String, double>{
      for (final c in PointsStatsUtils.categories)
        c: (projectedByCategory[c] ?? 0) * fvScaleHeadline,
    };
    final topHeadline = _topCategory(fvByCategoryHeadline);

    // Always show a fixed 10-year headline for motivation.
    const tenYearsDays = 3650;
    final projectedByCategory10y = PointsStatsUtils.projectByCategory(
      _recentByCategory,
      lookbackDays: _lookbackDaysForRate,
      horizonDays: tenYearsDays,
    );
    final projectedTotal10y = PointsStatsUtils.sumTotal(projectedByCategory10y);
    final fvTotal10y = _futureValueOfRecurringSavings(
      totalRecent,
      lookbackDays: _lookbackDaysForRate,
      horizonDays: tenYearsDays,
      annualRatePct: _investAnnualRatePct,
    );
    final fvScale10y = (projectedTotal10y > 0)
        ? (fvTotal10y / projectedTotal10y)
        : 0.0;
    final fvByCategory10y = <String, double>{
      for (final c in PointsStatsUtils.categories)
        c: (projectedByCategory10y[c] ?? 0) * fvScale10y,
    };
    final top10y = _topCategory(fvByCategory10y);

    final fvTotal = _futureValueOfRecurringSavings(
      projectedTotal,
      lookbackDays: _lookbackDaysForRate,
      horizonDays: selected.days,
      annualRatePct: _investAnnualRatePct,
    );

    final fvScale = (projectedTotal > 0) ? (fvTotal / projectedTotal) : 0.0;
    final fvByCategory = <String, double>{
      for (final c in PointsStatsUtils.categories)
        c: (projectedByCategory[c] ?? 0) * fvScale,
    };

    final pct = (fvTotal <= 0)
        ? 0.0
        : ((fvTotal / _targetAmount) * 100).clamp(0.0, 100.0);

    if (totalRecent <= 0) return _buildEmptyState(theme, scheme);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMotivationCard(
          theme,
          horizonLabel: selected.label,
          fvTotal: fvTotalHeadline,
          simpleTotal: projectedTotal,
          topCategory: topHeadline.$1,
          topValue: topHeadline.$2,
          fvTotal10y: fvTotal10y,
          simpleTotal10y: projectedTotal10y,
          topCategory10y: top10y.$1,
          topValue10y: top10y.$2,
        ),
        const SizedBox(height: 12),
        _buildHorizonChips(theme),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(IconCatalog.localOffer, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '예상 포인트 절감액 (${selected.label})',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatWon(fvTotal),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '기준: 최근 $_lookbackDaysForRate일 평균(오늘: $todayLabel)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '가정: 절약한 돈을 모아 연 '
                  '${_investAnnualRatePct.toStringAsFixed(1)}%로 굴림(복리).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '목표 기여: ${pct.toStringAsFixed(2)}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      '${_formatWon(fvTotal)} / ${_formatWon(_targetAmount)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (fvTotal / _targetAmount).clamp(0.0, 1.0).toDouble(),
                  backgroundColor: scheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 10),
                Text(
                  '단순 누적(이자 0%): ${_formatWon(projectedTotal)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '카테고리별 (${selected.label})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...PointsStatsUtils.categories.map((c) {
                  final v = fvByCategory[c] ?? 0;
                  final ratio = (fvTotal <= 0)
                      ? 0.0
                      : (v / fvTotal).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(c, style: theme.textTheme.bodyMedium),
                        ),
                        Expanded(
                          flex: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: ratio.toDouble(),
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatWon(v),
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 $_lookbackDaysForRate일 실제 합계(참고)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatWon(totalRecent),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (!hasProjectedData)
                  Text(
                    '※ 이 화면은 "미래 동기" 목적이라 최근 패턴을 기반으로 단순 예측합니다.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
