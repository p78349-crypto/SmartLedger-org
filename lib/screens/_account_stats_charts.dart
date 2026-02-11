part of 'account_stats_screen.dart';

/// 차트 빌드 메서드 (바, 라인, 파이).
extension AccountStatsCharts on _AccountStatsScreenState {
  Widget _buildChartForDisplay(
    List<ChartPoint> points,
    ThemeData theme,
    double maxValue,
    TransactionType type,
  ) {
    switch (_chartDisplay) {
      case ChartDisplayType.bar:
        return _buildBarChart(points, theme, maxValue, type);
      case ChartDisplayType.line:
        return _buildLineChart(points, theme, maxValue, type);
      case ChartDisplayType.pie:
        return _buildPieChart(points, theme, type);
      case ChartDisplayType.all:
        return _buildAllCharts(points, theme, maxValue, type);
    }
  }

  Widget _buildAllCharts(
    List<ChartPoint> points, ThemeData theme, double maxValue,
    TransactionType type,
  ) {
    return Column(children: [
      _buildPieChart(points, theme, type),
      const SizedBox(height: 24), const Divider(), const SizedBox(height: 24),
      _buildBarChart(points, theme, maxValue, type),
      const SizedBox(height: 24), const Divider(), const SizedBox(height: 24),
      _buildLineChart(points, theme, maxValue, type),
    ]);
  }

  Widget _buildBarChart(
    List<ChartPoint> points, ThemeData theme, double maxValue,
    TransactionType type,
  ) {
    final groups = points.asMap().entries.map((entry) {
      return BarChartGroupData(x: entry.key, barRods: [
        BarChartRodData(
          toY: entry.value.total,
          color: _typeColorFor(type, theme),
          borderRadius: BorderRadius.circular(4),
          width: 14,
        ),
      ]);
    }).toList();
    final chartMax = maxValue == 0 ? 1.0 : maxValue * 1.2;
    final labelStyle = theme.textTheme.bodySmall;
    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceBetween,
      maxY: chartMax,
      barGroups: groups,
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 32,
          getTitlesWidget: (value, meta) {
            final i = value.toInt();
            if (i < 0 || i >= points.length) return const SizedBox.shrink();
            return SideTitleWidget(
              meta: meta,
              child: Text(_shortMonthFormat.format(points[i].month),
                  style: labelStyle),
            );
          },
        )),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 48,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            child: Text(_formatAxisLabel(value), style: labelStyle),
          ),
        )),
      ),
    ));
  }

  Widget _buildLineChart(
    List<ChartPoint> points, ThemeData theme, double maxValue,
    TransactionType type,
  ) {
    final spots = points.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.total)).toList();
    final chartMax = maxValue == 0 ? 1.0 : maxValue * 1.2;
    final labelStyle = theme.textTheme.bodySmall;
    final color = _typeColorFor(type, theme);
    return LineChart(LineChartData(
      minY: 0, maxY: chartMax,
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 32,
          getTitlesWidget: (value, meta) {
            final i = value.round();
            if (i < 0 || i >= points.length) return const SizedBox.shrink();
            return SideTitleWidget(
              meta: meta,
              child: Text(_shortMonthFormat.format(points[i].month),
                  style: labelStyle),
            );
          },
        )),
        leftTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 48,
          getTitlesWidget: (value, meta) => SideTitleWidget(
            meta: meta,
            child: Text(_formatAxisLabel(value), style: labelStyle),
          ),
        )),
      ),
      lineBarsData: [LineChartBarData(
        spots: spots, isCurved: true, color: color, barWidth: 3,
        isStrokeCapRound: true,
        belowBarData: BarAreaData(
          show: true, color: _colorWithOpacity(color, 0.15)),
      )],
    ));
  }

  Widget _buildPieChart(
    List<ChartPoint> points, ThemeData theme, TransactionType type,
  ) {
    final nonZero = points.where((p) => p.total > 0).toList();
    final total = nonZero.fold<double>(0, (s, p) => s + p.total);
    if (nonZero.isEmpty || total == 0) return _buildNoChartData(theme);
    final color = _typeColorFor(type, theme);
    final sections = nonZero.asMap().entries.map((entry) {
      final ratio = entry.value.total / total;
      final percent = (ratio * 100).toStringAsFixed(ratio >= 0.1 ? 0 : 1);
      final sc = _sliceColor(color, entry.key, nonZero.length);
      return PieChartSectionData(
        value: entry.value.total, color: sc,
        title: '$percent%\n${_shortMonthFormat.format(entry.value.month)}',
        radius: 70,
        titleStyle: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
      );
    }).toList();
    return Column(children: [
      Expanded(child: PieChart(PieChartData(
        sections: sections, sectionsSpace: 1, centerSpaceRadius: 30))),
      const SizedBox(height: 12),
      Wrap(
        alignment: WrapAlignment.center, spacing: 8, runSpacing: 4,
        children: nonZero.asMap().entries.map((entry) {
          final sc = _sliceColor(color, entry.key, nonZero.length);
          return Chip(
            label: Text('${_shortMonthFormat.format(entry.value.month)} · '
                '${_formatCurrency(entry.value.total)}'),
            backgroundColor: _colorWithOpacity(sc, 0.2),
            avatar: CircleAvatar(backgroundColor: sc, radius: 6),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildNoChartData(ThemeData theme) =>
      Center(child: Text('표시할 데이터가 없습니다.', style: theme.textTheme.bodyMedium));

  String _chartDisplayLabel(ChartDisplayType d) {
    switch (d) {
      case ChartDisplayType.bar: return '막대형';
      case ChartDisplayType.line: return '선형';
      case ChartDisplayType.pie: return '원형';
      case ChartDisplayType.all: return '전체';
    }
  }

  String _formatAxisLabel(double value) {
    final abs = value.abs();
    if (abs >= 100000000) return '${(value / 100000000).toStringAsFixed(1)}억';
    if (abs >= 10000) return '${(value / 10000).toStringAsFixed(1)}만';
    if (abs >= 1000) return _compactNumberFormat.format(value);
    return value.toStringAsFixed(0);
  }

  Color _sliceColor(Color base, int index, int totalSlices) {
    final hsl = HSLColor.fromColor(base);
    final step = totalSlices <= 1 ? 0 : index / (totalSlices - 1);
    final lightness = (0.65 - step * 0.35).clamp(0.25, 0.75).toDouble();
    return hsl.withLightness(lightness).toColor();
  }

  Color _colorWithOpacity(Color color, double opacity) {
    final alpha = (opacity * 255).round().clamp(0, 255);
    return color.withAlpha(alpha);
  }
}
