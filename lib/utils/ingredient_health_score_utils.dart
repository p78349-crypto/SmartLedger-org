/// 식재료별 건강 점수 데이터베이스
/// 영수증 재료 기반 건강도 평가
class IngredientHealthScoreUtils {
  IngredientHealthScoreUtils._();

  /// 재료별 건강 점수 (1-5)
  /// 5 = 매우 건강 (채소, 버섯, 해조류)
  /// 4 = 건강 (생선, 두부, 콩)
  /// 3 = 보통 (닭가슴살, 계란, 쌀)
  /// 2 = 주의 (돼지고기, 소고기, 치즈)
  /// 1 = 비건강 (튀김, 가공육, 인스턴트)
  static const Map<String, int> ingredientScores = {
    // 채소류 (5점)
    '양배추': 5,
    '브로콜리': 5,
    '호박': 5,
    '가지': 5,
    '당근': 5,
    '양파': 5,
    '감자': 4, // 전분이 많아 4점
    '고구마': 4,
    '시금치': 5,
    '배추': 5,
    '상추': 5,
    '깻잎': 5,
    '파': 5,
    '마늘': 5,
    '생강': 5,
    '토마토': 5,
    '오이': 5,
    '무': 5,
    '콩나물': 5,
    '숙주': 5,

    // 버섯류 (5점)
    '느타리버섯': 5,
    '표고버섯': 5,
    '팽이버섯': 5,
    '새송이버섯': 5,
    '양송이버섯': 5,
    '목이버섯': 5,

    // 단백질 - 식물성 (5점)
    '두부': 5,
    '콩': 5,
    '된장': 4, // 나트륨 있어서 4점
    '청국장': 4,

    // 단백질 - 닭고기 (3-4점)
    '닭가슴살': 4,
    '닭고기': 3,
    '닭다리': 3,
    '닭튀김당': 1, // 튀김이라 1점
    // 단백질 - 돼지고기 (2-3점)
    '돼지고기': 2,
    '삼겹살': 2,
    '목살': 2,
    '앞다리': 3,

    // 단백질 - 소고기 (2-3점)
    '소고기': 3,
    '안심': 3,
    '등심': 2,

    // 해산물 (4-5점)
    '생선': 4,
    '고등어': 4,
    '삼치': 4,
    '연어': 4,
    '참치': 4,
    '새우': 4,
    '오징어': 4,
    '멸치': 5,
    '김': 5,
    '미역': 5,

    // 곡물 (3-4점)
    '쌀': 3,
    '현미': 4,
    '잡곡': 4,
    '귀리': 5,

    // 유제품 (3-4점)
    '우유': 3,
    '요구르트': 3,
    '치즈': 2,

    // 조미료 (2-3점)
    '고추장': 3,
    '간장': 3,
    '식용유': 2,
    '참기름': 3,
    '설탕': 1,
    '소금': 2,

    // 가공식품 (1-2점)
    '라면': 1,
    '햄': 1,
    '소시지': 1,
    '베이컨': 1,
    '통조림': 2,
  };

  /// 재료 이름으로 건강 점수 조회
  /// 매칭되는 항목 없으면 3점(보통) 반환
  static int getScore(String ingredientName) {
    final name = ingredientName.toLowerCase().trim();

    // 정확히 일치하는 항목 찾기
    for (final entry in ingredientScores.entries) {
      final key = entry.key.toLowerCase();
      if (name == key || name.contains(key) || key.contains(name)) {
        return entry.value;
      }
    }

    // 카테고리별 키워드 매칭
    if (_isVegetable(name)) return 5;
    if (_isMushroom(name)) return 5;
    if (_isSeafood(name)) return 4;
    if (_isChicken(name)) return 3;
    if (_isPork(name)) return 2;
    if (_isFried(name)) return 1;
    if (_isProcessed(name)) return 1;

    return 3; // 기본값: 보통
  }

  static bool _isVegetable(String name) {
    return name.contains('채소') ||
        name.contains('야채') ||
        name.contains('상추') ||
        name.contains('깻잎') ||
        name.contains('파') ||
        name.contains('쌈');
  }

  static bool _isMushroom(String name) {
    return name.contains('버섯');
  }

  static bool _isSeafood(String name) {
    return name.contains('생선') ||
        name.contains('어') ||
        name.contains('새우') ||
        name.contains('조개') ||
        name.contains('게') ||
        name.contains('해산물');
  }

  static bool _isChicken(String name) {
    return name.contains('닭') || name.contains('치킨');
  }

  static bool _isPork(String name) {
    return name.contains('돼지') || name.contains('삼겹') || name.contains('목살');
  }

  static bool _isFried(String name) {
    return name.contains('튀김') || name.contains('후라이드') || name.contains('치킨');
  }

