part of 'nutrition_food_knowledge.dart';

/// 채소류 항목.
const List<FoodKnowledgeEntry> _entriesVegetable = <FoodKnowledgeEntry>[
  FoodKnowledgeEntry(
    primaryName: '브로콜리',
    keywords: <String>['브로콜리', 'broccoli'],
    dailyIntakeText:
        '성인(대략): 익힌 브로콜리 1~2컵(대략 150~300g)/일 범위로 곁들이는 경우가 흔합니다.',
    pairings: <FoodPairingSuggestion>[
      FoodPairingSuggestion(
        ingredient: '닭고기/두부',
        why: '단백질 + 채소 조합으로 한 끼 구성이 쉬움.',
      ),
      FoodPairingSuggestion(
        ingredient: '올리브오일(소량)',
        why: '소량의 지방은 식감/만족도에 도움(과다 사용은 주의).',
      ),
      FoodPairingSuggestion(
        ingredient: '마늘',
        why: '향미를 올려 간을 과하게 하지 않게 도움.',
      ),
    ],
  ),

  FoodKnowledgeEntry(
    primaryName: '버섯(일반)',
    keywords: <String>['버섯', '표고버섯', '느타리', '팽이', 'mushroom'],
    dailyIntakeText:
        '성인(대략): 익힌 버섯 1~2컵(대략 100~200g)/일 정도를 반찬/국/볶음에 곁들이는 경우가 많습니다.',
    pairings: <FoodPairingSuggestion>[
      FoodPairingSuggestion(
        ingredient: '두부',
        why: '담백한 단백질과 잘 어울려 한 끼 구성이 쉬움.',
      ),
      FoodPairingSuggestion(ingredient: '달걀', why: '간단한 단백질 보강 조합.'),
      FoodPairingSuggestion(ingredient: '양파', why: '향미를 올려 간단 조리에 도움.'),
    ],
  ),

  FoodKnowledgeEntry(
    primaryName: '토마토',
    keywords: <String>['토마토', 'tomato'],
    dailyIntakeText:
        '성인(대략): 중간 크기 1~2개/일 또는 샐러드 한 접시 정도로 섭취하는 경우가 흔합니다.',
    pairings: <FoodPairingSuggestion>[
      FoodPairingSuggestion(
        ingredient: '달걀',
        why: '간단하고 균형 잡힌 조합으로 활용이 쉬움.',
      ),
      FoodPairingSuggestion(
        ingredient: '올리브오일(소량)',
        why: '소량의 지방은 맛/만족도를 올리기 쉬움(과다 사용은 주의).',
      ),
      FoodPairingSuggestion(
        ingredient: '양파/바질',
        why: '향미로 소금/설탕이 많은 소스 의존을 줄이기 쉬움.',
      ),
    ],
  ),

  FoodKnowledgeEntry(
    primaryName: '시금치/잎채소',
    keywords: <String>['시금치', '잎채소', 'spinach'],
    dailyIntakeText:
        '성인(대략): 익힌 잎채소 1~2컵/일 정도를 반찬/국에 곁들이는 경우가 많습니다.',
    pairings: <FoodPairingSuggestion>[
      FoodPairingSuggestion(
        ingredient: '달걀',
        why: '단백질 + 채소로 간단한 한 끼 구성이 쉬움.',
      ),
      FoodPairingSuggestion(ingredient: '마늘', why: '향미로 간단 조리에 도움.'),
      FoodPairingSuggestion(ingredient: '두부', why: '담백한 단백질과 잘 어울림.'),
    ],
  ),

  // 주요 채소류 섹션
  FoodKnowledgeEntry(
    primaryName: '양파',
    keywords: <String>['양파', 'onion'],
    dailyIntakeText:
        '성인(대략): 중간 크기 1/2~1개/일 정도를 요리에 넣어 섭취하는 경우가 많습니다.\n'
        '황 화합물(알리신 등)이 풍부해 항산화 효과가 좋습니다.',
    pairings: <FoodPairingSuggestion>[
      FoodPairingSuggestion(
        ingredient: '닭고기/돼지고기',
        why: '향미를 올려 기름/양념을 줄이기 쉬움.',
      ),
      FoodPairingSuggestion(
        ingredient: '당근',
        why: '볶음밥/스프 베이스로 채소 섭취량 증가.',
      ),
      FoodPairingSuggestion(
        ingredient: '버섯류',
        why: '감칠맛 극대화로 염분 사용 감소.',
      ),
      FoodPairingSuggestion(
        ingredient: '마늘',
        why: '양파+마늘 조합은 모든 요리의 기본 향신료.',
      ),
    ],
    quantitySuggestions: <String>['양파 1~2개', '마늘 3~5쪽', '당근 1개'],
    nutrients: NutritionNutrients(
      calories: 40,
      protein: 1.1,
      carbs: 9.3,
      fat: 0.1,
      fiber: 1.7,
      sodium: 4,
      servingSize: 1,
      servingSizeUnit: '개(중간, 약 100g)',
    ),
  ),

  FoodKnowledgeEntry(
    primaryName: '당근',
    keywords: <String>['당근', 'carrot'],
    dailyIntakeText:
        '성인(대략): 중간 크기 1개/일 정도를 요리나 간식으로 섭취하는 경우가 많습니다.\n'
        '베타카로틴(비타민A 전구체)이 풍부해 눈 건강에 좋습니다.',
    pairings: <FoodPairingSuggestion>[
      FoodPairingSuggestion(
        ingredient: '양파',
        why: '볶음/카레/스프 기본 조합으로 활용 쉬움.',
      ),
      FoodPairingSuggestion(
        ingredient: '브로콜리',
        why: '색상 조합이 좋고 영양 균형 극대화.',
      ),
      FoodPairingSuggestion(
        ingredient: '닭고기/돼지고기',
        why: '단백질 + 채소로 균형 잡힌 한 끼 구성.',
      ),
    ],
    quantitySuggestions: <String>['당근 2~3개', '양파 1~2개', '브로콜리 1개'],
    nutrients: NutritionNutrients(
      calories: 41,
      protein: 0.9,
      carbs: 9.6,
      fat: 0.2,
      fiber: 2.8,
      sodium: 69,
      servingSize: 1,
      servingSizeUnit: '개(중간, 약 100g)',
    ),
  ),

  FoodKnowledgeEntry(
    primaryName: '가지',
    keywords: <String>['가지', 'eggplant'],
    dailyIntakeText:
        '성인(대략): 중간 크기 1개/일 정도를 볶음/찜에 활용하는 경우가 많습니다.\n'
        '식이섬유가 풍부하고 칼로리가 낮아 다이어트에 좋습니다.',
    pairings: <FoodPairingSuggestion>[
      FoodPairingSuggestion(
        ingredient: '된장',
        why: '가지 된장찜/구이는 한국 전통 요리로 영양 만점.',
      ),
      FoodPairingSuggestion(
        ingredient: '돼지고기',
        why: '돼지고기+가지 볶음은 포만감 높은 조합.',
      ),
      FoodPairingSuggestion(
        ingredient: '마늘/생강',
        why: '향신료로 가지의 식감을 부드럽게.',
      ),
    ],
    quantitySuggestions: <String>['가지 1~2개', '된장 1큰술', '마늘 2~3쪽'],
    nutrients: NutritionNutrients(
      calories: 25,
      protein: 1.0,
      carbs: 5.9,
      fat: 0.2,
      fiber: 3.0,
      sodium: 2,
      servingSize: 1,
      servingSizeUnit: '개(중간, 약 100g)',
    ),
  ),

  FoodKnowledgeEntry(
    primaryName: '양배추',
    keywords: <String>['양배추', 'cabbage'],
    dailyIntakeText:
        '성인(대략): 100~200g/일 정도를 샐러드/볶음/쌈으로 섭취하는 경우가 많습니다.\n'
        '비타민C와 식이섬유가 풍부해 장 건강에 도움이 됩니다.',
    pairings: <FoodPairingSuggestion>[
      FoodPairingSuggestion(
        ingredient: '돼지고기',
        why: '쌈 채소로 완벽한 조합. 포만감 증가.',
      ),
      FoodPairingSuggestion(
        ingredient: '당근/양파',
        why: '볶음 요리 기본 채소 조합으로 활용 쉬움.',
      ),
      FoodPairingSuggestion(
        ingredient: '된장/고추장',
        why: '한국식 찌개에 넣으면 단맛과 식감 보완.',
      ),
    ],
    quantitySuggestions: <String>[
      '양배추 1/4통(약 100-150g)',
      '돼지고기(살코기) 100g',
      '당근 1개',
    ],
    nutrients: NutritionNutrients(
      calories: 25,
      protein: 1.3,
      carbs: 5.8,
      fat: 0.1,
      fiber: 2.5,
      sodium: 18,
      servingSize: 100,
      servingSizeUnit: 'g',
    ),
  ),
];
