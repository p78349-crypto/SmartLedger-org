import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/chart_colors.dart';

void main() {
  group('ChartColors', () {
    late ThemeData theme;

    setUp(() {
      theme = ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      );
    });

    group('getColorForIndex', () {
      test('returns primary-family colors for indices 0-9', () {
        final color0 = ChartColors.getColorForIndex(0, theme);
        expect(color0, theme.colorScheme.primary);

        final color1 = ChartColors.getColorForIndex(1, theme);
        expect(color1, Colors.blue);

        final color9 = ChartColors.getColorForIndex(9, theme);
        expect(color9, Colors.amber);
      });

      test('returns secondary-family colors for indices 10-19', () {
        final color10 = ChartColors.getColorForIndex(10, theme);
        expect(color10, theme.colorScheme.secondary);

        final color11 = ChartColors.getColorForIndex(11, theme);
        expect(color11, Colors.orange);

        final color19 = ChartColors.getColorForIndex(19, theme);
        expect(color19, Colors.grey);
      });

      test('returns tertiary-family colors for indices 20+', () {
        final color20 = ChartColors.getColorForIndex(20, theme);
        expect(color20, theme.colorScheme.tertiary);

        final color21 = ChartColors.getColorForIndex(21, theme);
        expect(color21, theme.colorScheme.outline);

        final color22 = ChartColors.getColorForIndex(22, theme);
        expect(color22, theme.colorScheme.onSurfaceVariant);
      });

      test('cycles tertiary colors for indices beyond 22', () {
        final color23 = ChartColors.getColorForIndex(23, theme);
        expect(color23, theme.colorScheme.tertiary);
      });
    });
  });
}
