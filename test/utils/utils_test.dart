import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/utils.dart';

void main() {
  group('utils.dart barrel export', () {
    test('exports CurrencyFormatter and it formats values', () {
      // Just a smoke test to ensure the barrel file stays valid.
      final formatted = CurrencyFormatter.format(123456);
      expect(formatted, isNotEmpty);
    });

    test('exports Validators', () {
      expect(Validators.required('x'), isNull);
      expect(Validators.required(''), isNotNull);
    });
  });
}
