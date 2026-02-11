part of 'in_app_screen_saver.dart';

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
