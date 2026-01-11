import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/number_formats.dart';

void main() {
  group('NumberFormats', () {
    test('currency formatter is accessible', () {
      expect(NumberFormats.currency, isNotNull);
    });

    test('currencyCompactKo formatter is accessible', () {
      expect(NumberFormats.currencyCompactKo, isNotNull);
    });

    test('custom formatter works', () {
      final formatter = NumberFormats.custom('#,###');
      expect(formatter.format(1234567), '1,234,567');
    });

    test('currency formats large numbers', () {
      final formatted = NumberFormats.currency.format(1000000);
      expect(formatted, isNotEmpty);
    });

    test('currencyCompactKo formats with compact notation', () {
      final formatted = NumberFormats.currencyCompactKo.format(1000000);
      // Korean compact: 100만
      expect(formatted, isNotEmpty);
    });
  });
}
