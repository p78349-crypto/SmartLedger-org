import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    final testDate = DateTime(2026, 1, 11, 14, 30, 45);

    group('DateFormat patterns', () {
      test('defaultDate formats as yyyy-MM-dd', () {
        expect(DateFormatter.defaultDate.format(testDate), '2026-01-11');
      });

      test('dateTime formats as yyyy-MM-dd HH:mm', () {
        expect(DateFormatter.dateTime.format(testDate), '2026-01-11 14:30');
      });

      test('dateTimeSeconds formats as yyyy-MM-dd HH:mm:ss', () {
        expect(DateFormatter.dateTimeSeconds.format(testDate), '2026-01-11 14:30:45');
      });

      test('monthLabel formats as yyyy년 M월', () {
        expect(DateFormatter.monthLabel.format(testDate), '2026년 1월');
      });

      test('monthDay formats as M월 d일', () {
        expect(DateFormatter.monthDay.format(testDate), '1월 11일');
      });

      test('shortMonth formats as M월', () {
        expect(DateFormatter.shortMonth.format(testDate), '1월');
      });

      test('yearMonth formats as yyyy-MM', () {
        expect(DateFormatter.yearMonth.format(testDate), '2026-01');
      });

      test('rangeMonth formats as yyyy.MM', () {
        expect(DateFormatter.rangeMonth.format(testDate), '2026.01');
      });

      test('rangeDate formats as yyyy.MM.dd', () {
        expect(DateFormatter.rangeDate.format(testDate), '2026.01.11');
      });

      test('yearKorean formats as yyyy년', () {
        expect(DateFormatter.yearKorean.format(testDate), '2026년');
      });

      test('fileNameDate formats as yyyyMMdd', () {
        expect(DateFormatter.fileNameDate.format(testDate), '20260111');
      });

      test('fileNameDateTime formats as yyyyMMdd_HHmmss', () {
        expect(DateFormatter.fileNameDateTime.format(testDate), '20260111_143045');
      });

      test('mmdd formats as MM/dd', () {
        expect(DateFormatter.mmdd.format(testDate), '01/11');
      });

      test('mmddHHmm formats as MM/dd HH:mm', () {
        expect(DateFormatter.mmddHHmm.format(testDate), '01/11 14:30');
      });
    });

    group('Static format methods', () {
      test('formatDate returns formatted date', () {
        expect(DateFormatter.formatDate(testDate), '2026-01-11');
      });

      test('formatDateTime returns formatted datetime', () {
        expect(DateFormatter.formatDateTime(testDate), '2026-01-11 14:30');
      });

      test('formatMonthLabel returns month label', () {
        expect(DateFormatter.formatMonthLabel(testDate), '2026년 1월');
      });

      test('formatShortMonth returns short month', () {
        expect(DateFormatter.formatShortMonth(testDate), '1월');
      });
    });
  });
}
