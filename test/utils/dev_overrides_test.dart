import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/dev_overrides.dart';

void main() {
  test('kDevBypassSecurity is safe-by-default (false)', () {
    expect(kDevBypassSecurity, isFalse);
  });
}
