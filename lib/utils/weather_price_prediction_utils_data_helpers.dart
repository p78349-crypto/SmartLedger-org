part of 'weather_price_prediction_utils.dart';

// ========== 날씨 민감 품목 데이터 ==========

/// 날씨에 민감한 품목 목록 (카테고리별)
const Map<String, List<String>> _weatherSensitiveItems = {
  '채소': [
    '배추', '무', '시금치', '상추', '깻잎', '양배추', '브로콜리',
    '당근', '고추', '파', '양파', '마늘', '감자', '고구마', '호박', '오이', '가지',
  ],
  '과일': [
    '사과', '배', '포도', '복숭아', '수박', '참외', '딸기',
    '귤', '오렌지', '바나나', '키위', '망고', '체리', '블루베리', '토마토',
  ],
  '수산물': [
    '고등어', '삼치', '갈치', '명태', '오징어', '낙지',
    '새우', '조개', '굴', '홍합', '미역', '김', '다시마',
  ],
  '육류': ['삼겹살', '목살', '등심', '안심', '닭가슴살', '닭다리'],
};

/// 품목별 날씨 민감도 (0~1, 높을수록 민감)
const Map<String, double> _itemWeatherSensitivity = {
  // 채소 (높은 민감도)
  '배추': 0.9, '시금치': 0.85, '상추': 0.85, '무': 0.8, '깻잎': 0.75,
  '양배추': 0.7, '고추': 0.8, '파': 0.65, '양파': 0.6, '마늘': 0.55,
  '오이': 0.75, '호박': 0.7, '가지': 0.7,
  // 과일 (중~높은 민감도)
  '수박': 0.85, '참외': 0.85, '딸기': 0.8, '포도': 0.75, '복숭아': 0.75,
  '사과': 0.6, '배': 0.55, '귤': 0.5, '바나나': 0.3, '토마토': 0.7,
  // 수산물 (중간 민감도)
  '고등어': 0.6, '삼치': 0.6, '갈치': 0.65, '오징어': 0.55, '새우': 0.5,
  '굴': 0.7, '미역': 0.4, '김': 0.35,
  // 육류 (낮은 민감도)
  '삼겹살': 0.3, '닭가슴살': 0.25, '등심': 0.3,
};

/// 날씨 조건별 가격 영향 규칙
const Map<String, Map<String, double>> _weatherImpactRules = {
  'hot': {
    '엽채류': 0.25, '수박': -0.15, '참외': -0.15, '수산물': 0.10,
  },
  'rainy': {
    '엽채류': 0.20, '과일': 0.15, '수산물': 0.05,
  },
  'cold': {
    '채소': 0.15, '수산물': 0.10, '난방비품목': 0.20,
  },
  'drought': {
    '채소': 0.30, '과일': 0.20,
  },
};

/// 월별 제철 식품
const Map<int, List<String>> _seasonalItems = {
  1: ['귤', '딸기', '시금치', '배추', '무', '굴', '삼치'],
  2: ['딸기', '시금치', '배추', '명태', '굴', '미역'],
  3: ['딸기', '미나리', '냉이', '달래', '바지락'],
  4: ['딸기', '키위', '미나리', '두릅', '조개류'],
  5: ['딸기', '참외', '매실', '양파', '감자', '멍게'],
  6: ['수박', '참외', '매실', '복숭아', '자두', '옥수수'],
  7: ['수박', '참외', '복숭아', '자두', '옥수수', '포도'],
  8: ['수박', '포도', '복숭아', '배', '고추', '전어'],
  9: ['배', '포도', '사과', '고구마', '대하', '전어', '삼치'],
  10: ['배', '사과', '감', '고구마', '대하', '갈치'],
  11: ['배', '사과', '감', '무', '배추', '굴'],
  12: ['귤', '사과', '배추', '무', '시금치', '굴', '명태'],
};

// ========== 유틸리티 헬퍼 ==========

/// 날짜로부터 계절 판단
Season _getSeason(DateTime date) {
  final month = date.month;
  if (month >= 3 && month <= 5) return Season.spring;
  if (month >= 6 && month <= 8) return Season.summer;
  if (month >= 9 && month <= 11) return Season.autumn;
  return Season.winter;
}

/// 계절 라벨
String _getSeasonLabel(Season season) {
  return switch (season) {
    Season.spring => '봄 (3~5월)',
    Season.summer => '여름 (6~8월)',
    Season.autumn => '가을 (9~11월)',
    Season.winter => '겨울 (12~2월)',
  };
}

