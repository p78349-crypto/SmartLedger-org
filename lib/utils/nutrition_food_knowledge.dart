import 'package:flutter/foundation.dart';

part 'nutrition_food_knowledge_meat.dart';
part 'nutrition_food_knowledge_veg.dart';
part 'nutrition_food_knowledge_snack.dart';

@immutable
class FoodPairingSuggestion {
  const FoodPairingSuggestion({required this.ingredient, required this.why});

  final String ingredient;
  final String why;
}

@immutable
class FoodKnowledgeEntry {
  const FoodKnowledgeEntry({
    required this.primaryName,
    required this.keywords,
    required this.dailyIntakeText,
    required this.pairings,
    this.quantitySuggestions = const <String>[],
    this.nutrients,
  });

  final String primaryName;
  final List<String> keywords;

  /// Human-readable, approximate guidance.
  final String dailyIntakeText;

  /// 건강/조리 관점의 "함께 넣으면 좋은 재료" 추천.
  final List<FoodPairingSuggestion> pairings;

  /// 특정 식재료를 선택했을 때 함께 제안할 "재료량(예시)" 목록.
  final List<String> quantitySuggestions;

  /// 영양성분 정보 (선택적)
  final NutritionNutrients? nutrients;
}

@immutable
class NutritionNutrients {
  const NutritionNutrients({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
    required this.sodium,
    required this.servingSize,
    required this.servingSizeUnit,
  });

  final double calories; // kcal
  final double protein; // g
  final double carbs; // g
  final double fat; // g
  final double fiber; // g
  final double sodium; // mg
  final double servingSize;
  final String servingSizeUnit; // "100g", "1개", "1스푼" 등

  String get caloriesText => '${calories.toStringAsFixed(0)} kcal';
  String get proteinText => '${protein.toStringAsFixed(1)}g';
  String get carbsText => '${carbs.toStringAsFixed(1)}g';
  String get fatText => '${fat.toStringAsFixed(1)}g';
  String get fiberText => '${fiber.toStringAsFixed(1)}g';
  String get sodiumText => '${sodium.toStringAsFixed(0)}mg';
}

class NutritionFoodKnowledge {
  NutritionFoodKnowledge._();

  static FoodKnowledgeEntry? lookup(String rawQuery) {
    final q = _normalize(rawQuery);
    if (q.isEmpty) return null;

    FoodKnowledgeEntry? best;
    var bestScore = 0;

    for (final entry in _entries) {
      var score = 0;
      for (final k in entry.keywords) {
        final nk = _normalize(k);
        if (nk.isEmpty) continue;
        if (q == nk) {
          score = 100;
          break;
        }
        if (q.contains(nk) || nk.contains(q)) {
          score = score < 50 ? 50 : score;
        }
      }

      if (score > bestScore) {
        bestScore = score;
        best = entry;
      }
    }

    return bestScore == 0 ? null : best;
  }

  static String _normalize(String s) =>
      s.trim().toLowerCase().replaceAll(' ', '').replaceAll('-', '');

  static List<FoodKnowledgeEntry> get allEntries => _entries;

  static const List<FoodKnowledgeEntry> _entries = <FoodKnowledgeEntry>[
    ..._entriesMeatDairy,
    ..._entriesVegetable,
    ..._entriesSnack,
  ];
}
