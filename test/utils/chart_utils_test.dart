import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/chart_utils.dart';

void main() {
  group('ChartDisplayType', () {
    test('label returns correct Korean text', () {
      expect(ChartDisplayType.bar.label, '막대형');
      expect(ChartDisplayType.line.label, '선형');
      expect(ChartDisplayType.pie.label, '원형');
      expect(ChartDisplayType.all.label, '전체');
    });

    test('icon returns correct IconData', () {
      expect(ChartDisplayType.bar.icon, isA<IconData>());
      expect(ChartDisplayType.line.icon, isA<IconData>());
      expect(ChartDisplayType.pie.icon, isA<IconData>());
      expect(ChartDisplayType.all.icon, isA<IconData>());
    });
  });

  group('ChartPoint', () {
    test('creates with required fields', () {
      const point = ChartPoint(label: '1월', value: 50000);
      expect(point.label, '1월');
      expect(point.value, 50000);
      expect(point.date, isNull);
      expect(point.color, isNull);
    });

    test('creates with all fields', () {
      final date = DateTime(2026, 1, 11);
      final point = ChartPoint(
        label: '식비',
        value: 150000,
        date: date,
        color: Colors.blue,
      );

      expect(point.date, date);
      expect(point.color, Colors.blue);
    });

    test('toString returns readable format', () {
      const point = ChartPoint(label: 'Test', value: 100);
      expect(point.toString(), contains('Test'));
      expect(point.toString(), contains('100'));
    });
  });

  group('ChartUtils', () {
    group('formatAxisLabel', () {
      test('formats 억 unit', () {
        expect(ChartUtils.formatAxisLabel(100000000), '1.0억');
        expect(ChartUtils.formatAxisLabel(250000000), '2.5억');
      });

      test('formats 만 unit', () {
        expect(ChartUtils.formatAxisLabel(10000), '1.0만');
        expect(ChartUtils.formatAxisLabel(50000), '5.0만');
        expect(ChartUtils.formatAxisLabel(99999), '10.0만');
      });

      test('formats 천 unit', () {
        expect(ChartUtils.formatAxisLabel(1000), '1.0천');
        expect(ChartUtils.formatAxisLabel(5500), '5.5천');
      });

      test('formats small numbers without unit', () {
        expect(ChartUtils.formatAxisLabel(500), '500');
        expect(ChartUtils.formatAxisLabel(0), '0');
      });

      test('handles negative values', () {
        expect(ChartUtils.formatAxisLabel(-100000000), '-1.0억');
        expect(ChartUtils.formatAxisLabel(-50000), '-5.0만');
      });
    });

    group('calculateMaxValue', () {
      test('returns 0 for empty list', () {
        expect(ChartUtils.calculateMaxValue([]), 0);
      });

      test('returns max with default padding', () {
        final result = ChartUtils.calculateMaxValue([10, 20, 30]);
        expect(result, 36); // 30 * 1.2
      });

      test('uses custom padding', () {
        final result = ChartUtils.calculateMaxValue([100], padding: 1.5);
        expect(result, 150);
      });
    });

    group('calculateMinValue', () {
      test('returns 0 for empty list', () {
        expect(ChartUtils.calculateMinValue([]), 0);
      });

      test('returns 0 when min is positive', () {
        expect(ChartUtils.calculateMinValue([10, 20, 30]), 0);
      });

      test('returns negative min with padding', () {
        final result = ChartUtils.calculateMinValue([-10, 0, 10]);
        expect(result, -12); // -10 * 1.2
      });
    });

    group('getInterval', () {
      test('returns 1 when maxValue is 0', () {
        expect(ChartUtils.getInterval(0, 5), 1);
      });

      test('calculates nice intervals', () {
        // 100을 5로 나누면 20, magnitude는 10, normalized는 2
        expect(ChartUtils.getInterval(100, 5), 20);
      });

      test('handles large values', () {
        final interval = ChartUtils.getInterval(1000000, 5);
        expect(interval, greaterThan(0));
        expect(interval % 100000, 0); // 100000의 배수여야 함
      });
    });
  });
}
