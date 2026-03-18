part of 'nutrition_food_knowledge.dart';

/// 후식/간식 항목.
const List<FoodKnowledgeEntry> _entriesSnack = <FoodKnowledgeEntry>[
  FoodKnowledgeEntry(
    primaryName: '카카오 분말(100% 무가당)',
    keywords: <String>['카카오', '카카오분말', '코코아', 'cocoa powder', '코코아분말'],
    dailyIntakeText:
        '성인(대략): 1~2스푼(약 10~20g)/일 정도를 음료나 요거트에 섞어 섭취하는 경우가 많습니다.\n'
        '무가당 분말 기준으로, 건강한 후식 추가에 활용하기 좋습니다.',
    pairings: <FoodPairingSuggestion>[
      FoodPairingSuggestion(
        ingredient: '우유',
        why: '클래식 조합으로 단백질/칼슘 보충 + 포만감 증가.',
      ),
      FoodPairingSuggestion(
        ingredient: '플레인 요구르트',
        why: '유산균 + 항산화 성분 조합으로 장 건강에 도움.',
      ),
      FoodPairingSuggestion(
        ingredient: '바나나',
        why: '자연스러운 단맛과 칼륨 추가로 포만감/에너지 상승.',
      ),
      FoodPairingSuggestion(
        ingredient: '꿀(소량)',
        why: '단맛 조절용. 과다 사용은 주의(당뇨/다이어트 시).',
      ),
    ],
    quantitySuggestions: <String>[
      '카카오 분말(100%) 1~2스푼',
      '우유 또는 무가당 두유 1잔(200ml)',
      '플레인 요구르트 1컵(150-200g)',
    ],
    nutrients: NutritionNutrients(
      calories: 12,
      protein: 1.0,
      carbs: 3.0,
      fat: 1.0,
      fiber: 0.9,
      sodium: 15,
      servingSize: 1,
      servingSizeUnit: '스푼(약 10g)',
    ),
  ),

  FoodKnowledgeEntry(
    primaryName: '아몬드 분말(100% 무가당)',
    keywords: <String>['아몬드', '아몬드분말', 'almond powder', '아몬드가루'],
    dailyIntakeText:
        '성인(대략): 1~2스푼(약 15~30g)/일 정도를 간식이나 요거트에 섞어 섭취하는 경우가 많습니다.\n'
        '건강한 지방(오메가-3)과 식이섬유가 풍부합니다.',
    pairings: <FoodPairingSuggestion>[
      FoodPairingSuggestion(
        ingredient: '플레인 요구르트',
        why: '추천 조합! 건강한 지방/식이섬유 + 유산균으로 장 건강.',
      ),
      FoodPairingSuggestion(ingredient: '우유', why: '영양 완벽 조합으로 포만감/에너지 상승.'),
      FoodPairingSuggestion(
        ingredient: '베리류(블루베리/딸기)',
        why: '항산화 성분 극대화로 건강한 후식 완성.',
      ),
      FoodPairingSuggestion(ingredient: '꿀(소량)', why: '단맛 조절용으로 후식 완성도 높임.'),
    ],
    quantitySuggestions: <String>[
      '아몬드 분말(100%) 1~2스푼',
      '플레인 요구르트 1컵(150-200g)',
      '우유 1잔(200ml)',
    ],
    nutrients: NutritionNutrients(
      calories: 55,
      protein: 2.0,
      carbs: 2.0,
      fat: 5.0,
      fiber: 1.2,
      sodium: 2,
      servingSize: 1,
      servingSizeUnit: '스푼(약 10g)',
    ),
  ),

  FoodKnowledgeEntry(
    primaryName: '냉동 바나나',
    keywords: <String>['바나나', '냉동바나나', 'banana', 'frozen banana'],
    dailyIntakeText:
        '성인(대략): 중간 크기 1/2~1개/일 정도를 간식이나 후식으로 섭취하는 경우가 많습니다.\n'
        '칼륨이 풍부해 혈압 관리, 근육 회복에 도움이 됩니다.',
    pairings: <FoodPairingSuggestion>[
      FoodPairingSuggestion(
        ingredient: '우유',
        why: '클래식 스무디 조합으로 에너지/트립토판(수면) 증가.',
      ),
      FoodPairingSuggestion(
        ingredient: '플레인 요구르트',
        why: '차갑고 부드러운 아이스크림 같은 식감 + 유산균.',
      ),
      FoodPairingSuggestion(
        ingredient: '카카오 분말(100%)',
        why: '초콜릿 바나나 조합으로 포만감/만족도 극대화.',
      ),
      FoodPairingSuggestion(
        ingredient: '아몬드 분말(100%)',
        why: '건강한 지방 + 과일 조합으로 영양 완벽.',
      ),
    ],
    quantitySuggestions: <String>[
      '냉동 바나나 1/2~1개',
      '우유 또는 두유 1잔(200ml)',
      '플레인 요구르트 1/2컵(100g)',
    ],
    nutrients: NutritionNutrients(
      calories: 53,
      protein: 0.6,
      carbs: 13.0,
      fat: 0.3,
      fiber: 1.5,
      sodium: 1,
      servingSize: 1,
      servingSizeUnit: '개(중간, 약 100g)',
    ),
  ),

  FoodKnowledgeEntry(
    primaryName: '밤(단호박/밤)',
    keywords: <String>['밤', 'chestnut'],
    dailyIntakeText:
        '성인(대략): 중간 크기 5~10개(약 50~100g)/주 정도를 간식이나 반찬으로 섭취하는 경우가 많습니다.\n'
        '포만감이 높고 미네랄(칼륨, 아연)이 풍부합니다.',
    pairings: <FoodPairingSuggestion>[
      FoodPairingSuggestion(ingredient: '우유', why: '밤의 포만감 + 우유의 칼슘으로 완벽한 조합.'),
      FoodPairingSuggestion(
        ingredient: '플레인 요구르트',
        why: '부드러운 식감으로 활용하기 좋은 간식 조합.',
      ),
      FoodPairingSuggestion(ingredient: '꿀(소량)', why: '단맛 조화로 더욱 맛있는 후식 완성.'),
    ],
    quantitySuggestions: <String>[
      '밤 5~10개(약 50-100g)',
      '우유 1잔(200ml)',
      '플레인 요구르트 1컵(150-200g)',
    ],
    nutrients: NutritionNutrients(
      calories: 56,
      protein: 1.1,
      carbs: 12.0,
      fat: 0.5,
      fiber: 2.4,
      sodium: 3,
      servingSize: 1,
      servingSizeUnit: '개(약 10g)',
    ),
  ),
];
