import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/shopping_category_rules.dart';

void main() {
  group('ShoppingCategoryRules', () {
    test('groups are ordered and non-empty', () {
      expect(ShoppingCategoryRules.groups, isNotEmpty);
      expect(ShoppingCategoryRules.groups.first, ShoppingCategoryRules.groceryKeywords);
    });

    test('known keyword maps to expected category pair', () {
      final pair = ShoppingCategoryRules.groceryKeywords['사과'];
      expect(pair, isNotNull);
      expect(pair!.mainCategory, '식품·음료비');
      expect(pair.subCategory, '장보기');
      expect(pair.detailCategory, isNull);
    });
  });
}
