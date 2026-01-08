import 'package:shared_preferences/shared_preferences.dart';

/// 개인 선호도 기반 추천 커스터마이징 유틸리티
class UserPreferenceUtils {
  static const String _prefKeyMealPreference = 'meal_preference';
  static const String _prefKeyBudgetLimit = 'budget_limit';
  static const String _prefKeyFavoriteRecipes = 'favorite_recipes';
  static const String _prefKeyDietaryRestrictions = 'dietary_restrictions';
  static const String _prefKeyPreferredCategories = 'preferred_categories';
  static const String _prefKeyMealPrepName = 'meal_prep_name';
  static const String _prefKeyNotificationEnabled = 'notification_enabled';
  static const String _prefKeyDarkMode = 'dark_mode';
  static const String _prefKeyLanguage = 'language';

  // ===== Meal Preference =====

  /// 식사 선호도 저장
  static Future<void> setMealPreference(String preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyMealPreference, preference);
  }

  /// 식사 선호도 조회
  static Future<String> getMealPreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyMealPreference) ?? '한식 중심';
  }

  // ===== Budget Limit =====

  /// 월별 예산 한도 저장
  static Future<void> setBudgetLimit(int budget) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKeyBudgetLimit, budget);
  }

  /// 월별 예산 한도 조회
  static Future<int> getBudgetLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefKeyBudgetLimit) ?? 500000;
  }

  // ===== Favorite Recipes =====

  /// 선호 요리 목록 저장
  static Future<void> setFavoriteRecipes(List<String> recipes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKeyFavoriteRecipes, recipes);
  }

  /// 선호 요리 목록 조회
  static Future<List<String>> getFavoriteRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefKeyFavoriteRecipes) ?? [];
  }

  /// 선호 요리 추가
  static Future<void> addFavoriteRecipe(String recipe) async {
    final recipes = await getFavoriteRecipes();
    if (!recipes.contains(recipe)) {
      recipes.add(recipe);
      await setFavoriteRecipes(recipes);
    }
  }

  /// 선호 요리 제거
  static Future<void> removeFavoriteRecipe(String recipe) async {
    final recipes = await getFavoriteRecipes();
    recipes.removeWhere((r) => r == recipe);
    await setFavoriteRecipes(recipes);
  }

  // ===== Dietary Restrictions =====

  /// 식단 제한사항 저장 (알레르기, 비건 등)
  static Future<void> setDietaryRestrictions(List<String> restrictions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKeyDietaryRestrictions, restrictions);
  }

  /// 식단 제한사항 조회
  static Future<List<String>> getDietaryRestrictions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefKeyDietaryRestrictions) ?? [];
  }

  /// 제한사항 추가
  static Future<void> addRestriction(String restriction) async {
    final restrictions = await getDietaryRestrictions();
    if (!restrictions.contains(restriction)) {
      restrictions.add(restriction);
      await setDietaryRestrictions(restrictions);
    }
  }

  /// 제한사항 제거
  static Future<void> removeRestriction(String restriction) async {
    final restrictions = await getDietaryRestrictions();
    restrictions.removeWhere((r) => r == restriction);
    await setDietaryRestrictions(restrictions);
  }

  // ===== Preferred Categories =====

  /// 선호 식재료 카테고리 저장
  static Future<void> setPreferredCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKeyPreferredCategories, categories);
  }

  /// 선호 식재료 카테고리 조회
  static Future<List<String>> getPreferredCategories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_prefKeyPreferredCategories) ?? [];
  }

  // ===== Meal Prep Name (식사 준비 이름) =====

  /// 식사 준비 이름 저장 (예: "김은서 도시락", "가족 식단")
  static Future<void> setMealPrepName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyMealPrepName, name);
  }

  /// 식사 준비 이름 조회
  static Future<String> getMealPrepName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyMealPrepName) ?? '식사 준비';
  }

  // ===== Notification Settings =====

  /// 알림 활성화 여부 저장
  static Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyNotificationEnabled, enabled);
  }

  /// 알림 활성화 여부 조회
  static Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyNotificationEnabled) ?? true;
  }

  // ===== UI Settings =====

  /// 다크모드 저장
  static Future<void> setDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyDarkMode, enabled);
  }

  /// 다크모드 조회
  static Future<bool> isDarkModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKeyDarkMode) ?? false;
  }

  /// 언어 설정 저장
  static Future<void> setLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyLanguage, language);
  }

  /// 언어 설정 조회
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyLanguage) ?? '한국어';
  }

  // ===== Helper Methods =====

  /// 모든 설정 조회
  static Future<UserPreferences> getAllPreferences() async {
    return UserPreferences(
      mealPreference: await getMealPreference(),
      budgetLimit: await getBudgetLimit(),
      favoriteRecipes: await getFavoriteRecipes(),
      dietaryRestrictions: await getDietaryRestrictions(),
      preferredCategories: await getPreferredCategories(),
      mealPrepName: await getMealPrepName(),
      notificationEnabled: await isNotificationEnabled(),
      darkModeEnabled: await isDarkModeEnabled(),
      language: await getLanguage(),
    );
  }

  /// 모든 설정 초기화
  static Future<void> resetAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyMealPreference);
    await prefs.remove(_prefKeyBudgetLimit);
    await prefs.remove(_prefKeyFavoriteRecipes);
    await prefs.remove(_prefKeyDietaryRestrictions);
    await prefs.remove(_prefKeyPreferredCategories);
    await prefs.remove(_prefKeyMealPrepName);
    await prefs.remove(_prefKeyNotificationEnabled);
    await prefs.remove(_prefKeyDarkMode);
    await prefs.remove(_prefKeyLanguage);
  }

  /// 추천 설정값 (기본값)
  static UserPreferences getDefaultPreferences() {
    return UserPreferences(
      mealPreference: '한식 중심',
      budgetLimit: 500000,
      favoriteRecipes: [],
      dietaryRestrictions: [],
      preferredCategories: [],
      mealPrepName: '식사 준비',
      notificationEnabled: true,
      darkModeEnabled: false,
      language: '한국어',
    );
  }

  /// 추천 메시지 생성
  static String getPersonalizedMessage(UserPreferences prefs) {
    return '${prefs.mealPrepName}를 위한 개인화된 추천입니다.\n'
        '선호도: ${prefs.mealPreference}\n'
        '월 예산: ${prefs.budgetLimit}원';
  }
}

