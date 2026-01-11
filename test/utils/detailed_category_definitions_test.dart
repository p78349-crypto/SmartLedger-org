import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/detailed_category_definitions.dart';

void main() {
  group('DetailedCategoryDefinitions', () {
    test('defaultCategory is 미분류', () {
      expect(DetailedCategoryDefinitions.defaultCategory, '미분류');
    });

    test('categoryOptions is not empty', () {
      expect(DetailedCategoryDefinitions.categoryOptions, isNotEmpty);
    });

    test('categoryOptions contains expected main categories', () {
      final options = DetailedCategoryDefinitions.categoryOptions;
      expect(options.containsKey('식품·음료비'), true);
      expect(options.containsKey('주거비'), true);
      expect(options.containsKey('교통비'), true);
      expect(options.containsKey('생활용품비'), true);
      expect(options.containsKey('저축/투자'), true);
    });

    test('식품·음료비 has sub-categories', () {
      final subcategories =
          DetailedCategoryDefinitions.categoryOptions['식품·음료비'];
      expect(subcategories, isNotNull);
      expect(subcategories!.containsKey('장보기'), true);
      expect(subcategories.containsKey('외식'), true);
    });

    test('장보기 has detail categories', () {
      final details =
          DetailedCategoryDefinitions.categoryOptions['식품·음료비']?['장보기'];
      expect(details, isNotNull);
      expect(details!.contains('채소'), true);
      expect(details.contains('과일'), true);
      expect(details.contains('육류'), true);
    });

    group('mainCategories', () {
      test('returns all category keys', () {
        final mainCategories = DetailedCategoryDefinitions.mainCategories;
        final optionKeys =
            DetailedCategoryDefinitions.categoryOptions.keys.toList();
        expect(mainCategories, optionKeys);
      });

      test('is not growable', () {
        final mainCategories = DetailedCategoryDefinitions.mainCategories;
        expect(() => mainCategories.add('test'), throwsUnsupportedError);
      });
    });

    group('getSubCategories', () {
      test('returns sub-categories for valid main category', () {
        final subcategories =
            DetailedCategoryDefinitions.getSubCategories('식품·음료비');
        expect(subcategories, contains('장보기'));
        expect(subcategories, contains('외식'));
      });

      test('returns empty list for invalid main category', () {
        final subcategories =
            DetailedCategoryDefinitions.getSubCategories('없는카테고리');
        expect(subcategories, isEmpty);
      });

      test('returned list is not growable', () {
        final subcategories =
            DetailedCategoryDefinitions.getSubCategories('식품·음료비');
        expect(() => subcategories.add('test'), throwsUnsupportedError);
      });
    });

    group('getDetailCategories', () {
      test('returns detail categories for valid path', () {
        final details = DetailedCategoryDefinitions.getDetailCategories(
          '식품·음료비',
          '장보기',
        );
        expect(details, contains('채소'));
        expect(details, contains('과일'));
      });

      test('returns empty list for invalid main category', () {
        final details = DetailedCategoryDefinitions.getDetailCategories(
          '없는카테고리',
          '장보기',
        );
        expect(details, isEmpty);
      });

      test('returns empty list for invalid sub category', () {
        final details = DetailedCategoryDefinitions.getDetailCategories(
          '식품·음료비',
          '없는서브',
        );
        expect(details, isEmpty);
      });
    });

    group('shoppingMainCategories', () {
      test('contains expected categories', () {
        const shopping = DetailedCategoryDefinitions.shoppingMainCategories;
        expect(shopping.contains('식품·음료비'), true);
        expect(shopping.contains('생활용품비'), true);
        expect(shopping.contains('의류/패션'), true);
      });

      test('includes default category', () {
        expect(
          DetailedCategoryDefinitions.shoppingMainCategories,
          contains(DetailedCategoryDefinitions.defaultCategory),
        );
      });
    });
  });
}
