import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/date_formats.dart';

void main() {
  group('DateFormats', () {
    final testDate = DateTime(2026, 1, 11, 14, 30, 45);

    test('yMd formats as yyyy-MM-dd', () {
      expect(DateFormats.yMd.format(testDate), '2026-01-11');
    });

    test('yMLabel formats as yyyy년 M월', () {
      expect(DateFormats.yMLabel.format(testDate), '2026년 1월');
    });

    test('yMdot formats as yyyy.MM', () {
      expect(DateFormats.yMdot.format(testDate), '2026.01');
    });

    test('yMddot formats as yyyy.MM.dd', () {
      expect(DateFormats.yMddot.format(testDate), '2026.01.11');
    });

    test('yMdHms formats as yyyy-MM-dd HH:mm:ss', () {
      expect(DateFormats.yMdHms.format(testDate), '2026-01-11 14:30:45');
    });

    test('monthDayLabel formats as M월 d일', () {
      expect(DateFormats.monthDayLabel.format(testDate), '1월 11일');
    });

    test('shortMonth formats as M월', () {
      expect(DateFormats.shortMonth.format(testDate), '1월');
    });
  });
}
