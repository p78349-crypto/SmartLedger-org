import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/recipe.dart';

void main() {
  group('RecipeIngredient', () {
    test('creates with required fields', () {
      final ingredient = RecipeIngredient(
        name: '당근',
        quantity: 100,
        unit: 'g',
      );

      expect(ingredient.name, '당근');
      expect(ingredient.quantity, 100);
      expect(ingredient.unit, 'g');
    });

    test('toJson serializes correctly', () {
      final ingredient = RecipeIngredient(
        name: '양파',
        quantity: 1.5,
        unit: '개',
      );

      final json = ingredient.toJson();

      expect(json['name'], '양파');
      expect(json['quantity'], 1.5);
      expect(json['unit'], '개');
    });

    test('fromJson parses correctly', () {
      final json = {
        'name': '마늘',
        'quantity': 3.0,
        'unit': '쪽',
      };

      final ingredient = RecipeIngredient.fromJson(json);

      expect(ingredient.name, '마늘');
      expect(ingredient.quantity, 3.0);
      expect(ingredient.unit, '쪽');
    });

    test('fromJson handles int quantity as double', () {
      final json = {
        'name': '감자',
        'quantity': 2, // int
        'unit': '개',
      };

      final ingredient = RecipeIngredient.fromJson(json);

      expect(ingredient.quantity, 2.0);
    });
  });

  group('Recipe', () {
    test('creates with required fields', () {
      final recipe = Recipe(
        id: 'recipe-1',
        name: '김치찌개',
        ingredients: [
          RecipeIngredient(name: '김치', quantity: 200, unit: 'g'),
          RecipeIngredient(name: '두부', quantity: 1, unit: '모'),
        ],
      );

      expect(recipe.id, 'recipe-1');
      expect(recipe.name, '김치찌개');
      expect(recipe.cuisine, '한식'); // 기본값
      expect(recipe.healthScore, 3); // 기본값
      expect(recipe.ingredients.length, 2);
    });

    test('creates with custom cuisine and health score', () {
      final recipe = Recipe(
        id: 'recipe-2',
        name: '스파게티',
        cuisine: '양식',
        ingredients: [
          RecipeIngredient(name: '파스타면', quantity: 100, unit: 'g'),
        ],
        healthScore: 2,
      );

      expect(recipe.cuisine, '양식');
      expect(recipe.healthScore, 2);
    });

    test('toJson serializes correctly', () {
      final recipe = Recipe(
        id: 'recipe-3',
        name: '된장찌개',
        ingredients: [
          RecipeIngredient(name: '된장', quantity: 30, unit: 'g'),
          RecipeIngredient(name: '두부', quantity: 0.5, unit: '모'),
        ],
        healthScore: 4,
      );

      final json = recipe.toJson();

      expect(json['id'], 'recipe-3');
      expect(json['name'], '된장찌개');
      expect(json['cuisine'], '한식');
      expect(json['healthScore'], 4);
      expect(json['ingredients'], isList);
      expect(json['ingredients'].length, 2);
    });

    test('fromJson parses correctly', () {
      final json = {
        'id': 'recipe-4',
        'name': '카레라이스',
        'cuisine': '일식',
        'ingredients': [
          {'name': '카레가루', 'quantity': 50.0, 'unit': 'g'},
          {'name': '감자', 'quantity': 2.0, 'unit': '개'},
        ],
        'healthScore': 3,
      };

      final recipe = Recipe.fromJson(json);

      expect(recipe.id, 'recipe-4');
      expect(recipe.name, '카레라이스');
      expect(recipe.cuisine, '일식');
      expect(recipe.healthScore, 3);
      expect(recipe.ingredients.length, 2);
      expect(recipe.ingredients[0].name, '카레가루');
    });

    test('fromJson uses default values when missing', () {
      final json = {
        'id': 'recipe-5',
        'name': '간단요리',
        'ingredients': <Map<String, dynamic>>[],
      };

      final recipe = Recipe.fromJson(json);

      expect(recipe.cuisine, '기타'); // null일 때 기본값
      expect(recipe.healthScore, 3); // null일 때 기본값
    });

    test('serialization roundtrip preserves data', () {
      final original = Recipe(
        id: 'recipe-6',
        name: '불고기',
        ingredients: [
          RecipeIngredient(name: '소고기', quantity: 300, unit: 'g'),
          RecipeIngredient(name: '배', quantity: 0.5, unit: '개'),
          RecipeIngredient(name: '간장', quantity: 3, unit: 'T'),
        ],
        healthScore: 4,
      );

      final json = original.toJson();
      final restored = Recipe.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.cuisine, original.cuisine);
      expect(restored.healthScore, original.healthScore);
      expect(restored.ingredients.length, original.ingredients.length);
      expect(restored.ingredients[0].name, original.ingredients[0].name);
      expect(restored.ingredients[0].quantity, original.ingredients[0].quantity);
    });
  });
}
