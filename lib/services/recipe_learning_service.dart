import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// 사용자의 요리 패턴을 학습하는 서비스
class RecipeLearningService {
  RecipeLearningService._();
  static final RecipeLearningService instance = RecipeLearningService._();

  static const String _keyRecipeHistory = 'recipe_history';
  static const String _keyIngredientFrequency = 'ingredient_frequency';
  static const String _keyMealTimePreference = 'meal_time_preference';
  static const String _keyHealthPreference = 'health_preference_score';

  /// 요리 기록 저장 (사용자가 레시피를 선택할 때마다 호출)
  Future<void> recordRecipeUsage({
    required String recipeName,
    required List<String> ingredients,
    required int healthScore,
    String? mealTime, // 'breakfast', 'lunch', 'dinner'
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 요리 빈도 업데이트
    await _updateRecipeFrequency(prefs, recipeName);

    // 2. 재료 사용 빈도 업데이트
    await _updateIngredientFrequency(prefs, ingredients);

    // 3. 시간대별 선호도 업데이트
    if (mealTime != null) {
      await _updateMealTimePreference(prefs, recipeName, mealTime);
    }

    // 4. 건강 선호도 업데이트
    await _updateHealthPreference(prefs, healthScore);

    debugPrint('RecipeLearningService: Recorded $recipeName usage');
  }

  /// 자주 만드는 요리 순위 가져오기
  Future<Map<String, int>> getRecipeFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyRecipeHistory);
    if (json == null) return {};

