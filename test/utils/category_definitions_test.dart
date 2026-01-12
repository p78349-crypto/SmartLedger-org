import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/category_definitions.dart';

void main() {
  group('CategoryDefinitions', () {
    test('defaultCategory is 미분류', () {
      expect(CategoryDefinitions.defaultCategory, '미분류');
    });

    test('categoryOptions contains default category', () {
      expect(
        CategoryDefinitions.categoryOptions.containsKey(
          CategoryDefinitions.defaultCategory,
        ),
        true,
      );
    });

    test('default category has empty subcategory list', () {
      expect(
        CategoryDefinitions.categoryOptions[CategoryDefinitions.defaultCategory],
        isEmpty,
      );
    });

    test('categoryOptions contains expected main categories', () {
      const options = CategoryDefinitions.categoryOptions;
      expect(options.containsKey('식품·음료비'), true);
      expect(options.containsKey('식비'), true);
      expect(options.containsKey('주거비'), true);
      expect(options.containsKey('교통비'), true);
      expect(options.containsKey('통신비'), true);
      expect(options.containsKey('생활용품비'), true);
      expect(options.containsKey('의료비'), true);
      expect(options.containsKey('저축/투자'), true);
    });

    test('식비 has expected subcategories', () {
      final subcategories = CategoryDefinitions.categoryOptions['식비'];
      expect(subcategories, isNotNull);
      expect(subcategories!.contains('외식'), true);
      expect(subcategories.contains('배달'), true);
      expect(subcategories.contains('간식'), true);
    });

    test('주거비 has expected subcategories', () {
      final subcategories = CategoryDefinitions.categoryOptions['주거비'];
      expect(subcategories, isNotNull);
      expect(subcategories!.contains('월세'), true);
      expect(subcategories.contains('전기요금'), true);
      expect(subcategories.contains('관리비'), true);
    });

    test('mainCategories returns all category keys', () {
      final mainCategories = CategoryDefinitions.mainCategories;
      final optionKeys = CategoryDefinitions.categoryOptions.keys.toList();
      expect(mainCategories, optionKeys);
    });

    test('mainCategories is not growable', () {
      final mainCategories = CategoryDefinitions.mainCategories;
      expect(() => mainCategories.add('test'), throwsUnsupportedError);
    });

    test('shoppingMainCategories contains expected categories', () {
      const shopping = CategoryDefinitions.shoppingMainCategories;
      expect(shopping.contains('식품·음료비'), true);
      expect(shopping.contains('생활용품비'), true);
      expect(shopping.contains('의류/잡화'), true);
      expect(shopping.contains(CategoryDefinitions.defaultCategory), true);
    });

    test('shoppingMainCategories are subset of mainCategories', () {
      final mainCategories = CategoryDefinitions.mainCategories;
      for (final category in CategoryDefinitions.shoppingMainCategories) {
        expect(
          mainCategories.contains(category),
          true,
          reason: '$category should be in mainCategories',
        );
      }
    });

    test('all subcategories are non-null lists', () {
      for (final entry in CategoryDefinitions.categoryOptions.entries) {
        expect(entry.value, isA<List<String>>());
      }
    });
  });
}
