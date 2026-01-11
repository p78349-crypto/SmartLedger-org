import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/thousands_input_formatter.dart';

void main() {
  group('ThousandsInputFormatter', () {
    late ThousandsInputFormatter formatter;

    setUp(() {
      formatter = const ThousandsInputFormatter();
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

    test('formats simple integer with commas', () {
      final result = formatText('1000');
      expect(result.text, '1,000');
    });

    test('removes decimal part (integer-only)', () {
      final result = formatText('1234.56');
      expect(result.text, '1,234');
    });

    test('removes non-numeric characters', () {
      final result = formatText('abc123def');
      expect(result.text, '123');
    });

    test('handles existing commas', () {
      final result = formatText('1,234,567');
      expect(result.text, '1,234,567');
    });

    test('handles leading zero', () {
      final result = formatText('0123');
      expect(result.text, '123');
    });
  });
}
