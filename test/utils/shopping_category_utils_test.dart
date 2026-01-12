import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/category_hint.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/utils/category_definitions.dart';
import 'package:smart_ledger/utils/shopping_category_utils.dart';

void main() {
  group('ShoppingCategoryUtils', () {
    ShoppingCartItem item(String name) => ShoppingCartItem(
          id: 'id',
          name: name,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        );

    test('normalizeHintKey trims/lowercases/removes spaces', () {
      expect(ShoppingCategoryUtils.normalizeHintKey('  Ab C  '), 'abc');
    });

    test('validateSuggestion falls back for unknown main category', () {
      final validated = ShoppingCategoryUtils.validateSuggestion(
        (mainCategory: '없는카테고리', subCategory: 'x', detailCategory: 'y'),
      );
      expect(validated.mainCategory, CategoryDefinitions.defaultCategory);
      expect(validated.subCategory, isNull);
    });

    test('validateSuggestion drops unknown subcategory', () {
      final validated = ShoppingCategoryUtils.validateSuggestion(
        (mainCategory: '식비', subCategory: '없는서브', detailCategory: 'x'),
      );
      expect(validated.mainCategory, '식비');
      expect(validated.subCategory, isNull);
      expect(validated.detailCategory, isNull);
    });

    test('suggestBuiltIn uses first keyword match and validates', () {
      final suggestion = ShoppingCategoryUtils.suggestBuiltIn(item('사과 1개'));
      expect(suggestion.mainCategory, '식품·음료비');
      expect(suggestion.subCategory, '장보기');
    });

    test('hintFromLearned supports exact and contains matching', () {
      final hints = <String, CategoryHint>{
        ShoppingCategoryUtils.normalizeHintKey('사과'): const CategoryHint(
          mainCategory: '식품·음료비',
          subCategory: '장보기',
        ),
        ShoppingCategoryUtils.normalizeHintKey('바나'): const CategoryHint(
          mainCategory: '식품·음료비',
          subCategory: '장보기',
        ),
      };

      final exact = ShoppingCategoryUtils.hintFromLearned(item('사과'), hints);
      expect(exact, isNotNull);
      expect(exact!.mainCategory, '식품·음료비');

      final contains = ShoppingCategoryUtils.hintFromLearned(item('바나나 우유'), hints);
      expect(contains, isNotNull);
      expect(contains!.mainCategory, '식품·음료비');
    });

    test('suggest prefers learned hints when shopping-main-categories', () {
      final hints = <String, CategoryHint>{
        ShoppingCategoryUtils.normalizeHintKey('사과'): const CategoryHint(
          mainCategory: '생활용품비',
          subCategory: '주방용품',
        ),
      };

      final suggestion = ShoppingCategoryUtils.suggest(
        item('사과'),
        learnedHints: hints,
      );
      expect(CategoryDefinitions.shoppingMainCategories.contains(suggestion.mainCategory), isTrue);
      expect(suggestion.mainCategory, '생활용품비');
    });
  });
}
