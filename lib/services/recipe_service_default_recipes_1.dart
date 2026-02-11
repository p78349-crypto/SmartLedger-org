part of 'recipe_service.dart';

/// 기본 레시피 Part 1: 한식 찌개·볶음·구이 (r1–r17)
final List<Recipe> _defaultRecipesPart1 = [
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
];
