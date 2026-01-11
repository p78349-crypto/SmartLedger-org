import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/chart_display_utils.dart';
import 'package:smart_ledger/utils/chart_utils.dart';

void main() {
  group('ChartDisplayUtils', () {
    group('getDisplayLabel', () {
      test('returns 막대형 for bar', () {
        expect(
          ChartDisplayUtils.getDisplayLabel(ChartDisplayType.bar),
          '막대형',
        );
      });

      test('returns 선형 for line', () {
        expect(
          ChartDisplayUtils.getDisplayLabel(ChartDisplayType.line),
          '선형',
        );
      });

      test('returns 원형 for pie', () {
        expect(
          ChartDisplayUtils.getDisplayLabel(ChartDisplayType.pie),
          '원형',
        );
      });

      test('returns 전체 for all', () {
        expect(
          ChartDisplayUtils.getDisplayLabel(ChartDisplayType.all),
          '전체',
        );
      });
    });

    group('getDisplayType', () {
      test('returns BarChart for bar', () {
        expect(
          ChartDisplayUtils.getDisplayType(ChartDisplayType.bar),
          'BarChart',
        );
      });

      test('returns LineChart for line', () {
        expect(
          ChartDisplayUtils.getDisplayType(ChartDisplayType.line),
          'LineChart',
        );
      });

      test('returns PieChart for pie', () {
        expect(
          ChartDisplayUtils.getDisplayType(ChartDisplayType.pie),
          'PieChart',
        );
      });

      test('returns CombinedChart for all', () {
        expect(
          ChartDisplayUtils.getDisplayType(ChartDisplayType.all),
          'CombinedChart',
        );
      });
    });

    group('nextDisplay', () {
      test('cycles from bar to line', () {
        expect(
          ChartDisplayUtils.nextDisplay(ChartDisplayType.bar),
          ChartDisplayType.line,
        );
      });

      test('cycles from line to pie', () {
        expect(
          ChartDisplayUtils.nextDisplay(ChartDisplayType.line),
          ChartDisplayType.pie,
        );
      });

      test('cycles from pie to all', () {
        expect(
          ChartDisplayUtils.nextDisplay(ChartDisplayType.pie),
          ChartDisplayType.all,
        );
      });

      test('cycles from all back to bar', () {
        expect(
          ChartDisplayUtils.nextDisplay(ChartDisplayType.all),
          ChartDisplayType.bar,
        );
      });

      test('cycles through all values correctly', () {
        var current = ChartDisplayType.bar;
        final seen = <ChartDisplayType>{current};

        for (var i = 0; i < ChartDisplayType.values.length; i++) {
          current = ChartDisplayUtils.nextDisplay(current);
          if (i < ChartDisplayType.values.length - 1) {
            expect(seen.contains(current), false);
          }
          seen.add(current);
        }

        expect(seen.length, ChartDisplayType.values.length);
      });
    });
  });
}
