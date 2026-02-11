part of 'chart_detail_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Chart builders for [_ChartDetailScreenState].
extension ChartDetailScreenCharts on _ChartDetailScreenState {
  Widget _buildChart(
    List<MapEntry<DateTime, double>> data,
    ThemeData theme,
    double maxValue,
    Color color,
  ) {
    switch (_chartType) {
      case ChartType.bar:
        return _buildBarChart(data, theme, maxValue, color);
      case ChartType.line:
        return _buildLineChart(data, theme, maxValue, color);
      case ChartType.pie:
        return _buildPieChart(data, theme, color);
    }
  }

  Widget _buildBarChart(
    List<MapEntry<DateTime, double>> data,
    ThemeData theme,
    double maxValue,
    Color color,
  ) {
    final groups = data
        .asMap()
        .entries
        .map(
          (entry) => BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: color,
                borderRadius: BorderRadius.circular(4),
                width: 14,
              ),
            ],
          ),
        )
        .toList();

    return BarChart(
      BarChartData(
        barGroups: groups,
        maxY: maxValue * 1.1,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${_currencyFormat.format(rod.toY)}원',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compactNumberFormat.format(value),
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  final month = data[value.toInt()].key;
                  return Text(
                    '${month.month}월',
                    style: theme.textTheme.bodySmall,
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxValue / 5,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildLineChart(
    List<MapEntry<DateTime, double>> data,
    ThemeData theme,
    double maxValue,
    Color color,
  ) {
    final spots = data
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
        .toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2.5,
            dotData: FlDotData(
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
        maxY: maxValue * 1.1,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${_currencyFormat.format(spot.y)}원',
                  const TextStyle(color: Colors.white),
                );
              }).toList();
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  _compactNumberFormat.format(value),
                  style: theme.textTheme.bodySmall,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  final month = data[value.toInt()].key;
                  return Text(
                    '${month.month}월',
                    style: theme.textTheme.bodySmall,
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
        ),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxValue / 5,
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildPieChart(
    List<MapEntry<DateTime, double>> data,
    ThemeData theme,
    Color baseColor,
  ) {
    final filteredData = data.where((entry) => entry.value > 0).toList();

    if (filteredData.isEmpty) {
      return Center(
        child: Text(
          '표시할 데이터가 없습니다.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }

    final sections = filteredData.asMap().entries.map((entry) {
      final index = entry.key;
      final monthData = entry.value;
      final sectionColor = Color.fromARGB(
        255,
        math.max(0, math.min(255, (baseColor.r * 255).round() + (index * 20))),
        math.max(0, math.min(255, (baseColor.g * 255).round() - (index * 10))),
        math.max(0, math.min(255, (baseColor.b * 255).round() + (index * 15))),
      );

      return PieChartSectionData(
        value: monthData.value,
        title: '${monthData.key.month}월',
        radius: 100,
        color: sectionColor,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
        ),
      ),
    );
  }
}
