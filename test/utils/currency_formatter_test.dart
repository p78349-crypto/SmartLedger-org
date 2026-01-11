import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('currencySymbols', () {
      test('contains KRW symbol', () {
        expect(CurrencyFormatter.currencySymbols['KRW'], '원');
      });

      test('contains USD symbol', () {
        expect(CurrencyFormatter.currencySymbols['USD'], '\$');
      });

      test('contains EUR symbol', () {
        expect(CurrencyFormatter.currencySymbols['EUR'], '€');
      });

      test('contains JPY symbol', () {
        expect(CurrencyFormatter.currencySymbols['JPY'], '¥');
      });
    });

    group('currencyNamesKo', () {
      test('returns Korean name for KRW', () {
        expect(CurrencyFormatter.currencyNamesKo['KRW'], '대한민국 원');
      });

      test('returns Korean name for USD', () {
        expect(CurrencyFormatter.currencyNamesKo['USD'], '미국 달러');
      });
    });

    group('nameKo', () {
      test('returns Korean name for valid code', () {
        expect(CurrencyFormatter.nameKo('KRW'), '대한민국 원');
        expect(CurrencyFormatter.nameKo('USD'), '미국 달러');
      });

      test('returns code for unknown currency', () {
        expect(CurrencyFormatter.nameKo('XXX'), 'XXX');
      });
    });

    group('format', () {
      test('formats number with thousands separator', () {
        final result = CurrencyFormatter.format(1234567, showUnit: false);
        expect(result, contains('1'));
        expect(result, contains('234'));
      });

      test('formats negative numbers', () {
        final result = CurrencyFormatter.format(-5000, showUnit: false);
        expect(result, contains('5'));
      });

      test('formats zero', () {
        final result = CurrencyFormatter.format(0, showUnit: false);
        expect(result, '0');
      });
    });

    group('formatWithDecimals', () {
      test('includes decimal places', () {
        final result =
            CurrencyFormatter.formatWithDecimals(1234.56, showUnit: false);
        expect(result, contains('1'));
        expect(result, contains('56'));
      });
    });

    group('NumberFormat accessors', () {
      test('currency accessor returns NumberFormat', () {
        expect(CurrencyFormatter.currency, isA<NumberFormat>());
      });

      test('currencyWithDecimals accessor returns NumberFormat', () {
        expect(CurrencyFormatter.currencyWithDecimals, isA<NumberFormat>());
      });

      test('compact accessor returns NumberFormat', () {
        expect(CurrencyFormatter.compact, isA<NumberFormat>());
      });
    });
  });
}
