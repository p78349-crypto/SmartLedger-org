import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_ledger/models/recipe.dart';

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

  // Default Korean Recipes
  final List<Recipe> _defaultRecipes = [
    Recipe(
      cuisine: 'Korean',
      id: 'r1',
      name: 'Kimchi Stew (김치찌개)',
      ingredients: [
        RecipeIngredient(name: 'Kimchi', quantity: 0.25, unit: 'head'),
        RecipeIngredient(name: 'Pork', quantity: 200, unit: 'g'),
        RecipeIngredient(name: 'Tofu', quantity: 0.5, unit: 'block'),
        RecipeIngredient(name: 'Green Onion', quantity: 1, unit: 'stalk'),
        RecipeIngredient(name: 'Onion', quantity: 0.5, unit: 'ea'),
      ],
    ),
    Recipe(
      id: 'r2',
      name: 'Soybean Paste Stew (된장찌개)',
      ingredients: [
        RecipeIngredient(name: 'Soybean Paste', quantity: 2, unit: 'tbsp'),
        RecipeIngredient(name: 'Tofu', quantity: 0.5, unit: 'block'),
        RecipeIngredient(name: 'Zucchini', quantity: 0.3, unit: 'ea'),
        RecipeIngredient(name: 'Onion', quantity: 0.5, unit: 'ea'),
        RecipeIngredient(name: 'Potato', quantity: 1, unit: 'ea'),
        RecipeIngredient(name: 'Green Onion', quantity: 0.5, unit: 'stalk'),
      ],
    ),
    Recipe(
      id: 'r3',
      name: 'Stir-fried Pork (제육볶음)',
      ingredients: [
        RecipeIngredient(name: 'Pork', quantity: 400, unit: 'g'),
        RecipeIngredient(name: 'Onion', quantity: 1, unit: 'ea'),
        RecipeIngredient(name: 'Green Onion', quantity: 1, unit: 'stalk'),
        RecipeIngredient(name: 'Carrot', quantity: 0.3, unit: 'ea'),
      ],
    ),
    Recipe(
      id: 'r4',
      name: '계란말이',
      ingredients: [
        RecipeIngredient(name: '계란', quantity: 4, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 0.2, unit: '대'),
        RecipeIngredient(name: '당근', quantity: 0.1, unit: '개'),
      ],
    ),
    Recipe(
      id: 'r5',
      name: '미역국',
      ingredients: [
        RecipeIngredient(name: '미역', quantity: 20, unit: 'g'),
        RecipeIngredient(name: '소고기', quantity: 150, unit: 'g'),
        RecipeIngredient(name: '다진마늘', quantity: 1, unit: '큰술'),
      ],
    ),
    Recipe(
      id: 'r6',
      name: '닭볶음탕',
      ingredients: [
        RecipeIngredient(name: '닭고기', quantity: 1, unit: '마리'),
        RecipeIngredient(name: '감자', quantity: 2, unit: '개'),
        RecipeIngredient(name: '당근', quantity: 0.5, unit: '개'),
        RecipeIngredient(name: '양파', quantity: 1, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 1, unit: '대'),
      ],
    ),
    Recipe(
      id: 'r7',
      name: '삼겹살 구이',
      ingredients: [
        RecipeIngredient(name: '돼지고기', quantity: 600, unit: 'g'),
        RecipeIngredient(name: '마늘', quantity: 10, unit: '쪽'),
        RecipeIngredient(name: '양파', quantity: 1, unit: '개'),
        RecipeIngredient(name: '버섯', quantity: 100, unit: 'g'),
        RecipeIngredient(name: '상추', quantity: 20, unit: '장'),
      ],
    ),
    Recipe(
      id: 'r8',
      name: '수육',
      ingredients: [
        RecipeIngredient(name: '돼지고기', quantity: 600, unit: 'g'),
        RecipeIngredient(name: '양파', quantity: 1, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 2, unit: '대'),
        RecipeIngredient(name: '마늘', quantity: 10, unit: '쪽'),
      ],
    ),
    Recipe(
      id: 'r9',
      name: '닭갈비',
      ingredients: [
        RecipeIngredient(name: '닭고기', quantity: 500, unit: 'g'),
        RecipeIngredient(name: '양배추', quantity: 0.25, unit: '통'),
        RecipeIngredient(name: '고구마', quantity: 1, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 1, unit: '대'),
      ],
    ),
    Recipe(
      id: 'r10',
      name: '카레',
      ingredients: [
        RecipeIngredient(name: '돼지고기', quantity: 200, unit: 'g'),
        RecipeIngredient(name: '감자', quantity: 2, unit: '개'),
        RecipeIngredient(name: '양파', quantity: 2, unit: '개'),
        RecipeIngredient(name: '당근', quantity: 0.5, unit: '개'),
      ],
    ),
    Recipe(
      id: 'r11',
      name: '순두부찌개',
      ingredients: [
        RecipeIngredient(name: '순두부', quantity: 1, unit: '봉'),
        RecipeIngredient(name: '바지락', quantity: 200, unit: 'g'),
        RecipeIngredient(name: '계란', quantity: 1, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 0.5, unit: '대'),
        RecipeIngredient(name: '양파', quantity: 0.5, unit: '개'),
      ],
    ),
    Recipe(
      id: 'r12',
      name: '부대찌개',
      ingredients: [
        RecipeIngredient(name: '햄', quantity: 200, unit: 'g'),
        RecipeIngredient(name: '소시지', quantity: 200, unit: 'g'),
        RecipeIngredient(name: '두부', quantity: 0.5, unit: '모'),
        RecipeIngredient(name: '라면사리', quantity: 1, unit: '개'),
        RecipeIngredient(name: '김치', quantity: 0.2, unit: '포기'),
        RecipeIngredient(name: '대파', quantity: 1, unit: '대'),
      ],
    ),
    Recipe(
      id: 'r13',
      name: '소불고기',
      ingredients: [
        RecipeIngredient(name: '소고기', quantity: 600, unit: 'g'),
        RecipeIngredient(name: '양파', quantity: 1, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 1, unit: '대'),
        RecipeIngredient(name: '당근', quantity: 0.3, unit: '개'),
        RecipeIngredient(name: '버섯', quantity: 100, unit: 'g'),
      ],
    ),
    Recipe(
      id: 'r14',
      name: '갈비찜',
      ingredients: [
        RecipeIngredient(name: '소갈비', quantity: 1, unit: 'kg'),
        RecipeIngredient(name: '무', quantity: 0.3, unit: '개'),
        RecipeIngredient(name: '당근', quantity: 1, unit: '개'),
        RecipeIngredient(name: '밤', quantity: 10, unit: '개'),
        RecipeIngredient(name: '대추', quantity: 10, unit: '개'),
      ],
    ),
    Recipe(
      id: 'r15',
      name: '잡채',
      ingredients: [
        RecipeIngredient(name: '당면', quantity: 250, unit: 'g'),
        RecipeIngredient(name: '시금치', quantity: 0.5, unit: '단'),
        RecipeIngredient(name: '당근', quantity: 0.5, unit: '개'),
        RecipeIngredient(name: '양파', quantity: 1, unit: '개'),
        RecipeIngredient(name: '돼지고기', quantity: 100, unit: 'g'),
        RecipeIngredient(name: '버섯', quantity: 100, unit: 'g'),
      ],
    ),
    Recipe(
      id: 'r16',
      name: '떡볶이',
      ingredients: [
        RecipeIngredient(name: '떡', quantity: 400, unit: 'g'),
        RecipeIngredient(name: '어묵', quantity: 3, unit: '장'),
        RecipeIngredient(name: '대파', quantity: 1, unit: '대'),
        RecipeIngredient(name: '양배추', quantity: 0.1, unit: '통'),
      ],
    ),
    Recipe(
      id: 'r17',
      name: '비빔밥',
      ingredients: [
        RecipeIngredient(name: '콩나물', quantity: 100, unit: 'g'),
        RecipeIngredient(name: '시금치', quantity: 0.3, unit: '단'),
        RecipeIngredient(name: '당근', quantity: 0.3, unit: '개'),
        RecipeIngredient(name: '계란', quantity: 1, unit: '개'),
        RecipeIngredient(name: '소고기', quantity: 50, unit: 'g'),
      ],
    ),
    Recipe(
      id: 'r18',
      name: '김치볶음밥',
      ingredients: [
        RecipeIngredient(name: '김치', quantity: 0.2, unit: '포기'),
        RecipeIngredient(name: '햄', quantity: 100, unit: 'g'),
        RecipeIngredient(name: '대파', quantity: 0.5, unit: '대'),
        RecipeIngredient(name: '계란', quantity: 1, unit: '개'),
      ],
    ),
    Recipe(
      id: 'r19',
      name: '콩나물국',
      ingredients: [
        RecipeIngredient(name: '콩나물', quantity: 300, unit: 'g'),
        RecipeIngredient(name: '대파', quantity: 0.5, unit: '대'),
        RecipeIngredient(name: '다진마늘', quantity: 0.5, unit: '큰술'),
      ],
    ),
    Recipe(
      id: 'r20',
      name: '소고기무국',
      ingredients: [
        RecipeIngredient(name: '소고기', quantity: 200, unit: 'g'),
        RecipeIngredient(name: '무', quantity: 0.3, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 1, unit: '대'),
        RecipeIngredient(name: '다진마늘', quantity: 1, unit: '큰술'),
      ],
    ),
    Recipe(
      id: 'r21',
      name: '시금치나물',
      ingredients: [
        RecipeIngredient(name: '시금치', quantity: 1, unit: '단'),
        RecipeIngredient(name: '다진마늘', quantity: 0.5, unit: '큰술'),
        RecipeIngredient(name: '참기름', quantity: 1, unit: '큰술'),
      ],
    ),
    Recipe(
      id: 'r22',
      name: '콩나물무침',
      ingredients: [
        RecipeIngredient(name: '콩나물', quantity: 1, unit: '봉'),
        RecipeIngredient(name: '대파', quantity: 0.2, unit: '대'),
        RecipeIngredient(name: '다진마늘', quantity: 0.5, unit: '큰술'),
      ],
    ),
    Recipe(
      id: 'r23',
      name: '멸치볶음',
      ingredients: [
        RecipeIngredient(name: '멸치', quantity: 100, unit: 'g'),
        RecipeIngredient(name: '꽈리고추', quantity: 50, unit: 'g'),
        RecipeIngredient(name: '마늘', quantity: 5, unit: '쪽'),
      ],
    ),
    Recipe(
      id: 'r24',
      name: '고등어조림',
      ingredients: [
        RecipeIngredient(name: '고등어', quantity: 1, unit: '마리'),
        RecipeIngredient(name: '무', quantity: 0.3, unit: '개'),
        RecipeIngredient(name: '양파', quantity: 0.5, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 1, unit: '대'),
      ],
    ),
    Recipe(
      id: 'r25',
      name: '오징어볶음',
      ingredients: [
        RecipeIngredient(name: '오징어', quantity: 2, unit: '마리'),
        RecipeIngredient(name: '양파', quantity: 1, unit: '개'),
        RecipeIngredient(name: '당근', quantity: 0.3, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 1, unit: '대'),
        RecipeIngredient(name: '양배추', quantity: 0.1, unit: '통'),
      ],
    ),
    Recipe(
      id: 'r26',
      name: '삼계탕',
      ingredients: [
        RecipeIngredient(name: '닭고기', quantity: 1, unit: '마리'),
        RecipeIngredient(name: '인삼', quantity: 1, unit: '뿌리'),
        RecipeIngredient(name: '대추', quantity: 5, unit: '개'),
        RecipeIngredient(name: '마늘', quantity: 10, unit: '쪽'),
        RecipeIngredient(name: '찹쌀', quantity: 0.5, unit: '컵'),
      ],
    ),
    Recipe(
      id: 'r27',
      name: '칼국수',
      ingredients: [
        RecipeIngredient(name: '칼국수면', quantity: 2, unit: '인분'),
        RecipeIngredient(name: '바지락', quantity: 200, unit: 'g'),
        RecipeIngredient(name: '애호박', quantity: 0.3, unit: '개'),
        RecipeIngredient(name: '감자', quantity: 1, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 0.5, unit: '대'),
      ],
    ),
    Recipe(
      id: 'r28',
      name: '만두국',
      ingredients: [
        RecipeIngredient(name: '만두', quantity: 10, unit: '개'),
        RecipeIngredient(name: '계란', quantity: 1, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 0.5, unit: '대'),
        RecipeIngredient(name: '김', quantity: 1, unit: '장'),
      ],
    ),
    Recipe(
      id: 'r29',
      name: '육개장',
      ingredients: [
        RecipeIngredient(name: '소고기', quantity: 300, unit: 'g'),
        RecipeIngredient(name: '고사리', quantity: 100, unit: 'g'),
        RecipeIngredient(name: '숙주', quantity: 200, unit: 'g'),
        RecipeIngredient(name: '대파', quantity: 3, unit: '대'),
        RecipeIngredient(name: '무', quantity: 0.2, unit: '개'),
      ],
    ),
    Recipe(
      id: 'r30',
      name: '감자채볶음',
      ingredients: [
        RecipeIngredient(name: '감자', quantity: 2, unit: '개'),
        RecipeIngredient(name: '양파', quantity: 0.5, unit: '개'),
        RecipeIngredient(name: '당근', quantity: 0.2, unit: '개'),
      ],
    ),
    Recipe(
      id: 'r31',
      name: '호박전',
      ingredients: [
        RecipeIngredient(name: '애호박', quantity: 1, unit: '개'),
        RecipeIngredient(name: '계란', quantity: 2, unit: '개'),
        RecipeIngredient(name: '밀가루', quantity: 0.5, unit: '컵'),
      ],
    ),
    Recipe(
      id: 'r32',
      name: '김치전',
      ingredients: [
        RecipeIngredient(name: '김치', quantity: 0.2, unit: '포기'),
        RecipeIngredient(name: '부침가루', quantity: 1, unit: '컵'),
        RecipeIngredient(name: '양파', quantity: 0.5, unit: '개'),
        RecipeIngredient(name: '오징어', quantity: 0.5, unit: '마리'),
      ],
    ),
    Recipe(
      id: 'r33',
      name: '해물파전',
      ingredients: [
        RecipeIngredient(name: '쪽파', quantity: 1, unit: '단'),
        RecipeIngredient(name: '오징어', quantity: 1, unit: '마리'),
        RecipeIngredient(name: '새우', quantity: 100, unit: 'g'),
        RecipeIngredient(name: '부침가루', quantity: 2, unit: '컵'),
        RecipeIngredient(name: '계란', quantity: 2, unit: '개'),
      ],
    ),
    Recipe(
      id: 'r34',
      name: '계란말이',
      ingredients: [
        RecipeIngredient(name: '계란', quantity: 5, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 0.2, unit: '대'),
        RecipeIngredient(name: '당근', quantity: 0.1, unit: '개'),
      ],
    ),
    Recipe(
      id: 'r35',
      name: '계란찜',
      ingredients: [
        RecipeIngredient(name: '계란', quantity: 3, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 0.1, unit: '대'),
        RecipeIngredient(name: '새우젓', quantity: 0.5, unit: '큰술'),
      ],
    ),
    Recipe(
      id: 'r36',
      name: '두부조림',
      ingredients: [
        RecipeIngredient(name: '두부', quantity: 1, unit: '모'),
        RecipeIngredient(name: '양파', quantity: 0.5, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 0.5, unit: '대'),
        RecipeIngredient(name: '고춧가루', quantity: 1, unit: '큰술'),
      ],
    ),
    Recipe(
      id: 'r37',
      name: '어묵볶음',
      ingredients: [
        RecipeIngredient(name: '어묵', quantity: 4, unit: '장'),
        RecipeIngredient(name: '양파', quantity: 0.5, unit: '개'),
        RecipeIngredient(name: '당근', quantity: 0.2, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 0.5, unit: '대'),
      ],
    ),
    Recipe(
      id: 'r38',
      name: '진미채볶음',
      ingredients: [
        RecipeIngredient(name: '진미채', quantity: 200, unit: 'g'),
        RecipeIngredient(name: '고추장', quantity: 2, unit: '큰술'),
        RecipeIngredient(name: '마요네즈', quantity: 1, unit: '큰술'),
      ],
    ),
    Recipe(
      id: 'r39',
      name: '오이무침',
      ingredients: [
        RecipeIngredient(name: '오이', quantity: 2, unit: '개'),
        RecipeIngredient(name: '양파', quantity: 0.5, unit: '개'),
        RecipeIngredient(name: '고춧가루', quantity: 2, unit: '큰술'),
      ],
    ),
    Recipe(
      id: 'r40',
      name: '가지볶음',
      ingredients: [
        RecipeIngredient(name: '가지', quantity: 2, unit: '개'),
        RecipeIngredient(name: '양파', quantity: 0.5, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 0.5, unit: '대'),
        RecipeIngredient(name: '굴소스', quantity: 1, unit: '큰술'),
      ],
    ),
    Recipe(
      id: 'r41',
      name: '닭볶음탕',
      ingredients: [
        RecipeIngredient(name: '닭고기', quantity: 1, unit: '마리'),
        RecipeIngredient(name: '감자', quantity: 2, unit: '개'),
        RecipeIngredient(name: '당근', quantity: 0.5, unit: '개'),
        RecipeIngredient(name: '양파', quantity: 1, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 2, unit: '대'),
      ],
    ),
    Recipe(
      id: 'r42',
      name: '찜닭',
      ingredients: [
        RecipeIngredient(name: '닭고기', quantity: 1, unit: '마리'),
        RecipeIngredient(name: '당면', quantity: 100, unit: 'g'),
        RecipeIngredient(name: '감자', quantity: 2, unit: '개'),
        RecipeIngredient(name: '당근', quantity: 0.5, unit: '개'),
        RecipeIngredient(name: '양파', quantity: 1, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 1, unit: '대'),
      ],
    ),
    Recipe(
      id: 'r43',
      name: '동태찌개',
      ingredients: [
        RecipeIngredient(name: '동태', quantity: 1, unit: '마리'),
        RecipeIngredient(name: '무', quantity: 0.3, unit: '개'),
        RecipeIngredient(name: '두부', quantity: 0.5, unit: '모'),
        RecipeIngredient(name: '대파', quantity: 1, unit: '대'),
        RecipeIngredient(name: '쑥갓', quantity: 50, unit: 'g'),
      ],
    ),
    Recipe(
      id: 'r44',
      name: '알탕',
      ingredients: [
        RecipeIngredient(name: '명란', quantity: 200, unit: 'g'),
        RecipeIngredient(name: '곤이', quantity: 100, unit: 'g'),
        RecipeIngredient(name: '무', quantity: 0.2, unit: '개'),
        RecipeIngredient(name: '콩나물', quantity: 100, unit: 'g'),
        RecipeIngredient(name: '대파', quantity: 1, unit: '대'),
      ],
    ),
    Recipe(
      id: 'r45',
      name: '미역국',
      ingredients: [
        RecipeIngredient(name: '미역', quantity: 20, unit: 'g'),
        RecipeIngredient(name: '소고기', quantity: 100, unit: 'g'),
        RecipeIngredient(name: '다진마늘', quantity: 1, unit: '큰술'),
        RecipeIngredient(name: '참기름', quantity: 1, unit: '큰술'),
      ],
    ),
    Recipe(
      id: 'r46',
      name: '북엇국',
      ingredients: [
        RecipeIngredient(name: '북어채', quantity: 50, unit: 'g'),
        RecipeIngredient(name: '무', quantity: 0.2, unit: '개'),
        RecipeIngredient(name: '계란', quantity: 1, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 0.5, unit: '대'),
        RecipeIngredient(name: '참기름', quantity: 1, unit: '큰술'),
      ],
    ),
    Recipe(
      id: 'r47',
      name: '떡국',
      ingredients: [
        RecipeIngredient(name: '떡국떡', quantity: 400, unit: 'g'),
        RecipeIngredient(name: '소고기', quantity: 100, unit: 'g'),
        RecipeIngredient(name: '계란', quantity: 1, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 0.5, unit: '대'),
        RecipeIngredient(name: '김', quantity: 1, unit: '장'),
      ],
    ),
    Recipe(
      id: 'r48',
      name: '수제비',
      ingredients: [
        RecipeIngredient(name: '밀가루', quantity: 2, unit: '컵'),
        RecipeIngredient(name: '감자', quantity: 1, unit: '개'),
        RecipeIngredient(name: '애호박', quantity: 0.3, unit: '개'),
        RecipeIngredient(name: '대파', quantity: 0.5, unit: '대'),
        RecipeIngredient(name: '바지락', quantity: 100, unit: 'g'),
      ],
    ),
    Recipe(
      id: 'r49',
      name: '쫄면',
      ingredients: [
        RecipeIngredient(name: '쫄면', quantity: 200, unit: 'g'),
        RecipeIngredient(name: '콩나물', quantity: 100, unit: 'g'),
        RecipeIngredient(name: '양배추', quantity: 50, unit: 'g'),
        RecipeIngredient(name: '오이', quantity: 0.3, unit: '개'),
        RecipeIngredient(name: '계란', quantity: 0.5, unit: '개'),
      ],
    ),
    Recipe(
      id: 'r50',
      name: '잔치국수',
      ingredients: [
        RecipeIngredient(name: '소면', quantity: 200, unit: 'g'),
        RecipeIngredient(name: '애호박', quantity: 0.2, unit: '개'),
        RecipeIngredient(name: '당근', quantity: 0.1, unit: '개'),
        RecipeIngredient(name: '계란', quantity: 1, unit: '개'),
        RecipeIngredient(name: '김치', quantity: 50, unit: 'g'),
      ],
    ),
    // International Recipes
    Recipe(
      id: 'r51',
      name: 'Steak (스테이크)',
      cuisine: 'Western',
      ingredients: [
        RecipeIngredient(name: 'Beef', quantity: 300, unit: 'g'),
        RecipeIngredient(name: 'Asparagus', quantity: 3, unit: 'ea'),
        RecipeIngredient(name: 'Garlic', quantity: 5, unit: 'clove'),
        RecipeIngredient(name: 'Butter', quantity: 20, unit: 'g'),
      ],
    ),
    Recipe(
      id: 'r52',
      name: 'Pasta (파스타)',
      cuisine: 'Western',
      ingredients: [
        RecipeIngredient(name: 'Pasta', quantity: 100, unit: 'g'),
        RecipeIngredient(name: 'Garlic', quantity: 5, unit: 'clove'),
        RecipeIngredient(name: 'Olive Oil', quantity: 3, unit: 'tbsp'),
        RecipeIngredient(name: 'Peperoncino', quantity: 3, unit: 'ea'),
      ],
    ),
    Recipe(
      id: 'r53',
      name: 'Udon (우동)',
      cuisine: 'Japanese',
      ingredients: [
        RecipeIngredient(name: 'Udon Noodles', quantity: 1, unit: 'ea'),
        RecipeIngredient(name: 'Fish Cake', quantity: 1, unit: 'sheet'),
        RecipeIngredient(name: 'Green Onion', quantity: 0.5, unit: 'stalk'),
        RecipeIngredient(name: 'Crown Daisy', quantity: 20, unit: 'g'),
      ],
    ),
    Recipe(
      id: 'r54',
      name: 'Mapo Tofu (마파두부)',
      cuisine: 'Chinese',
      ingredients: [
        RecipeIngredient(name: 'Tofu', quantity: 1, unit: 'block'),
        RecipeIngredient(name: 'Pork', quantity: 100, unit: 'g'),
        RecipeIngredient(name: 'Green Onion', quantity: 0.5, unit: 'stalk'),
        RecipeIngredient(name: 'Doubanjiang', quantity: 2, unit: 'tbsp'),
      ],
    ),
  ];
}

