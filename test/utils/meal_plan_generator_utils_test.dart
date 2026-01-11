import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/food_expiry_item.dart';
import 'package:smart_ledger/utils/meal_plan_generator_utils.dart';

void main() {
  group('MealPlanGeneratorUtils', () {
    FoodExpiryItem item(String name) => FoodExpiryItem(
          id: 'id_$name',
          name: name,
          memo: '',
          createdAt: DateTime(2026, 1, 1),
          purchaseDate: DateTime(2026, 1, 1),
          expiryDate: DateTime(2026, 1, 10),
          quantity: 1.0,
          unit: '개',
          location: '냉장',
          category: '테스트',
          supplier: '',
        );

    test('generate3DayMealPlan returns 3 days with non-empty meals', () {
      final plans = MealPlanGeneratorUtils.generate3DayMealPlan(
        [item('계란'), item('두부')],
        preference: '한식 중심',
      );

      expect(plans.length, 3);
      for (final p in plans) {
        expect(p.meals.breakfast, isNotEmpty);
        expect(p.meals.lunch, isNotEmpty);
        expect(p.meals.dinner, isNotEmpty);
        expect(p.meals.breakfastOptions, isNotEmpty);
        expect(p.meals.lunchOptions, isNotEmpty);
        expect(p.meals.dinnerOptions, isNotEmpty);
      }
    });

    test('getMealExplanation mentions owned ingredients when matched', () {
      final items = [item('계란')];
      final msg = MealPlanGeneratorUtils.getMealExplanation('계란프라이', items);
      expect(msg, contains('보유한'));
    });

    test('getMealPlanSummary handles empty and 3-day plans', () {
      expect(MealPlanGeneratorUtils.getMealPlanSummary(const []), contains('없습니다'));

      final plans = MealPlanGeneratorUtils.generate3DayMealPlan(const []);
      final summary = MealPlanGeneratorUtils.getMealPlanSummary(plans);
      expect(summary, contains('향후 3일'));
    });

    test('analyzeMealNutrition returns good balance when protein+veg+carb are present', () {
      final meals = DayMeals(
        breakfast: '계란',
        lunch: '샐러드',
        dinner: '밥',
        breakfastOptions: const ['계란'],
        lunchOptions: const ['샐러드'],
        dinnerOptions: const ['밥'],
      );
      expect(MealPlanGeneratorUtils.analyzeMealNutrition(meals), contains('영양'));
    });

    test('getCookingDifficulty returns expected labels', () {
      expect(MealPlanGeneratorUtils.getCookingDifficulty('계란말이'), contains('쉬움'));
      expect(MealPlanGeneratorUtils.getCookingDifficulty('두부조림'), contains('어려움'));
      expect(MealPlanGeneratorUtils.getCookingDifficulty('김치'), contains('보통'));
    });
  });
}
