import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/recipe.dart';

part 'recipe_service_default_recipes_1a.dart';
part 'recipe_service_default_recipes_1b.dart';
part 'recipe_service_default_recipes_2a.dart';
part 'recipe_service_default_recipes_2b.dart';
part 'recipe_service_default_recipes_3a.dart';
part 'recipe_service_default_recipes_3b.dart';
part 'recipe_service_default_recipes_3c.dart';
part 'recipe_service_default_recipes_who.dart';

class RecipeService {
  static final RecipeService instance = RecipeService._();
  RecipeService._();

  final ValueNotifier<List<Recipe>> recipes = ValueNotifier([]);

  /// In-memory search index for fast recipe lookup
  /// Key: normalized search term, Value: matching recipes
  final Map<String, List<Recipe>> _searchIndex = {};

  Future<void> load() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/recipes.json');
      // ignore: avoid_slow_async_io
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        recipes.value = jsonList.map((e) => Recipe.fromJson(e)).toList();
      } else {
        // Seed default recipes if file doesn't exist
        recipes.value = _defaultRecipes;
        await save();
      }
      _buildSearchIndex();
    } catch (e) {
      debugPrint('Failed to load recipes: $e');
      recipes.value = _defaultRecipes;
      _buildSearchIndex();
    }
  }

  Future<void> save() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/recipes.json');
      final jsonList = recipes.value.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Failed to save recipes: $e');
    }
  }

  Future<void> addRecipe(Recipe recipe) async {
    final current = List<Recipe>.from(recipes.value);
    current.add(recipe);
    recipes.value = current;
    await save();
    _buildSearchIndex();
  }

  Future<void> updateRecipe(Recipe recipe) async {
    final current = List<Recipe>.from(recipes.value);
    final index = current.indexWhere((r) => r.id == recipe.id);
    if (index != -1) {
      current[index] = recipe;
      recipes.value = current;
      await save();
      _buildSearchIndex();
    }
  }

  Future<void> deleteRecipe(String id) async {
    final current = List<Recipe>.from(recipes.value);
    current.removeWhere((r) => r.id == id);
    recipes.value = current;
    await save();
    _buildSearchIndex();
  }

  /// Normalize text for search: lowercase, remove extra spaces
  String _normalize(String text) {
    return text.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Build search index for fast lookups
  void _buildSearchIndex() {
    _searchIndex.clear();

    for (final recipe in recipes.value) {
      final terms = <String>{};

      // Add all localized names
      for (final name in recipe.localizedNames.values) {
        terms.add(_normalize(name));
        // Add individual words
        terms.addAll(_normalize(name).split(' '));
      }

      // Add cuisine
      terms.add(_normalize(recipe.cuisine));

      // Add ingredient names
      for (final ing in recipe.ingredients) {
        terms.add(_normalize(ing.name));
        terms.addAll(_normalize(ing.name).split(' '));
      }

      // Add to index
      for (final term in terms) {
        _searchIndex.putIfAbsent(term, () => []).add(recipe);
      }
    }
  }

  /// Fast search using pre-built index
  /// Returns recipes matching all query terms
  List<Recipe> searchRecipes(String query) {
    if (query.trim().isEmpty) return recipes.value;

    final normalizedQuery = _normalize(query);
    final queryTerms = normalizedQuery.split(' ');

    // Get recipes matching each term
    final matchingSets = <Set<String>>[];
    for (final term in queryTerms) {
      final matches = <String>{};
      // Exact match
      if (_searchIndex.containsKey(term)) {
        matches.addAll(_searchIndex[term]!.map((r) => r.id));
      }
      // Prefix match
      for (final key in _searchIndex.keys) {
        if (key.startsWith(term) || key.contains(term)) {
          matches.addAll(_searchIndex[key]!.map((r) => r.id));
        }
      }
      if (matches.isNotEmpty) {
        matchingSets.add(matches);
      }
    }

    if (matchingSets.isEmpty) return [];

    // Intersect all sets (recipes must match all terms)
    var result = matchingSets.first;
    for (var i = 1; i < matchingSets.length; i++) {
      result = result.intersection(matchingSets[i]);
    }

    return recipes.value.where((r) => result.contains(r.id)).toList();
  }

  /// Default recipes: Korean + International + WHO health
  final List<Recipe> _defaultRecipes = [
    ..._defaultRecipesPart1a,
    ..._defaultRecipesPart1b,
    ..._defaultRecipesPart2a,
    ..._defaultRecipesPart2b,
    ..._defaultRecipesPart3a,
    ..._defaultRecipesPart3b,
    ..._defaultRecipesPart3c,
    ..._defaultRecipesWHO,
  ];
}
