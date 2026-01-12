import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/currency_input_formatter.dart';

void main() {
  group('CurrencyInputFormatter', () {
    late CurrencyInputFormatter formatter;

    setUp(() {
      formatter = CurrencyInputFormatter();
    });

    TextEditingValue formatText(String text) {
      return formatter.formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
    }

    test('returns empty for empty input', () {
      final result = formatText('');
      expect(result.text, '');
    });

    test('formats simple number', () {
      final result = formatText('1000');
      expect(result.text, '1,000');
    });

    test('formats large number with commas', () {
      final result = formatText('1234567');
      expect(result.text, '1,234,567');
    });

    test('removes non-numeric characters', () {
      final result = formatText('abc123def');
      expect(result.text, '123');
    });

    test('handles existing commas', () {
      final result = formatText('1,234,567');
      expect(result.text, '1,234,567');
    });

    test('handles decimal input', () {
      final result = formatText('1234.56');
      expect(result.text, '1,234.56');
    });

    test('handles leading zero', () {
      final result = formatText('0123');
      expect(result.text, '123');
    });

    group('with allowNegative', () {
      setUp(() {
        formatter = CurrencyInputFormatter(allowNegative: true);
      });

      test('allows negative numbers', () {
        final result = formatText('-1000');
        expect(result.text, '-1,000');
      });

      test('formats negative large numbers', () {
        final result = formatText('-1234567');
        expect(result.text, '-1,234,567');
      });
    });

    group('without allowNegative', () {
      setUp(() {
        formatter = CurrencyInputFormatter();
      });

      test('removes negative sign', () {
        final result = formatText('-1000');
        expect(result.text, '1,000');
      });
    });

    test('maintains cursor position relative to end', () {
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(
          text: '12345',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(result.selection.baseOffset, isNonNegative);
    });
  });
}
