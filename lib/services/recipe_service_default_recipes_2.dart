part of 'recipe_service.dart';

/// 기본 레시피 Part 2: 한식 반찬·국·전 (r18–r34)
final List<Recipe> _defaultRecipesPart2 = [
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
];
