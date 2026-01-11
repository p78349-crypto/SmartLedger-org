import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/nutrition_food_knowledge.dart';

void main() {
  group('NutritionFoodKnowledge', () {
    test('allEntries is non-empty', () {
      expect(NutritionFoodKnowledge.allEntries, isNotEmpty);
    });

    test('lookup returns null for empty query', () {
      expect(NutritionFoodKnowledge.lookup(''), isNull);
      expect(NutritionFoodKnowledge.lookup('   '), isNull);
    });

    test('lookup matches exact and normalized queries', () {
      final egg = NutritionFoodKnowledge.lookup('계란');
      expect(egg, isNotNull);
      expect(egg!.primaryName, contains('달걀'));

      // Normalization removes spaces and hyphens.
      final chicken = NutritionFoodKnowledge.lookup('chicken breast');
      expect(chicken, isNotNull);
      expect(chicken!.primaryName, contains('닭고기'));

      final chicken2 = NutritionFoodKnowledge.lookup('chicken-breast');
      expect(chicken2, isNotNull);
      expect(chicken2!.primaryName, contains('닭고기'));
    });
  });
}