    final Map<String, dynamic> data = jsonDecode(json);
    return data.map((key, value) => MapEntry(key, value as int));
  }

  /// 자주 사용하는 재료 순위 가져오기
  Future<Map<String, int>> getIngredientFrequency() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyIngredientFrequency);
    if (json == null) return {};

    final Map<String, dynamic> data = jsonDecode(json);
    return data.map((key, value) => MapEntry(key, value as int));
  }

  /// 시간대별 선호 요리 가져오기
  Future<Map<String, Map<String, int>>> getMealTimePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyMealTimePreference);
    if (json == null) return {};

    final Map<String, dynamic> data = jsonDecode(json);
    return data.map(
      (mealTime, recipes) => MapEntry(
        mealTime,
        (recipes as Map<String, dynamic>).map(
          (recipe, count) => MapEntry(recipe, count as int),
        ),
      ),
    );
  }

  /// 건강 선호도 점수 가져오기 (0.0 ~ 1.0, 높을수록 건강한 요리 선호)
  Future<double> getHealthPreferenceScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyHealthPreference) ?? 0.5; // 기본값: 중립
  }

  /// 개인화된 요리 추천 가중치 계산
  ///
  /// Returns: 각 레시피별 학습 기반 가중치 (높을수록 추천 우선순위 ↑)
  Future<Map<String, double>> getPersonalizedWeights(
    List<String> recipeNames,
  ) async {
    final recipeFreq = await getRecipeFrequency();
    final totalRecipeCount = recipeFreq.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );

    final weights = <String, double>{};

    for (final recipeName in recipeNames) {
      final frequency = recipeFreq[recipeName] ?? 0;

      // 빈도 기반 가중치 (0.0 ~ 1.0)
      final frequencyWeight = totalRecipeCount > 0
          ? (frequency / totalRecipeCount) *
                2.0 // 최대 2배 가중치
          : 0.0;

      weights[recipeName] = 1.0 + frequencyWeight;
    }

    return weights;
  }

  /// 시간대에 맞는 요리 추천 가중치
  Future<Map<String, double>> getMealTimeWeights(
    List<String> recipeNames,
    String mealTime,
  ) async {
    final mealPrefs = await getMealTimePreference();
    final timePrefs = mealPrefs[mealTime] ?? {};
    final totalCount = timePrefs.values.fold(0, (sum, count) => sum + count);

    final weights = <String, double>{};

    for (final recipeName in recipeNames) {
      final frequency = timePrefs[recipeName] ?? 0;

      // 해당 시간대에 자주 먹었던 요리는 가중치 증가
      final timeWeight = totalCount > 0 ? (frequency / totalCount) * 1.5 : 0.0;

      weights[recipeName] = 1.0 + timeWeight;
    }

    return weights;
  }

  /// 학습 데이터 초기화 (설정에서 호출)
  Future<void> resetLearning() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRecipeHistory);
    await prefs.remove(_keyIngredientFrequency);
    await prefs.remove(_keyMealTimePreference);
    await prefs.remove(_keyHealthPreference);
    debugPrint('RecipeLearningService: Learning data reset');
  }

  // Private helper methods

  Future<void> _updateRecipeFrequency(
    SharedPreferences prefs,
    String recipeName,
  ) async {
    final json = prefs.getString(_keyRecipeHistory);
    final Map<String, int> history = json != null
        ? (jsonDecode(json) as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value as int),
          )
        : {};

    history[recipeName] = (history[recipeName] ?? 0) + 1;

    await prefs.setString(_keyRecipeHistory, jsonEncode(history));
  }

  Future<void> _updateIngredientFrequency(
    SharedPreferences prefs,
    List<String> ingredients,
  ) async {
    final json = prefs.getString(_keyIngredientFrequency);
    final Map<String, int> frequency = json != null
        ? (jsonDecode(json) as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, value as int),
          )
        : {};

    for (final ingredient in ingredients) {
      final normalized = ingredient.toLowerCase().trim();
      frequency[normalized] = (frequency[normalized] ?? 0) + 1;
    }

    await prefs.setString(_keyIngredientFrequency, jsonEncode(frequency));
  }

  Future<void> _updateMealTimePreference(
    SharedPreferences prefs,
    String recipeName,
    String mealTime,
  ) async {
    final json = prefs.getString(_keyMealTimePreference);
    final Map<String, Map<String, int>> mealPrefs = json != null
        ? (jsonDecode(json) as Map<String, dynamic>).map(
            (key, value) => MapEntry(
              key,
              (value as Map<String, dynamic>).map(
                (k, v) => MapEntry(k, v as int),
              ),
            ),
          )
        : {};

    if (!mealPrefs.containsKey(mealTime)) {
      mealPrefs[mealTime] = {};
    }

    mealPrefs[mealTime]![recipeName] =
        (mealPrefs[mealTime]![recipeName] ?? 0) + 1;

    await prefs.setString(_keyMealTimePreference, jsonEncode(mealPrefs));
  }

  Future<void> _updateHealthPreference(
    SharedPreferences prefs,
    int healthScore,
  ) async {
    final currentScore = prefs.getDouble(_keyHealthPreference) ?? 0.5;
    final totalRecipes = await _getTotalRecipeCount(prefs);

    // 이동 평균으로 건강 선호도 계산 (healthScore를 0-1로 정규화)
    final normalizedHealth = (healthScore - 1) / 4.0; // 1-5 → 0-1
    final newScore =
        (currentScore * totalRecipes + normalizedHealth) / (totalRecipes + 1);

    await prefs.setDouble(_keyHealthPreference, newScore);
  }

  Future<int> _getTotalRecipeCount(SharedPreferences prefs) async {
    final json = prefs.getString(_keyRecipeHistory);
    if (json == null) return 0;

    final Map<String, dynamic> history = jsonDecode(json);
    return history.values.fold<int>(0, (sum, count) => sum + (count as int));
  }

  /// 학습 통계 요약
  Future<LearningStats> getStats() async {
    final recipeFreq = await getRecipeFrequency();
    final ingredientFreq = await getIngredientFrequency();
    final healthScore = await getHealthPreferenceScore();

    final totalRecipes = recipeFreq.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    final topRecipes =
        (recipeFreq.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(5)
            .map((e) => '${e.key} (${e.value}회)')
            .toList();

    final topIngredients =
        (ingredientFreq.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .take(5)
            .map((e) => '${e.key} (${e.value}회)')
            .toList();

    return LearningStats(
      totalRecipesCooked: totalRecipes,
      topRecipes: topRecipes,
      topIngredients: topIngredients,
      healthPreferenceScore: healthScore,
      healthPreferenceLabel: _getHealthLabel(healthScore),
    );
  }

  String _getHealthLabel(double score) {
    if (score >= 0.7) return '💚 건강식 선호';
    if (score >= 0.5) return '🟡 균형식 선호';
    return '🟠 일반식 선호';
  }
}

/// 학습 통계
class LearningStats {
  final int totalRecipesCooked;
  final List<String> topRecipes;
  final List<String> topIngredients;
  final double healthPreferenceScore;
  final String healthPreferenceLabel;

  LearningStats({
    required this.totalRecipesCooked,
    required this.topRecipes,
    required this.topIngredients,
    required this.healthPreferenceScore,
    required this.healthPreferenceLabel,
  });

  @override
  String toString() {
    return '''
=== 학습 통계 ===
총 요리 횟수: $totalRecipesCooked회
자주 만드는 요리: ${topRecipes.join(', ')}
자주 쓰는 재료: ${topIngredients.join(', ')}
건강 선호도: $healthPreferenceLabel (${(healthPreferenceScore * 100).toStringAsFixed(0)}%)
''';
  }
}
