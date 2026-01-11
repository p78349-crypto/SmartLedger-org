import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/shopping_repurchase_rules.dart';

void main() {
  group('ShoppingRepurchaseRules', () {
    test('keywordToMinDays contains common items', () {
      expect(ShoppingRepurchaseRules.keywordToMinDays, isNotEmpty);
      expect(ShoppingRepurchaseRules.keywordToMinDays['우유'], 3);
      expect(ShoppingRepurchaseRules.keywordToMinDays['사과'], 30);
    });

    test('defaultMinDays is 7', () {
      expect(ShoppingRepurchaseRules.defaultMinDays, 7);
    });
  });
}
