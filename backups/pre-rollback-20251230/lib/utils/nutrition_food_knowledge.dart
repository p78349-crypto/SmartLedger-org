import 'package:flutter/foundation.dart';

@immutable
class FoodPairingSuggestion {
  const FoodPairingSuggestion({
    required this.ingredient,
    required this.why,
  });

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

  static const List<FoodKnowledgeEntry> _entries = <FoodKnowledgeEntry>[
    FoodKnowledgeEntry(
      primaryName: '닭고기(살코기)',
      keywords: <String>[
        '닭고기',
        '닭',
        '치킨',
        '닭가슴살',
        'chicken',
        'chickenbreast',
      ],
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
      dailyIntakeText:
          '성인(대략): 1/2~1모(약 150~300g)/일 범위로 나눠 먹는 경우가 흔합니다.',
      pairings: <FoodPairingSuggestion>[
        FoodPairingSuggestion(
          ingredient: '김치/파/마늘',
          why: '담백한 맛을 보완해 조리 만족도를 올리기 쉬움(염분은 주의).',
        ),
        FoodPairingSuggestion(
          ingredient: '버섯',
          why: '식이섬유·감칠맛으로 포만감에 도움.',
        ),
        FoodPairingSuggestion(
          ingredient: '현미/잡곡',
          why: '식물성 단백질과 곡류 조합으로 한 끼 구성이 쉬움.',
        ),
      ],
    ),

    FoodKnowledgeEntry(
      primaryName: '연어(등푸른 생선)',
      keywords: <String>[
        '연어',
        'salmon',
      ],
      dailyIntakeText:
          '성인(대략): 조리된 생선 100~150g/회, 주 1~3회 정도로 섭취하는 경우가 많습니다.',
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
      keywords: <String>[
        '소고기',
        '소',
        'beef',
      ],
      dailyIntakeText:
          '성인(대략): 조리된 살코기 80~120g/회 정도를 한 끼 단백질로 활용하는 경우가 많습니다.',
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
      keywords: <String>[
        '돼지고기',
        '돼지',
        'pork',
      ],
      dailyIntakeText:
          '성인(대략): 조리된 살코기 80~120g/회 정도를 한 끼 단백질로 활용하는 경우가 많습니다.',
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
      keywords: <String>[
        '우유',
        '요거트',
        '요구르트',
        'yogurt',
        'milk',
      ],
      dailyIntakeText:
          '성인(대략): 우유 200ml 1잔 또는 플레인 요거트 1컵(약 150~200g) 정도를 간식/식사에 활용하는 경우가 많습니다.',
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
        FoodPairingSuggestion(
          ingredient: '달걀',
          why: '간단한 단백질 보강 조합.',
        ),
        FoodPairingSuggestion(
          ingredient: '양파',
          why: '향미를 올려 간단 조리에 도움.',
        ),
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
        FoodPairingSuggestion(
          ingredient: '마늘',
          why: '향미로 간단 조리에 도움.',
        ),
        FoodPairingSuggestion(
          ingredient: '두부',
          why: '담백한 단백질과 잘 어울림.',
        ),
      ],
    ),
  ];
}

