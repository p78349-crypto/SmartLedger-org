import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/period_utils.dart';

void main() {
  group('PeriodUtils', () {
    final baseDate = DateTime(2026, 3, 15); // 2026년 3월 15일 기준

    group('getPeriodRange', () {
      test('week returns 7 day range', () {
        final range =
            PeriodUtils.getPeriodRange(PeriodType.week, baseDate: baseDate);
        expect(range.end, baseDate);
        expect(range.start, DateTime(2026, 3, 9)); // 6일 전
      });

      test('month returns current month range', () {
        final range =
            PeriodUtils.getPeriodRange(PeriodType.month, baseDate: baseDate);
        expect(range.start, DateTime(2026, 3, 1));
        expect(range.end, DateTime(2026, 3, 31));
      });

      test('quarter returns Q1 for March', () {
        final range =
            PeriodUtils.getPeriodRange(PeriodType.quarter, baseDate: baseDate);
        expect(range.start, DateTime(2026, 1, 1));
        expect(range.end, DateTime(2026, 3, 31));
      });

      test('quarter returns Q2 for April', () {
        final aprilDate = DateTime(2026, 4, 15);
        final range =
            PeriodUtils.getPeriodRange(PeriodType.quarter, baseDate: aprilDate);
        expect(range.start, DateTime(2026, 4, 1));
        expect(range.end, DateTime(2026, 6, 30));
      });

      test('halfYear returns H1 for March', () {
        final range =
            PeriodUtils.getPeriodRange(PeriodType.halfYear, baseDate: baseDate);
        expect(range.start, DateTime(2026, 1, 1));
        expect(range.end, DateTime(2026, 6, 30));
      });

      test('halfYear returns H2 for September', () {
        final septDate = DateTime(2026, 9, 15);
        final range =
            PeriodUtils.getPeriodRange(PeriodType.halfYear, baseDate: septDate);
        expect(range.start, DateTime(2026, 7, 1));
        expect(range.end, DateTime(2026, 12, 31));
      });

      test('year returns full year range', () {
        final range =
            PeriodUtils.getPeriodRange(PeriodType.year, baseDate: baseDate);
        expect(range.start, DateTime(2026, 1, 1));
        expect(range.end, DateTime(2026, 12, 31));
      });

      test('decade returns 10 year range', () {
        final range =
            PeriodUtils.getPeriodRange(PeriodType.decade, baseDate: baseDate);
        expect(range.start, DateTime(2020, 1, 1));
        expect(range.end, DateTime(2029, 12, 31));
      });
    });

    group('getPeriodLabel', () {
      test('returns correct labels', () {
        expect(PeriodUtils.getPeriodLabel(PeriodType.week), '주간 리포트');
        expect(PeriodUtils.getPeriodLabel(PeriodType.month), '월간 리포트');
        expect(PeriodUtils.getPeriodLabel(PeriodType.quarter), '분기 리포트');
        expect(PeriodUtils.getPeriodLabel(PeriodType.halfYear), '반기 리포트');
        expect(PeriodUtils.getPeriodLabel(PeriodType.year), '연간 리포트');
        expect(PeriodUtils.getPeriodLabel(PeriodType.decade), '10년');
      });
    });

    group('isRangeView', () {
      test('returns true for all period types', () {
        for (final period in PeriodType.values) {
          expect(PeriodUtils.isRangeView(period), isTrue);
        }
      });
    });
  });

  group('DateTimeRange', () {
    test('contains returns true for date within range', () {
      final range = DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 12, 31),
      );
      expect(range.contains(DateTime(2026, 6, 15)), isTrue);
    });

    test('contains returns true for start date', () {
      final range = DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 12, 31),
      );
      expect(range.contains(DateTime(2026, 1, 1)), isTrue);
    });

    test('contains returns true for end date', () {
      final range = DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 12, 31),
      );
      expect(range.contains(DateTime(2026, 12, 31)), isTrue);
    });

    test('contains returns false for date before range', () {
      final range = DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 12, 31),
      );
      expect(range.contains(DateTime(2025, 12, 31)), isFalse);
    });

    test('contains returns false for date after range', () {
      final range = DateTimeRange(
        start: DateTime(2026, 1, 1),
        end: DateTime(2026, 12, 31),
      );
      expect(range.contains(DateTime(2027, 1, 1)), isFalse);
    });
  });
}
