import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import '../utils/nutrition_food_knowledge.dart';
// Reuse data models if possible or redefine
import '../models/food_expiry_item.dart';

/// Service to handle Recipe/Food Knowledge from JSON data.
/// Replaces the hardcoded [NutritionFoodKnowledge].
class RecipeKnowledgeService {
  RecipeKnowledgeService._();
  static final RecipeKnowledgeService instance = RecipeKnowledgeService._();

  List<FoodKnowledgeEntry> _entries = [];
  bool _isLoaded = false;

  /// Suggests main ingredients to buy/add when the current inventory lacks a
  /// clear main ingredient.
  ///
  /// Scoring is based on how many pairing ingredients match the current stock.
  /// Entries whose main ingredient is already present are excluded.
  List<MissingMainIngredientSuggestion> suggestMissingMainIngredients(
    List<FoodExpiryItem> inventory, {
    int limit = 3,
  }) {
    if (!_isLoaded || limit <= 0) return const <MissingMainIngredientSuggestion>[];

    final inventoryNames = inventory.map((e) => _normalize(e.name)).toSet();
    if (inventoryNames.isEmpty) return const <MissingMainIngredientSuggestion>[];

    bool hasMainIngredient(FoodKnowledgeEntry entry) {
      for (final k in entry.keywords) {
        final nk = _normalize(k);
        if (nk.isEmpty) continue;
        if (inventoryNames.any((inv) => inv.contains(nk) || nk.contains(inv))) {
          return true;
        }
      }
      return false;
    }

    final candidates = <MissingMainIngredientSuggestion>[];
    for (final entry in _entries) {
      if (entry.keywords.isEmpty) continue;
      if (hasMainIngredient(entry)) continue;

      final matched = <String>[];
      var score = 0;

      for (final p in entry.pairings) {
        final tokens = _tokenizePairingIngredient(p.ingredient);
        var matchedThisPairing = false;
        for (final t in tokens) {
          final nt = _normalize(t);
          if (nt.isEmpty) continue;
          if (inventoryNames.any((inv) => inv.contains(nt) || nt.contains(inv))) {
            matchedThisPairing = true;
            break;
          }
        }
        if (matchedThisPairing) {
          score += 1;
          final label = p.ingredient.trim();
          if (label.isNotEmpty && !matched.contains(label)) {
            matched.add(label);
          }
        }
      }

      if (score <= 0) continue;

      // Mild preference for common "main" ingredients.
      final primary = entry.primaryName;
      final primaryN = _normalize(primary);
      final preferred = <String>{
        _normalize('달걀'),
        _normalize('계란'),
        _normalize('닭고기'),
        _normalize('돼지고기'),
        _normalize('소고기'),
        _normalize('두부'),
      };
      final bonus = preferred.any((p) => p.isNotEmpty && primaryN.contains(p))
          ? 0.5
          : 0.0;

      candidates.add(
        MissingMainIngredientSuggestion(
          primaryName: primary,
          score: score + bonus,
          matchedPairings: matched,
        ),
      );
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    if (candidates.length <= limit) return candidates;
    return candidates.take(limit).toList();
  }

  /// Loads the food knowledge data from JSON asset.
  Future<void> loadData() async {
    if (_isLoaded) return;
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/food_knowledge.json',
      );
      final List<dynamic> jsonList = jsonDecode(jsonString);

      _entries = jsonList.map((json) {
        return FoodKnowledgeEntry(
          primaryName: json['primaryName'] ?? '',
          keywords: List<String>.from(json['keywords'] ?? []),
          dailyIntakeText: json['dailyIntakeText'] ?? '',
          pairings:
              (json['pairings'] as List<dynamic>?)?.map((p) {
                return FoodPairingSuggestion(
                  ingredient: p['ingredient'] ?? '',
                  why: p['why'] ?? '',
                );
              }).toList() ??
              [],
          quantitySuggestions: List<String>.from(
            json['quantitySuggestions'] ?? [],
          ),
        );
      }).toList();

      _isLoaded = true;
      debugPrint('RecipeKnowledgeService: Loaded ${_entries.length} entries.');
    } catch (e) {
      debugPrint('RecipeKnowledgeService: Error loading data - $e');
    }
  }

  /// Search for a specific ingredient/recipe entry.
  FoodKnowledgeEntry? lookup(String query) {
    if (!_isLoaded || query.isEmpty) return null;
    final q = _normalize(query);

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

  /// Finds recipes where the primary ingredient matches items in the inventory.
  /// Returns a list of recipes (entries) that can be made with current stock.
  List<FoodKnowledgeEntry> findRecipesByInventory(
    List<FoodExpiryItem> inventory,
  ) {
    if (!_isLoaded) return [];

    final matches = <FoodKnowledgeEntry>[];
    final inventoryNames = inventory.map((e) => _normalize(e.name)).toSet();

    for (final entry in _entries) {
      // Check if we have the "Main Ingredient" for this entry
      // e.g. Entry is "Chicken", check if we have "chicken" in inventory
      bool hasMainIngredient = false;
      for (final k in entry.keywords) {
        final nk = _normalize(k);
        // Simple containment check
        if (inventoryNames.any((inv) => inv.contains(nk) || nk.contains(inv))) {
          hasMainIngredient = true;
          break;
        }
      }

      if (hasMainIngredient) {
        matches.add(entry);
      }
    }
    return matches;
  }

  static String _normalize(String s) =>
      s.trim().toLowerCase().replaceAll(' ', '').replaceAll('-', '');

  static List<String> _tokenizePairingIngredient(String raw) {
    final s = raw
        .replaceAll('(', ' ')
        .replaceAll(')', ' ')
        .replaceAll('[', ' ')
        .replaceAll(']', ' ')
        .trim();
    if (s.isEmpty) return const <String>[];

    return s
        .split(RegExp(r'[/,·]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

class MissingMainIngredientSuggestion {
  final String primaryName;
  final double score;
  final List<String> matchedPairings;

  const MissingMainIngredientSuggestion({
    required this.primaryName,
    required this.score,
    required this.matchedPairings,
  });
}