/// 사용자 설정 정보
class UserPreferences {
  final String mealPreference;
  final int budgetLimit;
  final List<String> favoriteRecipes;
  final List<String> dietaryRestrictions;
  final List<String> preferredCategories;
  final String mealPrepName;
  final bool notificationEnabled;
  final bool darkModeEnabled;
  final String language;

  UserPreferences({
    required this.mealPreference,
    required this.budgetLimit,
    required this.favoriteRecipes,
    required this.dietaryRestrictions,
    required this.preferredCategories,
    required this.mealPrepName,
    required this.notificationEnabled,
    required this.darkModeEnabled,
    required this.language,
  });

  /// 제한사항이 적용된 추천 필터
  bool isIngredientAllowed(String ingredientName) {
    for (final restriction in dietaryRestrictions) {
      if (ingredientName.toLowerCase().contains(restriction.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  /// 선호 카테고리 포함 여부
  bool isPreferredCategory(String category) {
    if (preferredCategories.isEmpty) return true;
    return preferredCategories.contains(category);
  }

  /// 설정 요약 정보
  String getSummary() {
    final restrictions = dietaryRestrictions.isEmpty
        ? '제한사항 없음'
        : dietaryRestrictions.join(', ');
    return '$mealPreference | 예산 $budgetLimit원 | $restrictions';
  }
}