  static bool _isProcessed(String name) {
    return name.contains('라면') ||
        name.contains('햄') ||
        name.contains('소시지') ||
        name.contains('베이컨') ||
        name.contains('통조림');
  }

  /// 재료 목록의 평균 건강 점수 계산
  /// 채소/버섯 비율이 높으면 보너스 점수
  static double calculateAverageScore(List<String> ingredients) {
    if (ingredients.isEmpty) return 3.0;

    int totalScore = 0;
    int vegetableCount = 0;
    int mushroomCount = 0;

    for (final ingredient in ingredients) {
      final score = getScore(ingredient);
      totalScore += score;

      if (score == 5) {
        if (_isMushroom(ingredient)) {
          mushroomCount++;
        } else {
          vegetableCount++;
        }
      }
    }

    double average = totalScore / ingredients.length;

    // 채소/버섯 비율이 50% 이상이면 +0.5점
    final healthyRatio = (vegetableCount + mushroomCount) / ingredients.length;
    if (healthyRatio >= 0.5) {
      average = (average + 0.5).clamp(1.0, 5.0);
    }

    return average;
  }

  /// 재료 목록으로 정수 건강 점수 계산 (1-5)
  static int calculateRecipeScore(List<String> ingredients) {
    final average = calculateAverageScore(ingredients);
    return average.round().clamp(1, 5);
  }

  /// 건강 점수 라벨
  static String getScoreLabel(int score) {
    switch (score) {
      case 5:
        return '💚 매우 건강';
      case 4:
        return '💚 건강';
      case 3:
        return '🟡 보통';
      case 2:
        return '🟠 주의';
      case 1:
        return '🔴 비건강';
      default:
        return '🟡 보통';
    }
  }

  /// 건강 점수 상세 설명
  static String getScoreDescription(int score) {
    switch (score) {
      case 5:
        return '영양소가 풍부하고 칼로리가 낮은 최고의 선택입니다';
      case 4:
        return '건강에 좋은 재료입니다';
      case 3:
        return '적당히 섭취하면 좋습니다';
      case 2:
        return '지방이나 나트륨이 많을 수 있으니 주의하세요';
      case 1:
        return '가급적 적게 드세요';
      default:
        return '보통 수준의 재료입니다';
    }
  }

  /// 재료별 건강 점수 분석 결과
  static IngredientAnalysis analyzeIngredients(List<String> ingredients) {
    final scores = <String, int>{};
    int score5 = 0;
    int score4 = 0;
    int score3 = 0;
    int score2 = 0;
    int score1 = 0;

    for (final ingredient in ingredients) {
      final score = getScore(ingredient);
      scores[ingredient] = score;

      switch (score) {
        case 5:
          score5++;
          break;
        case 4:
          score4++;
          break;
        case 3:
          score3++;
          break;
        case 2:
          score2++;
          break;
        case 1:
          score1++;
          break;
      }
    }

    return IngredientAnalysis(
      ingredientScores: scores,
      veryHealthyCount: score5,
      healthyCount: score4,
      normalCount: score3,
      cautionCount: score2,
      unhealthyCount: score1,
      averageScore: calculateAverageScore(ingredients),
      overallScore: calculateRecipeScore(ingredients),
    );
  }
}

/// 재료 분석 결과
class IngredientAnalysis {
  final Map<String, int> ingredientScores; // 재료별 점수
  final int veryHealthyCount; // 5점 재료 개수
  final int healthyCount; // 4점 재료 개수
  final int normalCount; // 3점 재료 개수
  final int cautionCount; // 2점 재료 개수
  final int unhealthyCount; // 1점 재료 개수
  final double averageScore; // 평균 점수
  final int overallScore; // 전체 점수 (1-5)

  IngredientAnalysis({
    required this.ingredientScores,
    required this.veryHealthyCount,
    required this.healthyCount,
    required this.normalCount,
    required this.cautionCount,
    required this.unhealthyCount,
    required this.averageScore,
    required this.overallScore,
  });

  /// 건강한 재료 비율 (4-5점)
  double get healthyRatio {
    final total = ingredientScores.length;
    if (total == 0) return 0.0;
    return (veryHealthyCount + healthyCount) / total;
  }

  /// 주의/비건강 재료 비율 (1-2점)
  double get unhealthyRatio {
    final total = ingredientScores.length;
    if (total == 0) return 0.0;
    return (cautionCount + unhealthyCount) / total;
  }

  /// 건강도 요약 메시지
  String get summary {
    if (overallScore >= 4) {
      return '💚 매우 건강한 재료 조합입니다! (${(healthyRatio * 100).toInt()}% 건강 재료)';
    } else if (overallScore == 3) {
      return '🟡 적당한 재료 조합입니다';
    } else {
      return '🟠 건강한 재료를 더 추가해보세요';
    }
  }
}
