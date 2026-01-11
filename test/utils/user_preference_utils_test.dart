import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/utils/user_preference_utils.dart';

void main() {
  group('UserPreferenceUtils', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
    });

    test('set/get basic prefs roundtrip', () async {
      await UserPreferenceUtils.setMealPreference('양식');
      expect(await UserPreferenceUtils.getMealPreference(), '양식');

      await UserPreferenceUtils.setBudgetLimit(123);
      expect(await UserPreferenceUtils.getBudgetLimit(), 123);

      await UserPreferenceUtils.setLanguage('English');
      expect(await UserPreferenceUtils.getLanguage(), 'English');

      await UserPreferenceUtils.setDarkMode(true);
      expect(await UserPreferenceUtils.isDarkModeEnabled(), isTrue);
    });

    test('favorite recipes add/remove is idempotent', () async {
      await UserPreferenceUtils.addFavoriteRecipe('김치찌개');
      await UserPreferenceUtils.addFavoriteRecipe('김치찌개');
      final recipes = await UserPreferenceUtils.getFavoriteRecipes();
      expect(recipes.where((r) => r == '김치찌개').length, 1);

      await UserPreferenceUtils.removeFavoriteRecipe('김치찌개');
      expect(await UserPreferenceUtils.getFavoriteRecipes(), isEmpty);
    });

    test('getAllPreferences reflects stored values', () async {
      await UserPreferenceUtils.setMealPrepName('우리집');
      await UserPreferenceUtils.setMealPreference('한식');
      await UserPreferenceUtils.setBudgetLimit(777);
      await UserPreferenceUtils.setPreferredCategories(['채소']);
      await UserPreferenceUtils.setDietaryRestrictions(['우유']);

      final prefs = await UserPreferenceUtils.getAllPreferences();
      expect(prefs.mealPrepName, '우리집');
      expect(prefs.budgetLimit, 777);
      expect(prefs.preferredCategories, ['채소']);
      expect(prefs.dietaryRestrictions, ['우유']);

      final msg = UserPreferenceUtils.getPersonalizedMessage(prefs);
      expect(msg, contains('우리집'));
      expect(msg, contains('777원'));
    });

    test('resetAllPreferences restores defaults', () async {
      await UserPreferenceUtils.setMealPreference('양식');
      await UserPreferenceUtils.resetAllPreferences();
      expect(await UserPreferenceUtils.getMealPreference(), '한식 중심');
    });
  });

  group('UserPreferences', () {
    test('isIngredientAllowed respects restrictions (case-insensitive)', () {
      final prefs = UserPreferences(
        mealPreference: 'x',
        budgetLimit: 0,
        favoriteRecipes: const [],
        dietaryRestrictions: const ['Milk'],
        preferredCategories: const [],
        mealPrepName: 'x',
        notificationEnabled: true,
        darkModeEnabled: false,
        language: 'x',
      );

      expect(prefs.isIngredientAllowed('oat milk'), isFalse);
      expect(prefs.isIngredientAllowed('banana'), isTrue);
    });

    test('isPreferredCategory defaults to true when empty list', () {
      final prefs = UserPreferences(
        mealPreference: 'x',
        budgetLimit: 0,
        favoriteRecipes: const [],
        dietaryRestrictions: const [],
        preferredCategories: const [],
        mealPrepName: 'x',
        notificationEnabled: true,
        darkModeEnabled: false,
        language: 'x',
      );
      expect(prefs.isPreferredCategory('채소'), isTrue);
    });

    test('summary formats key info', () {
      final prefs = UserPreferences(
        mealPreference: '한식',
        budgetLimit: 500000,
        favoriteRecipes: const [],
        dietaryRestrictions: const ['견과류'],
        preferredCategories: const ['채소'],
        mealPrepName: '식사 준비',
        notificationEnabled: true,
        darkModeEnabled: false,
        language: '한국어',
      );
      expect(prefs.getSummary(), contains('한식'));
      expect(prefs.getSummary(), contains('500000원'));
      expect(prefs.getSummary(), contains('견과류'));
    });
  });
}
