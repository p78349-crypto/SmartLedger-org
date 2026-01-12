import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/food_expiry_item.dart';
import 'package:smart_ledger/utils/recipe_recommendation_utils.dart';

void main() {
  group('RecipeRecommendationUtils', () {
    FoodExpiryItem item(
      String name, {
      required DateTime now,
      int daysUntilExpiry = 10,
    }) {
      return FoodExpiryItem(
        id: 'id_$name',
        name: name,
        purchaseDate: now.subtract(const Duration(days: 1)),
        expiryDate: now.add(Duration(days: daysUntilExpiry)),
        createdAt: now.subtract(const Duration(days: 1)),
      );
    }

    test('getRecommendedRecipes recommends default recipes when >=50% ingredients match', () async {
      final now = DateTime(2026, 1, 10);
      final available = [
        item('계란', now: now),
        item('소금', now: now),
      ];

      final map = await RecipeRecommendationUtils.getRecommendedRecipes(
        available,
        includeUserRecipes: false,
      );

      // 계란프라이 requires ['계란','버터','소금'] => 2/3 => 66%
      expect(map.keys, contains('계란프라이'));
      final match = map['계란프라이']!;
      expect(match.matchPercentage, greaterThanOrEqualTo(50));
      expect(match.requiredCount, 3);
      expect(match.availableCount, 2);
    });

    test('prioritizeExpiring sorts recipes using expiringIngredientCount first', () async {
      final now = DateTime(2026, 1, 10);
      final available = [
        item('계란', now: now, daysUntilExpiry: 1), // expiring
        item('소금', now: now),
        item('두부', now: now, daysUntilExpiry: 1), // expiring
        item('간장', now: now),
        item('마늘', now: now),
        item('파', now: now),
      ];

      final list = await RecipeRecommendationUtils.getTopRecommendations(
        available,
        limit: 5,
        includeUserRecipes: false,
      );

      expect(list, isNotEmpty);
      // At least one recipe should report expiring usage.
      expect(list.any((e) => e.expiringIngredientCount > 0), isTrue);
    });

    test('RecipeMatch.message includes flags and availability summary', () {
      final m = RecipeMatch(
        recipeName: 'x',
        requiredCount: 5,
        availableCount: 5,
        matchPercentage: 100,
        expiringIngredientCount: 1,
        healthScore: 5,
      );

      expect(m.usesExpiringIngredients, isTrue);
      expect(m.isVeryHealthy, isTrue);
      expect(m.message, contains('유통기한 임박'));
      expect(m.message, contains('매우 건강'));
      expect(m.message, contains('모든 재료 준비됨'));
    });

    test('generateRecommendationMessage lists up to 3 expiring items', () {
      final now = DateTime(2026, 1, 10);
      final expiring = [
        item('a', now: now, daysUntilExpiry: 1),
        item('b', now: now, daysUntilExpiry: 1),
        item('c', now: now, daysUntilExpiry: 1),
        item('d', now: now, daysUntilExpiry: 1),
      ];
      final recipe = RecipeMatch(recipeName: '요리', requiredCount: 1, availableCount: 1, matchPercentage: 100);

      final msg = RecipeRecommendationUtils.generateRecommendationMessage(expiring, recipe);
      expect(msg, contains('a'));
      expect(msg, contains('b'));
      expect(msg, contains('c'));
      expect(msg, isNot(contains('d')));
    });
  });
}
