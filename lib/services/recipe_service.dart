import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/recipe.dart';

part 'recipe_service_default_recipes_1.dart';
part 'recipe_service_default_recipes_2.dart';
part 'recipe_service_default_recipes_3.dart';

class RecipeService {
  static final RecipeService instance = RecipeService._();
  RecipeService._();

  final ValueNotifier<List<Recipe>> recipes = ValueNotifier([]);

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
    } catch (e) {
      debugPrint('Failed to load recipes: $e');
      recipes.value = _defaultRecipes;
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
  }

  Future<void> updateRecipe(Recipe recipe) async {
    final current = List<Recipe>.from(recipes.value);
    final index = current.indexWhere((r) => r.id == recipe.id);
    if (index != -1) {
      current[index] = recipe;
      recipes.value = current;
      await save();
    }
  }

  Future<void> deleteRecipe(String id) async {
    final current = List<Recipe>.from(recipes.value);
    current.removeWhere((r) => r.id == id);
    recipes.value = current;
    await save();
  }

  /// Default recipes: Korean + International + WHO health
  final List<Recipe> _defaultRecipes = [
    ..._defaultRecipesPart1,
    ..._defaultRecipesPart2,
    ..._defaultRecipesPart3,
  ];
}
