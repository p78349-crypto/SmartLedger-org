import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/type_converters.dart';

void main() {
  group('TypeConverters', () {
    group('parseDouble', () {
      test('returns null for null', () {
        expect(TypeConverters.parseDouble(null), isNull);
      });

      test('returns double as-is', () {
        expect(TypeConverters.parseDouble(3.14), 3.14);
      });

      test('converts int to double', () {
        expect(TypeConverters.parseDouble(42), 42.0);
      });

      test('parses string to double', () {
        expect(TypeConverters.parseDouble('3.14'), 3.14);
      });

      test('parses string with commas', () {
        expect(TypeConverters.parseDouble('1,234.56'), 1234.56);
      });

      test('returns null for invalid string', () {
        expect(TypeConverters.parseDouble('abc'), isNull);
      });
    });

    group('parseCurrency', () {
      test('returns null for null', () {
        expect(TypeConverters.parseCurrency(null), isNull);
      });

      test('parses simple number', () {
        expect(TypeConverters.parseCurrency('1000'), 1000);
      });

      test('parses with comma as thousands separator', () {
        expect(TypeConverters.parseCurrency('1,234,567'), 1234567);
      });

      test('parses with dot as decimal', () {
        expect(TypeConverters.parseCurrency('1,234.56'), 1234.56);
      });

      test('parses European format (dot as thousands, comma as decimal)', () {
        expect(TypeConverters.parseCurrency('1.234,56'), 1234.56);
      });

      test('handles currency symbols', () {
        expect(TypeConverters.parseCurrency('\$1,000'), 1000);
        expect(TypeConverters.parseCurrency('₩10,000'), 10000);
      });

      test('returns null for empty string', () {
        expect(TypeConverters.parseCurrency(''), isNull);
      });
    });

    group('parseInt', () {
      test('returns null for null', () {
        expect(TypeConverters.parseInt(null), isNull);
      });

      test('returns int as-is', () {
        expect(TypeConverters.parseInt(42), 42);
      });

      test('converts double to int', () {
        expect(TypeConverters.parseInt(3.7), 3);
      });

      test('parses string to int', () {
        expect(TypeConverters.parseInt('42'), 42);
      });

      test('parses string with commas', () {
        expect(TypeConverters.parseInt('1,234'), 1234);
      });

      test('returns null for invalid string', () {
        expect(TypeConverters.parseInt('abc'), isNull);
      });
    });

    group('parseString', () {
      test('returns default for null', () {
        expect(TypeConverters.parseString(null), '');
      });

      test('returns string as-is', () {
        expect(TypeConverters.parseString('hello'), 'hello');
      });

      test('converts int to string', () {
        expect(TypeConverters.parseString(42), '42');
      });

      test('uses custom default value', () {
        expect(
          TypeConverters.parseString(null, defaultValue: 'default'),
          'default',
        );
      });
    });

    group('parseBool', () {
      test('returns default for null', () {
        expect(TypeConverters.parseBool(null), false);
      });

      test('returns bool as-is', () {
        expect(TypeConverters.parseBool(true), true);
        expect(TypeConverters.parseBool(false), false);
      });

      test('parses string true variants', () {
        expect(TypeConverters.parseBool('true'), true);
        expect(TypeConverters.parseBool('TRUE'), true);
        expect(TypeConverters.parseBool('1'), true);
        expect(TypeConverters.parseBool('yes'), true);
      });

      test('parses string false variants', () {
        expect(TypeConverters.parseBool('false'), false);
        expect(TypeConverters.parseBool('0'), false);
        expect(TypeConverters.parseBool('no'), false);
      });

      test('parses int to bool', () {
        expect(TypeConverters.parseBool(1), true);
        expect(TypeConverters.parseBool(0), false);
      });
    });

    group('parseDateTime', () {
      test('returns null for null', () {
        expect(TypeConverters.parseDateTime(null), isNull);
      });

      test('returns DateTime as-is', () {
        final dt = DateTime(2026, 1, 11);
        expect(TypeConverters.parseDateTime(dt), dt);
      });

      test('parses ISO string', () {
        final result = TypeConverters.parseDateTime('2026-01-11T10:30:00');
        expect(result?.year, 2026);
        expect(result?.month, 1);
        expect(result?.day, 11);
      });

      test('parses milliseconds since epoch', () {
        final ms = DateTime(2026, 1, 11).millisecondsSinceEpoch;
        final result = TypeConverters.parseDateTime(ms);
        expect(result?.year, 2026);
      });

      test('returns null for invalid string', () {
        expect(TypeConverters.parseDateTime('invalid'), isNull);
      });
    });

    group('formatNumber', () {
      test('formats integer with commas', () {
        expect(TypeConverters.formatNumber(1234567), '1,234,567');
      });

      test('formats small numbers', () {
        expect(TypeConverters.formatNumber(123), '123');
      });

      test('formats double with commas', () {
        expect(TypeConverters.formatNumber(1234.56), '1,234.56');
      });
    });

    group('parseDoubleList', () {
      test('converts list of mixed values', () {
        final result = TypeConverters.parseDoubleList([1, '2.5', 3.0, 'abc']);
        expect(result, [1.0, 2.5, 3.0]);
      });

      test('returns empty for empty list', () {
        expect(TypeConverters.parseDoubleList([]), isEmpty);
      });
    });

    group('parseIntList', () {
      test('converts list of mixed values', () {
        final result = TypeConverters.parseIntList([1, '2', 3.7, 'abc']);
        expect(result, [1, 2, 3]);
      });
    });

    group('parseMap', () {
      test('converts map values', () {
        final source = {'a': 1, 'b': 2};
        final result = TypeConverters.parseMap<int>(source, (v) => v as int);
        expect(result, {'a': 1, 'b': 2});
      });

      test('returns default on error', () {
        final source = {'a': 'not_int'};
        final result = TypeConverters.parseMap<int>(
          source,
          (v) => int.parse(v as String),
          defaultValue: {'default': 0},
        );
        expect(result, {'default': 0});
      });
    });
  });
}
