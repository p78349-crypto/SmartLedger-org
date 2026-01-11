import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/food_expiry_item.dart';
import 'package:smart_ledger/utils/ingredients_recommendation_utils.dart';

void main() {
  group('IngredientsRecommendationUtils', () {
    group('nutritionCategories', () {
      test('contains expected categories', () {
        final categories = IngredientsRecommendationUtils.nutritionCategories;
        expect(categories.containsKey('단백질'), true);
        expect(categories.containsKey('탄수화물'), true);
        expect(categories.containsKey('채소'), true);
        expect(categories.containsKey('과일'), true);
        expect(categories.containsKey('유제품'), true);
        expect(categories.containsKey('기름/양념'), true);
      });

      test('단백질 category contains protein sources', () {
        final proteins =
            IngredientsRecommendationUtils.nutritionCategories['단백질'];
        expect(proteins, contains('계란'));
        expect(proteins, contains('닭가슴살'));
        expect(proteins, contains('두부'));
      });

      test('채소 category contains vegetables', () {
        final veggies =
            IngredientsRecommendationUtils.nutritionCategories['채소'];
        expect(veggies, contains('당근'));
        expect(veggies, contains('브로콜리'));
        expect(veggies, contains('시금치'));
      });
    });

    group('getNutritionCategory', () {
      test('returns 단백질 for egg', () {
        final category =
            IngredientsRecommendationUtils.getNutritionCategory('계란');
        expect(category, '단백질');
      });

      test('returns 채소 for carrot', () {
        final category =
            IngredientsRecommendationUtils.getNutritionCategory('당근');
        expect(category, '채소');
      });

      test('returns 과일 for apple', () {
        final category =
            IngredientsRecommendationUtils.getNutritionCategory('사과');
        expect(category, '과일');
      });

      test('returns 기타 for unknown ingredient', () {
        final category =
            IngredientsRecommendationUtils.getNutritionCategory('알수없는음식');
        expect(category, '기타');
      });

      test('handles partial match', () {
        final category =
            IngredientsRecommendationUtils.getNutritionCategory('닭가슴살구이');
        expect(category, '단백질');
      });
    });

    group('getNutritionInfo', () {
      test('returns emoji and category for protein', () {
        final info =
            IngredientsRecommendationUtils.getNutritionInfo('계란');
        expect(info, contains('🥚'));
        expect(info, contains('단백질'));
      });

      test('returns emoji and category for vegetable', () {
        final info =
            IngredientsRecommendationUtils.getNutritionInfo('브로콜리');
        expect(info, contains('🥬'));
        expect(info, contains('채소'));
      });

      test('returns emoji and category for fruit', () {
        final info = IngredientsRecommendationUtils.getNutritionInfo('사과');
        expect(info, contains('🍎'));
        expect(info, contains('과일'));
      });
    });

    group('getPriceValueScore', () {
      test('returns score between 0 and 100', () {
        final now = DateTime.now();
        final item = FoodExpiryItem(
          id: '1',
          name: '테스트',
          purchaseDate: now,
          expiryDate: now.add(const Duration(days: 15)),
          createdAt: now,
          price: 5000.0,
        );
        final score = IngredientsRecommendationUtils.getPriceValueScore(item);
        expect(score, greaterThanOrEqualTo(0));
        expect(score, lessThanOrEqualTo(100));
      });

      test('higher score for items with more days left', () {
        final now = DateTime.now();
        final longExpiry = FoodExpiryItem(
          id: '1',
          name: '테스트',
          purchaseDate: now,
          expiryDate: now.add(const Duration(days: 30)),
          createdAt: now,
          price: 5000.0,
        );
        final shortExpiry = FoodExpiryItem(
          id: '2',
          name: '테스트',
          purchaseDate: now,
          expiryDate: now.add(const Duration(days: 5)),
          createdAt: now,
          price: 5000.0,
        );

        final longScore =
            IngredientsRecommendationUtils.getPriceValueScore(longExpiry);
        final shortScore =
            IngredientsRecommendationUtils.getPriceValueScore(shortExpiry);

        expect(longScore, greaterThan(shortScore));
      });

      test('higher score for lower price', () {
        final now = DateTime.now();
        final lowPrice = FoodExpiryItem(
          id: '1',
          name: '테스트',
          purchaseDate: now,
          expiryDate: now.add(const Duration(days: 15)),
          createdAt: now,
          price: 1000.0,
        );
        final highPrice = FoodExpiryItem(
          id: '2',
          name: '테스트',
          purchaseDate: now,
          expiryDate: now.add(const Duration(days: 15)),
          createdAt: now,
          price: 9000.0,
        );

        final lowPriceScore =
            IngredientsRecommendationUtils.getPriceValueScore(lowPrice);
        final highPriceScore =
            IngredientsRecommendationUtils.getPriceValueScore(highPrice);

        expect(lowPriceScore, greaterThan(highPriceScore));
      });
    });

    group('getOptimizedRecommendations', () {
      test('returns empty list for empty input', () {
        final result =
            IngredientsRecommendationUtils.getOptimizedRecommendations([]);
        expect(result, isEmpty);
      });

      test('sorts by expiry date first', () {
        final now = DateTime.now();
        final items = <FoodExpiryItem>[
          FoodExpiryItem(
            id: '1',
            name: '나중',
            purchaseDate: now,
            expiryDate: now.add(const Duration(days: 10)),
            createdAt: now,
          ),
          FoodExpiryItem(
            id: '2',
            name: '빠름',
            purchaseDate: now,
            expiryDate: now.add(const Duration(days: 2)),
            createdAt: now,
          ),
        ];

        final result =
            IngredientsRecommendationUtils.getOptimizedRecommendations(items);

        expect(result.first.name, '빠름');
      });

      test('respects limit parameter', () {
        final now = DateTime.now();
        final items = List<FoodExpiryItem>.generate(
          15,
          (i) => FoodExpiryItem(
            id: '$i',
            name: '아이템$i',
            purchaseDate: now,
            expiryDate: now.add(Duration(days: i)),
            createdAt: now,
          ),
        );

        final result =
            IngredientsRecommendationUtils.getOptimizedRecommendations(
          items,
          limit: 5,
        );

        expect(result.length, 5);
      });
    });
  });
}
