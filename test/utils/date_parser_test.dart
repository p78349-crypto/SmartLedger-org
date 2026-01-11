import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/date_parser.dart';

void main() {
  group('DateParser', () {
    final testNow = DateTime(2026, 1, 15);

    test('returns today for empty input', () {
      final result = DateParser.parse('', now: testNow);
      expect(result, DateTime(2026, 1, 15));
    });

    test('returns today for null input', () {
      final result = DateParser.parse(null, now: testNow);
      expect(result, DateTime(2026, 1, 15));
    });

    group('relative keywords', () {
      test('오늘 returns today', () {
        final result = DateParser.parse('오늘', now: testNow);
        expect(result, DateTime(2026, 1, 15));
      });

      test('내일 returns tomorrow', () {
        final result = DateParser.parse('내일', now: testNow);
        expect(result, DateTime(2026, 1, 16));
      });

      test('모레 returns day after tomorrow', () {
        final result = DateParser.parse('모레', now: testNow);
        expect(result, DateTime(2026, 1, 17));
      });
    });

    group('N일 뒤 pattern', () {
      test('3일 뒤 returns 3 days later', () {
        final result = DateParser.parse('3일 뒤', now: testNow);
        expect(result, DateTime(2026, 1, 18));
      });

      test('10일뒤 (no space) works', () {
        final result = DateParser.parse('10일뒤', now: testNow);
        expect(result, DateTime(2026, 1, 25));
      });

      test('handles large number of days', () {
        final result = DateParser.parse('100일 뒤', now: testNow);
        expect(result, DateTime(2026, 4, 25));
      });
    });

    group('M월 D일 pattern', () {
      test('1월 20일 returns January 20', () {
        final result = DateParser.parse('1월 20일', now: testNow);
        expect(result, DateTime(2026, 1, 20));
      });

      test('12월 25일 returns December 25', () {
        final result = DateParser.parse('12월 25일', now: testNow);
        expect(result, DateTime(2026, 12, 25));
      });

      test('handles space variations', () {
        final result = DateParser.parse('3 월  5 일', now: testNow);
        expect(result, DateTime(2026, 3, 5));
      });
    });

    group('ISO format', () {
      test('parses ISO date string', () {
        final result = DateParser.parse('2026-03-20', now: testNow);
        expect(result, DateTime(2026, 3, 20));
      });

      test('parses ISO datetime and strips time', () {
        final result = DateParser.parse('2026-06-15T14:30:00', now: testNow);
        expect(result, DateTime(2026, 6, 15));
      });
    });

    group('fallback', () {
      test('returns today for invalid input', () {
        final result = DateParser.parse('invalid date', now: testNow);
        expect(result, DateTime(2026, 1, 15));
      });
    });
  });
}