/// 날씨 조건 분류
WeatherConditionType _classifyWeather(WeatherSnapshot weather) {
  final condition = weather.condition.toLowerCase();
  final temp = weather.tempC ?? 20.0;

  if (temp >= 30) return WeatherConditionType.hot;
  if (temp <= -5) return WeatherConditionType.cold;

  if (condition.contains('비') || condition.contains('rain')) {
    return WeatherConditionType.rainy;
  }
  if (condition.contains('눈') || condition.contains('snow')) {
    return WeatherConditionType.snowy;
  }
  if (condition.contains('맑') ||
      condition.contains('sunny') ||
      condition.contains('clear')) {
    return WeatherConditionType.sunny;
  }
  if (condition.contains('흐') || condition.contains('cloud')) {
    return WeatherConditionType.cloudy;
  }
  return WeatherConditionType.unknown;
}

/// 거래 데이터에서 품목별 가격 이력 추출
Map<String, List<PriceRecord>> _extractPriceHistory(
  List<Transaction> transactions, {
  DateTime? startDate,
  DateTime? endDate,
}) {
  final history = <String, List<PriceRecord>>{};

  for (final tx in transactions) {
    if (tx.type != TransactionType.expense) continue;
    if (tx.unitPrice <= 0) continue;

    // 기간 필터
    if (startDate != null && tx.date.isBefore(startDate)) continue;
    if (endDate != null && tx.date.isAfter(endDate)) continue;

    // 식료품 카테고리만
    final cat = tx.mainCategory.toLowerCase();
    if (!cat.contains('식') && !cat.contains('마트') && !cat.contains('장보기')) {
      continue;
    }

    final weather = tx.weather;
    final itemName = tx.description.trim();
    if (itemName.isEmpty) continue;

    history
        .putIfAbsent(itemName, () => [])
        .add(
          PriceRecord(
            date: tx.date,
            unitPrice: tx.unitPrice,
            weather: weather,
          ),
        );
  }

  return history;
}

/// 날씨 조건에 따른 가격 영향 계산
double _getWeatherImpact(String weatherKey, String itemName) {
  final rules = _weatherImpactRules[weatherKey];
  if (rules == null) return 0;

  if (rules.containsKey(itemName)) return rules[itemName]!;

  final category = _getItemCategory(itemName);
  if (rules.containsKey(category)) return rules[category]!;

  if (rules.containsKey('엽채류') && _isLeafyVegetable(itemName)) {
    return rules['엽채류']!;
  }

  return 0;
}

/// 품목의 카테고리 반환
String _getItemCategory(String itemName) {
  for (final entry in _weatherSensitiveItems.entries) {
    if (entry.value.contains(itemName)) return entry.key;
  }
  return '기타';
}

/// 엽채류 여부 확인
bool _isLeafyVegetable(String itemName) {
  const leafyVegetables = ['배추', '시금치', '상추', '깻잎', '양배추', '청경채'];
  return leafyVegetables.contains(itemName);
}

/// 피어슨 상관계수 계산 (단순화)
double _calculateCorrelation(List<double> x, List<double> y) {
  if (x.length != y.length || x.isEmpty) return 0;

  final n = x.length;
  final meanX = x.reduce((a, b) => a + b) / n;
  final meanY = y.reduce((a, b) => a + b) / n;

  var numerator = 0.0;
  var denomX = 0.0;
  var denomY = 0.0;

  for (var i = 0; i < n; i++) {
    final dx = x[i] - meanX;
    final dy = y[i] - meanY;
    numerator += dx * dy;
    denomX += dx * dx;
    denomY += dy * dy;
  }

  final denom = denomX * denomY;
  if (denom <= 0) return 0;
  return numerator / (denom > 0 ? denom.sqrt() : 1);
}

/// 신뢰도 계산
double _calculateConfidence({
  required int sampleCount,
  required double sensitivity,
  required bool hasWeatherData,
}) {
  var confidence = 0.3;

  if (sampleCount >= 50) {
    confidence += 0.3;
  } else if (sampleCount >= 20) {
    confidence += 0.2;
  } else if (sampleCount >= 10) {
    confidence += 0.1;
  }

  confidence += sensitivity * 0.2;
  if (hasWeatherData) confidence += 0.1;

  return confidence.clamp(0.0, 1.0);
}
