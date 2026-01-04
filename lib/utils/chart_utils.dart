/// Chart utility classes and functions for reusable chart components
library;

import 'dart:math' show pow, log;
import 'package:flutter/material.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';

/// Chart display types
enum ChartDisplayType {
  bar,
  line,
  pie,
  all;

  /// Get display label for the chart type
  String get label {
    switch (this) {
      case ChartDisplayType.bar:
        return '막대형';
      case ChartDisplayType.line:
        return '선형';
      case ChartDisplayType.pie:
        return '원형';
      case ChartDisplayType.all:
        return '전체';
    }
  }

  /// Get icon for the chart type
  IconData get icon {
    switch (this) {
      case ChartDisplayType.bar:
        return IconCatalog.barChart;
      case ChartDisplayType.line:
        return IconCatalog.showChart;
      case ChartDisplayType.pie:
        return IconCatalog.pieChart;
      case ChartDisplayType.all:
        return IconCatalog.gridView;
    }
  }
}

/// Mixin for chart display state management
mixin ChartDisplayMixin<T extends StatefulWidget> on State<T> {
  ChartDisplayType _chartDisplay = ChartDisplayType.bar;

  ChartDisplayType get chartDisplay => _chartDisplay;

  void setChartDisplay(ChartDisplayType display) {
    setState(() {
      _chartDisplay = display;
    });
  }
}

/// Reusable chart display selector widget
class ChartDisplaySelector extends StatelessWidget {
  final ChartDisplayType selected;
  final ValueChanged<ChartDisplayType> onChanged;
  final List<ChartDisplayType>? types;
  final bool showIcons;

  const ChartDisplaySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.types,
    this.showIcons = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayTypes = types ?? ChartDisplayType.values;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: displayTypes.map((type) {
        final isSelected = selected == type;
        final scheme = Theme.of(context).colorScheme;

        return ChoiceChip(
          label: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: showIcons
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type.icon,
                        size: 18,
                        color: isSelected
                            ? scheme.onPrimaryContainer
                            : scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        type.label,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  )
                : Text(
                    type.label,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
          ),
          selected: isSelected,
          onSelected: (isSelected) {
            if (isSelected) {
              onChanged(type);
            }
          },
          selectedColor: scheme.primaryContainer,
          backgroundColor: scheme.surfaceContainerLow,
          side: BorderSide(
            color: isSelected
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}

/// Chart builder interface
abstract class ChartBuilder<T> {
  Widget buildBarChart(List<T> data, ThemeData theme);
  Widget buildLineChart(List<T> data, ThemeData theme);
  Widget buildPieChart(List<T> data, ThemeData theme);

  Widget buildAllCharts(List<T> data, ThemeData theme) {
    return Column(
      children: [
        buildPieChart(data, theme),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        buildBarChart(data, theme),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 24),
        buildLineChart(data, theme),
      ],
    );
  }

  Widget build(List<T> data, ThemeData theme, ChartDisplayType type) {
    switch (type) {
      case ChartDisplayType.bar:
        return buildBarChart(data, theme);
      case ChartDisplayType.line:
        return buildLineChart(data, theme);
      case ChartDisplayType.pie:
        return buildPieChart(data, theme);
      case ChartDisplayType.all:
        return buildAllCharts(data, theme);
    }
  }
}

/// Chart point data class
class ChartPoint {
  final String label;
  final double value;
  final DateTime? date;
  final Color? color;

  const ChartPoint({
    required this.label,
    required this.value,
    this.date,
    this.color,
  });

  @override
  String toString() => 'ChartPoint(label: $label, value: $value)';
}

/// Chart utilities
class ChartUtils {
  ChartUtils._();

  /// Format large numbers for chart labels
  static String formatAxisLabel(double value) {
    final abs = value.abs();
    if (abs >= 100000000) {
      return '${(value / 100000000).toStringAsFixed(1)}억';
    }
    if (abs >= 10000) {
      return '${(value / 10000).toStringAsFixed(1)}만';
    }
    if (abs >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}천';
    }
    return value.toStringAsFixed(0);
  }

  /// Calculate max value with padding for better chart display
  static double calculateMaxValue(List<double> values, {double padding = 1.2}) {
    if (values.isEmpty) return 0;
    final max = values.reduce((a, b) => a > b ? a : b);
    return max * padding;
  }

  /// Calculate min value with padding
  static double calculateMinValue(List<double> values, {double padding = 1.2}) {
    if (values.isEmpty) return 0;
    final min = values.reduce((a, b) => a < b ? a : b);
    return min < 0 ? min * padding : 0;
  }

  /// Get appropriate interval for axis labels
  static double getInterval(double maxValue, int divisions) {
    if (maxValue == 0) return 1;
    final rawInterval = maxValue / divisions;
    final magnitude = _magnitude(rawInterval);
    final normalized = rawInterval / magnitude;

    double niceInterval;
    if (normalized <= 1) {
      niceInterval = 1;
    } else if (normalized <= 2) {
      niceInterval = 2;
    } else if (normalized <= 5) {
      niceInterval = 5;
    } else {
      niceInterval = 10;
    }

    return niceInterval * magnitude;
  }

  static double _magnitude(double value) {
    return value == 0
        ? 1
        : pow(10, (log(value.abs()) / ln10).floor()).toDouble();
  }

  static const double ln10 = 2.302585092994046;
}
