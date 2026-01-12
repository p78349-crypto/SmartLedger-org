import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/income_category_definitions.dart';

void main() {
  group('IncomeCategoryDefinitions', () {
    test('defaultCategory is 미분류', () {
      expect(IncomeCategoryDefinitions.defaultCategory, '미분류');
    });

    test('categoryOptions contains default category', () {
      expect(
        IncomeCategoryDefinitions.categoryOptions.containsKey(
          IncomeCategoryDefinitions.defaultCategory,
        ),
        true,
      );
    });

    test('default category has empty subcategory list', () {
      expect(
        IncomeCategoryDefinitions
            .categoryOptions[IncomeCategoryDefinitions.defaultCategory],
        isEmpty,
      );
    });

    test('categoryOptions contains expected main categories', () {
      const options = IncomeCategoryDefinitions.categoryOptions;
      expect(options.containsKey('주수입'), true);
      expect(options.containsKey('사업소득'), true);
      expect(options.containsKey('부수입'), true);
      expect(options.containsKey('금융소득'), true);
      expect(options.containsKey('기타소득'), true);
    });

    test('주수입 has expected subcategories', () {
      final subcategories =
          IncomeCategoryDefinitions.categoryOptions['주수입'];
      expect(subcategories, isNotNull);
      expect(subcategories!.contains('급여'), true);
      expect(subcategories.contains('배우자 급여'), true);
    });

    test('금융소득 has expected subcategories', () {
      final subcategories =
          IncomeCategoryDefinitions.categoryOptions['금융소득'];
      expect(subcategories, isNotNull);
      expect(subcategories!.contains('예적금 이자'), true);
      expect(subcategories.contains('배당금'), true);
      expect(subcategories.contains('주식 수익'), true);
    });

    group('mainCategories', () {
      test('returns all category keys', () {
        final mainCategories = IncomeCategoryDefinitions.mainCategories;
        final optionKeys =
            IncomeCategoryDefinitions.categoryOptions.keys.toList();
        expect(mainCategories, optionKeys);
      });

      test('is not growable', () {
        final mainCategories = IncomeCategoryDefinitions.mainCategories;
        expect(() => mainCategories.add('test'), throwsUnsupportedError);
      });
    });

    group('defaultMainCategory', () {
      test('returns first category with non-empty subcategories', () {
        final defaultMain = IncomeCategoryDefinitions.defaultMainCategory;
        expect(defaultMain, isNotNull);
        expect(defaultMain, isNot(IncomeCategoryDefinitions.defaultCategory));

        final subs =
            IncomeCategoryDefinitions.categoryOptions[defaultMain];
        expect(subs, isNotEmpty);
      });
    });

    group('firstSubcategoryOf', () {
      test('returns first subcategory for valid main category', () {
        final first = IncomeCategoryDefinitions.firstSubcategoryOf('주수입');
        expect(first, '급여');
      });

      test('returns null for invalid main category', () {
        final first =
            IncomeCategoryDefinitions.firstSubcategoryOf('없는카테고리');
        expect(first, isNull);
      });

      test('returns null for category with empty subcategories', () {
        final first = IncomeCategoryDefinitions.firstSubcategoryOf(
          IncomeCategoryDefinitions.defaultCategory,
        );
        expect(first, isNull);
      });
    });
  });
}
