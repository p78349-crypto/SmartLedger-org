import 'package:flutter/foundation.dart';

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

  /// 건강/조리 관점의 “함께 넣으면 좋은 재료” 추천.
  final List<FoodPairingSuggestion> pairings;

  /// 특정 식재료를 선택했을 때 함께 제안할 “재료량(예시)” 목록.
  ///
  /// - 앱 내에서 간단히 보여주는 참고용입니다.
  /// - 인원/레시피/취향에 따라 달라질 수 있습니다.
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
    FoodKnowledgeEntry(
      primaryName: '닭고기(살코기)',
      keywords: <String>['닭고기', '닭', '치킨', '닭가슴살', 'chicken', 'chickenbreast'],
      dailyIntakeText:
          '성인(대략): 조리된 살코기 100~150g/일 정도를 한 끼 단백질로 활용하는 경우가 많습니다.\n'
          '개인(체중/활동량/질환)에 따라 적정량은 달라질 수 있어요.',
      pairings: <FoodPairingSuggestion>[
        FoodPairingSuggestion(
          ingredient: '브로콜리',
          why: '식이섬유·비타민이 더해져 포만감과 균형에 도움.',
        ),
        FoodPairingSuggestion(
          ingredient: '버섯(표고/느타리/팽이)',
          why: '감칠맛으로 염분/소스 사용을 줄이기 쉬움.',
        ),
        FoodPairingSuggestion(
          ingredient: '양파/마늘',
          why: '향미를 올려 기름/당이 많은 양념 의존을 줄이기 쉬움.',
        ),
        FoodPairingSuggestion(
          ingredient: '파프리카/토마토',
          why: '채소 비중을 늘려 식사 균형에 도움.',
        ),
        FoodPairingSuggestion(
          ingredient: '현미/귀리(또는 잡곡밥)',
          why: '단백질 + 복합탄수 조합으로 포만감 유지에 도움.',
        ),
      ],
      quantitySuggestions: <String>[
        '닭고기(적은 것) 1마리',
        '양파 1개',
        '당근 2개',
        '호박 1/2개',
        '가지 1개',
        '양배추 100g',
        '표고버섯(큰 것) 3개',
        '팽이(적은 것) 1봉지',
        '된장 조금',
        '고추장 조금',
      ],
    ),
    FoodKnowledgeEntry(
      primaryName: '달걀',
      keywords: <String>['계란', '달걀', 'egg', 'eggs'],
      dailyIntakeText:
          '성인(대략): 1~2개/일 범위로 섭취하는 경우가 흔합니다.\n'
          '개인 건강상태(혈중지질 등)에 따라 조절이 필요할 수 있어요.',
      pairings: <FoodPairingSuggestion>[
        FoodPairingSuggestion(
          ingredient: '시금치/부추',
          why: '채소를 곁들이면 한 끼 구성이 더 균형적이기 쉬움.',
        ),
        FoodPairingSuggestion(
          ingredient: '토마토',
          why: '산미/수분으로 느끼함을 줄이고 채소 섭취를 늘리기 쉬움.',
        ),
        FoodPairingSuggestion(
          ingredient: '김/미역',
          why: '요오드/미네랄 공급원으로 곁들이기 쉬움(과다 섭취는 주의).',
        ),
      ],
    ),
    FoodKnowledgeEntry(
      primaryName: '두부',
      keywords: <String>['두부', 'tofu'],
      dailyIntakeText: '성인(대략): 1/2~1모(약 150~300g)/일 범위로 나눠 먹는 경우가 흔합니다.',
      pairings: <FoodPairingSuggestion>[
        FoodPairingSuggestion(
          ingredient: '김치/파/마늘',
          why: '담백한 맛을 보완해 조리 만족도를 올리기 쉬움(염분은 주의).',
        ),
        FoodPairingSuggestion(ingredient: '버섯', why: '식이섬유·감칠맛으로 포만감에 도움.'),
        FoodPairingSuggestion(
          ingredient: '현미/잡곡',
          why: '식물성 단백질과 곡류 조합으로 한 끼 구성이 쉬움.',
        ),
      ],
    ),

    FoodKnowledgeEntry(
      primaryName: '연어(등푸른 생선)',
      keywords: <String>['연어', 'salmon'],
      dailyIntakeText: '성인(대략): 조리된 생선 100~150g/회, 주 1~3회 정도로 섭취하는 경우가 많습니다.',
      pairings: <FoodPairingSuggestion>[
        FoodPairingSuggestion(
          ingredient: '레몬/식초(산미)',
          why: '산미로 풍미를 올려 소금/설탕이 많은 소스 의존을 줄이기 쉬움.',
        ),
        FoodPairingSuggestion(
          ingredient: '브로콜리/시금치',
          why: '채소 곁들이면 한 끼 균형과 포만감에 도움.',
        ),
        FoodPairingSuggestion(
          ingredient: '버섯',
          why: '감칠맛을 더해 간을 과하게 하지 않게 도움.',
        ),
      ],
      quantitySuggestions: <String>[
        '연어 1토막(약 120~150g)',
        '브로콜리 1컵(또는 한 줌)',
        '양파 1/2개',
        '버섯 1줌',
        '레몬(또는 식초) 조금',
        '올리브오일 소량',
        '소금/후추 아주 조금',
      ],
    ),

    FoodKnowledgeEntry(
      primaryName: '소고기(살코기)',
      keywords: <String>['소고기', '소', 'beef'],
      dailyIntakeText: '성인(대략): 조리된 살코기 80~120g/회 정도를 한 끼 단백질로 활용하는 경우가 많습니다.',
      pairings: <FoodPairingSuggestion>[
        FoodPairingSuggestion(
          ingredient: '버섯',
          why: '감칠맛을 올려 기름진 부위/양념 의존을 줄이기 쉬움.',
        ),
        FoodPairingSuggestion(
          ingredient: '양파/파',
          why: '향미로 만족도를 올리면서 간을 과하게 하지 않게 도움.',
        ),
        FoodPairingSuggestion(
          ingredient: '상추/깻잎(쌈채소)',
          why: '채소 섭취를 늘리고 한입 구성에 도움.',
        ),
      ],
      quantitySuggestions: <String>[
        '소고기(살코기) 120g',
        '양파 1/2개',
        '버섯 1줌',
        '파 1/2대',
        '마늘 1~2쪽',
        '쌈채소 한 줌(선택)',
        '간장/된장 아주 조금(선택)',
      ],
    ),

    FoodKnowledgeEntry(
      primaryName: '돼지고기(살코기)',
      keywords: <String>['돼지고기', '돼지', 'pork'],
      dailyIntakeText: '성인(대략): 조리된 살코기 80~120g/회 정도를 한 끼 단백질로 활용하는 경우가 많습니다.',
      pairings: <FoodPairingSuggestion>[
        FoodPairingSuggestion(
          ingredient: '양배추/상추(쌈)',
          why: '채소를 늘려 포만감과 균형에 도움.',
        ),
        FoodPairingSuggestion(
          ingredient: '마늘/생강',
          why: '향미로 기름진 느낌을 줄이고 과한 소스 사용을 줄이기 쉬움.',
        ),
        FoodPairingSuggestion(
          ingredient: '버섯',
          why: '감칠맛 + 식이섬유로 만족도를 올리기 쉬움.',
        ),
      ],
      quantitySuggestions: <String>[
        '돼지고기(살코기) 120g',
        '양배추 100g(또는 상추 한 줌)',
        '양파 1/2개',
        '버섯 1줌',
        '마늘 1~2쪽',
        '고추장 조금(선택)',
        '된장 조금(선택)',
      ],
    ),

    FoodKnowledgeEntry(
      primaryName: '우유/플레인 요거트',
      keywords: <String>['우유', '요거트', '요구르트', 'yogurt', 'milk'],
      dailyIntakeText:
          '성인(대략): 우유 200ml 1잔 또는 플레인 요거트 1컵(약 150~200g) '
          '정도를 간식/식사에 활용하는 경우가 많습니다.',
      pairings: <FoodPairingSuggestion>[
        FoodPairingSuggestion(
          ingredient: '견과류(무가당)',
          why: '식감/포만감을 올리되, 당이 많은 토핑 대신 무가당을 권장.',
        ),
        FoodPairingSuggestion(
          ingredient: '바나나/베리류',
          why: '과일로 자연스러운 단맛을 보완(과다 섭취는 주의).',
        ),
        FoodPairingSuggestion(
          ingredient: '귀리/오트',
          why: '복합탄수와 함께 먹기 쉬워 포만감에 도움.',
        ),
      ],
    ),

    FoodKnowledgeEntry(
      primaryName: '브로콜리',
      keywords: <String>['브로콜리', 'broccoli'],
      dailyIntakeText: '성인(대략): 익힌 브로콜리 1~2컵(대략 150~300g)/일 범위로 곁들이는 경우가 흔합니다.',
      pairings: <FoodPairingSuggestion>[
        FoodPairingSuggestion(
          ingredient: '닭고기/두부',
          why: '단백질 + 채소 조합으로 한 끼 구성이 쉬움.',
        ),
        FoodPairingSuggestion(
          ingredient: '올리브오일(소량)',
          why: '소량의 지방은 식감/만족도에 도움(과다 사용은 주의).',
        ),
        FoodPairingSuggestion(ingredient: '마늘', why: '향미를 올려 간을 과하게 하지 않게 도움.'),
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
      dailyIntakeText: '성인(대략): 중간 크기 1~2개/일 또는 샐러드 한 접시 정도로 섭취하는 경우가 흔합니다.',
      pairings: <FoodPairingSuggestion>[
        FoodPairingSuggestion(ingredient: '달걀', why: '간단하고 균형 잡힌 조합으로 활용이 쉬움.'),
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
      dailyIntakeText: '성인(대략): 익힌 잎채소 1~2컵/일 정도를 반찬/국에 곁들이는 경우가 많습니다.',
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
        FoodPairingSuggestion(ingredient: '당근', why: '볶음밥/스프 베이스로 채소 섭취량 증가.'),
        FoodPairingSuggestion(ingredient: '버섯류', why: '감칠맛 극대화로 염분 사용 감소.'),
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
        FoodPairingSuggestion(ingredient: '양파', why: '볶음/카레/스프 기본 조합으로 활용 쉬움.'),
        FoodPairingSuggestion(ingredient: '브로콜리', why: '색상 조합이 좋고 영양 균형 극대화.'),
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
        FoodPairingSuggestion(ingredient: '마늘/생강', why: '향신료로 가지의 식감을 부드럽게.'),
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
        FoodPairingSuggestion(ingredient: '돼지고기', why: '쌈 채소로 완벽한 조합. 포만감 증가.'),
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

    // 후식/간식 섹션
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
        FoodPairingSuggestion(
          ingredient: '우유',
          why: '밤의 포만감 + 우유의 칼슘으로 완벽한 조합.',
        ),
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
}
