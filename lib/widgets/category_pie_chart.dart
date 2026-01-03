import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_ledger/utils/chart_colors.dart';
import 'package:smart_ledger/utils/stats_calculator.dart';

/// 카테고리별 지출/수입 비율을 보여주는 파이 차트 위젯
class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({
    super.key,
    required this.categoryStats,
    this.height = 200,
    this.centerSpaceRadius = 40,
    this.sectionRadius = 50,
  });

  final List<CategoryStats> categoryStats;
  final double height;
  final double centerSpaceRadius;
  final double sectionRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: height,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: centerSpaceRadius,
          sections: categoryStats.asMap().entries.map((entry) {
            final index = entry.key;
            final stats = entry.value;
            const fontSize = 12.0;

            return PieChartSectionData(
              color: ChartColors.getColorForIndex(index, theme),
              value: stats.total,
              title: stats.percentage > 5
                  ? '${stats.percentage.toStringAsFixed(0)}%'
                  : '',
              radius: sectionRadius,
              titleStyle: const TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
