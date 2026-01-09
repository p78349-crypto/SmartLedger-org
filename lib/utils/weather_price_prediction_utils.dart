/// 날씨 기반 식료품 가격 예측 유틸리티
///
/// 1년 날씨 데이터와 구매 기록을 분석하여 식료품 가격 등락을 예측합니다.
/// - 기온/강수량과 가격의 상관관계 분석
/// - 계절별 가격 패턴 학습
/// - 다음 달 가격 예측 및 알림
library;

import '../models/transaction.dart';
import '../models/weather_snapshot.dart';

/// 날씨 조건 분류
enum WeatherConditionType {
  sunny, // 맑음
  cloudy, // 흐림
  rainy, // 비
  snowy, // 눈
  hot, // 폭염 (30도 이상)
  cold, // 한파 (-5도 이하)
  unknown,
}

/// 계절 분류
enum Season {
  spring, // 3~5월
  summer, // 6~8월
  autumn, // 9~11월
  winter, // 12~2월
}

/// 가격 변동 방향
enum PriceTrend {
  rising, // 상승
  falling, // 하락
  stable, // 안정
}

/// 품목별 날씨-가격 상관관계
class WeatherPriceCorrelation {
  final String itemName;
  final String category;
  final double correlationCoeff; // -1 ~ 1 (음의 상관 ~ 양의 상관)
  final WeatherFactorType weatherFactor;
  final String explanation;

  const WeatherPriceCorrelation({
    required this.itemName,
    required this.category,
    required this.correlationCoeff,
    required this.weatherFactor,
    required this.explanation,
  });

  /// 상관관계 강도 (0~1)
  double get strength => correlationCoeff.abs();
}

/// 날씨 요소 유형
enum WeatherFactorType {
  temperature, // 기온
  precipitation, // 강수량
  humidity, // 습도
  condition, // 날씨 상태
}

/// 가격 예측 결과
class PricePrediction {
  final String itemName;
  final DateTime predictionDate;
  final double currentPrice;
  final double predictedPrice;
  final PriceTrend trend;
  final double confidence; // 0~1
  final String reason;
  final List<String> recommendations;

  const PricePrediction({
    required this.itemName,
    required this.predictionDate,
    required this.currentPrice,
    required this.predictedPrice,
    required this.trend,
    required this.confidence,
    required this.reason,
    this.recommendations = const [],
  });

  /// 예상 변동률 (%)
  double get changePercent {
    if (currentPrice <= 0) return 0;
    return ((predictedPrice - currentPrice) / currentPrice) * 100;
  }
}

/// 날씨 기반 가격 알림
class WeatherPriceAlert {
  final String itemName;
  final String category;
  final String triggerWeather; // 원인이 된 날씨
  final PriceTrend expectedTrend;
  final double expectedChangePercent;
  final int daysUntilImpact; // 영향까지 예상 일수
  final String recommendation;

  const WeatherPriceAlert({
    required this.itemName,
    required this.category,
    required this.triggerWeather,
    required this.expectedTrend,
    required this.expectedChangePercent,
    required this.daysUntilImpact,
    required this.recommendation,
  });
}

/// 계절별 가격 통계
class SeasonalPriceStat {
  final Season season;
  final String itemName;
  final double avgPrice;
  final double minPrice;
  final double maxPrice;
  final int sampleCount;

  const SeasonalPriceStat({
    required this.season,
    required this.itemName,
    required this.avgPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.sampleCount,
  });
}

/// 날씨 기반 가격 예측 유틸리티
class WeatherPricePredictionUtils {
  WeatherPricePredictionUtils._();

  // ========== 날씨 민감 품목 데이터 ==========

  /// 날씨에 민감한 품목 목록 (카테고리별)
  static const Map<String, List<String>> weatherSensitiveItems = {
    '채소': [
      '배추',
      '무',
      '시금치',
      '상추',
      '깻잎',
      '양배추',
      '브로콜리',
      '당근',
      '고추',
      '파',
      '양파',
      '마늘',
      '감자',
      '고구마',
      '호박',
      '오이',
      '가지',
    ],
    '과일': [
      '사과',
      '배',
      '포도',
      '복숭아',
      '수박',
      '참외',
      '딸기',
      '귤',
      '오렌지',
      '바나나',
      '키위',
      '망고',
      '체리',
      '블루베리',
      '토마토',
    ],
    '수산물': [
      '고등어',
      '삼치',
      '갈치',
      '명태',
      '오징어',
      '낙지',
      '새우',
      '조개',
      '굴',
      '홍합',
      '미역',
      '김',
      '다시마',
    ],
    '육류': ['삼겹살', '목살', '등심', '안심', '닭가슴살', '닭다리'],
  };

  /// 품목별 날씨 민감도 (0~1, 높을수록 민감)
  static const Map<String, double> itemWeatherSensitivity = {
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
  static const Map<String, Map<String, double>> weatherImpactRules = {
    'hot': {
      '엽채류': 0.25, // 폭염시 엽채류 25% 상승
      '수박': -0.15, // 폭염시 수박 15% 하락 (출하량 증가)
      '참외': -0.15,
      '수산물': 0.10, // 어획량 감소로 10% 상승
    },
    'rainy': {
      '엽채류': 0.20, // 장마시 20% 상승
      '과일': 0.15, // 과일 15% 상승
      '수산물': 0.05, // 어획 어려움으로 5% 상승
    },
    'cold': {
      '채소': 0.15, // 한파시 채소 15% 상승
      '수산물': 0.10, // 어획 어려움
      '난방비품목': 0.20, // 고구마, 감자 등
    },
    'drought': {
      '채소': 0.30, // 가뭄시 채소 30% 상승
      '과일': 0.20, // 과일 20% 상승
    },
  };

  /// 월별 제철 식품
  static const Map<int, List<String>> seasonalItems = {
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

  // ========== 핵심 예측 메서드 ==========

  /// 현재 날씨와 과거 데이터를 기반으로 품목 가격 예측
  static PricePrediction? predictPrice({
    required String itemName,
    required List<Transaction> transactions,
    required WeatherSnapshot currentWeather,
    DateTime? targetDate,
  }) {
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));

    // 해당 품목의 가격 이력 추출
    final priceHistory = _extractPriceHistory(
      transactions,
      startDate: oneYearAgo,
    );

    final records = priceHistory[itemName] ?? [];
    if (records.length < 3) return null; // 데이터 부족

    // 현재 평균 가격 (최근 30일)
    final recentDate = now.subtract(const Duration(days: 30));
    final recentRecords = records
        .where((r) => r.date.isAfter(recentDate))
        .toList();
    if (recentRecords.isEmpty) return null;

    final currentPrice =
        recentRecords.fold<double>(0, (s, r) => s + r.unitPrice) /
        recentRecords.length;

    // 예측 로직
    var predictedPrice = currentPrice;
    var reason = '';
    final recommendations = <String>[];

    // 1. 날씨 영향 분석
    final sensitivity = itemWeatherSensitivity[itemName] ?? 0.5;
    final weatherType = _classifyWeather(currentWeather);

    // 기온 영향
    final temp = currentWeather.tempC ?? 20.0;
    if (temp >= 30) {
      // 폭염
      final impact = _getWeatherImpact('hot', itemName);
      predictedPrice *= 1 + impact;
      if (impact != 0) {
        reason = '폭염으로 인한 가격 ${impact > 0 ? "상승" : "하락"} 예상';
        if (impact > 0) {
          recommendations.add('지금 구매하시면 좋아요!');
        }
      }
    } else if (temp <= -5) {
      // 한파
      final impact = _getWeatherImpact('cold', itemName);
      predictedPrice *= 1 + impact;
      if (impact != 0) {
        reason = '한파로 인한 가격 ${impact > 0 ? "상승" : "하락"} 예상';
      }
    }

    // 강수량 영향
    final precipitation = currentWeather.precipitation1hMm ?? 0;
    if (precipitation > 10 || weatherType == WeatherConditionType.rainy) {
      final impact = _getWeatherImpact('rainy', itemName);
      predictedPrice *= 1 + impact * sensitivity;
      if (impact != 0 && reason.isEmpty) {
        reason = '장마/비로 인한 가격 변동 예상';
      }
    }

    // 2. 계절 영향
    final targetSeason = getSeason(targetDate ?? now);
    final seasonalStats = calculateSeasonalStats(itemName, transactions);
    final seasonStat = seasonalStats
        .where((s) => s.season == targetSeason)
        .firstOrNull;

    if (seasonStat != null && seasonStat.sampleCount >= 3) {
      // 계절 평균 대비 조정
      final seasonalAdjustment = seasonStat.avgPrice / currentPrice;
      if (seasonalAdjustment > 1.1 || seasonalAdjustment < 0.9) {
        predictedPrice *= 1.0 + (seasonalAdjustment - 1.0) * 0.3;
        reason += '\n${getSeasonLabel(targetSeason)} 계절적 가격 변동 반영';
      }
    }

    // 트렌드 결정
    final changePercent =
        ((predictedPrice - currentPrice) / currentPrice) * 100;
    final trend = changePercent > 5
        ? PriceTrend.rising
        : changePercent < -5
        ? PriceTrend.falling
        : PriceTrend.stable;

    // 신뢰도 계산
    final confidence = _calculateConfidence(
      sampleCount: records.length,
      sensitivity: sensitivity,
      hasWeatherData: records.any((r) => r.weather != null),
    );

    return PricePrediction(
      itemName: itemName,
      predictionDate: targetDate ?? now.add(const Duration(days: 7)),
      currentPrice: currentPrice,
      predictedPrice: predictedPrice,
      trend: trend,
      confidence: confidence,
      reason: reason.isEmpty ? '안정적인 가격 흐름 예상' : reason,
      recommendations: recommendations,
    );
  }

  /// 현재 날씨 기반 가격 알림 생성
  static List<WeatherPriceAlert> generateAlerts({
    required List<Transaction> transactions,
    required WeatherSnapshot currentWeather,
  }) {
    final alerts = <WeatherPriceAlert>[];
    final temp = currentWeather.tempC ?? 20.0;
    final weatherType = _classifyWeather(currentWeather);

    // 폭염 알림
    if (temp >= 30) {
      alerts.add(
        const WeatherPriceAlert(
          itemName: '배추',
          category: '채소',
          triggerWeather: '폭염 (30도 이상)',
          expectedTrend: PriceTrend.rising,
          expectedChangePercent: 20.0,
          daysUntilImpact: 7,
          recommendation: '배추를 미리 구매하세요! 폭염 지속시 가격 상승 예상',
        ),
      );
      alerts.add(
        const WeatherPriceAlert(
          itemName: '시금치',
          category: '채소',
          triggerWeather: '폭염 (30도 이상)',
          expectedTrend: PriceTrend.rising,
          expectedChangePercent: 25.0,
          daysUntilImpact: 5,
          recommendation: '엽채류 미리 구매 추천',
        ),
      );
      alerts.add(
        const WeatherPriceAlert(
          itemName: '수박',
          category: '과일',
          triggerWeather: '폭염 (30도 이상)',
          expectedTrend: PriceTrend.falling,
          expectedChangePercent: -15.0,
          daysUntilImpact: 3,
          recommendation: '수박은 조금 기다리면 더 싸게 살 수 있어요!',
        ),
      );
    }

    // 한파 알림
    if (temp <= -5) {
      alerts.add(
        const WeatherPriceAlert(
          itemName: '채소류',
          category: '채소',
          triggerWeather: '한파 (-5도 이하)',
          expectedTrend: PriceTrend.rising,
          expectedChangePercent: 15.0,
          daysUntilImpact: 5,
          recommendation: '한파 전에 채소를 미리 구매하세요',
        ),
      );
    }

    // 비/장마 알림
    if (weatherType == WeatherConditionType.rainy ||
        (currentWeather.precipitation1hMm ?? 0) > 10) {
      alerts.add(
        const WeatherPriceAlert(
          itemName: '엽채류',
          category: '채소',
          triggerWeather: '장마/폭우',
          expectedTrend: PriceTrend.rising,
          expectedChangePercent: 20.0,
          daysUntilImpact: 7,
          recommendation: '장마 전에 채소를 비축해두세요',
        ),
      );
    }

    return alerts;
  }

  /// 품목의 날씨-가격 상관관계 분석
  static WeatherPriceCorrelation? analyzeWeatherCorrelation(
    String itemName,
    List<Transaction> transactions,
  ) {
    final priceHistory = _extractPriceHistory(transactions);
    final records = priceHistory[itemName] ?? [];

    // 날씨 데이터가 있는 레코드만 필터
    final weatherRecords = records.where((r) => r.weather != null).toList();
    if (weatherRecords.length < 5) return null;

    // 기온과 가격의 상관관계 계산 (단순화)
    final temps = weatherRecords.map((r) => r.weather!.tempC ?? 20.0).toList();
    final prices = weatherRecords.map((r) => r.unitPrice).toList();

    final correlation = _calculateCorrelation(temps, prices);
    final category = _getItemCategory(itemName);
    final sensitivity = itemWeatherSensitivity[itemName] ?? 0.5;

    String explanation;
    if (correlation > 0.3) {
      explanation = '기온이 올라갈수록 $itemName 가격이 상승하는 경향이 있습니다.';
    } else if (correlation < -0.3) {
      explanation = '기온이 올라갈수록 $itemName 가격이 하락하는 경향이 있습니다.';
    } else {
      explanation = '$itemName는 날씨 변화에 비교적 안정적인 가격을 유지합니다.';
    }

    return WeatherPriceCorrelation(
      itemName: itemName,
      category: category,
      correlationCoeff: correlation * sensitivity,
      weatherFactor: WeatherFactorType.temperature,
      explanation: explanation,
    );
  }

  /// 계절별 가격 통계 계산
  static List<SeasonalPriceStat> calculateSeasonalStats(
    String itemName,
    List<Transaction> transactions,
  ) {
    final priceHistory = _extractPriceHistory(transactions);
    final records = priceHistory[itemName] ?? [];
    if (records.isEmpty) return [];

    // 계절별 그룹핑
    final seasonGroups = <Season, List<double>>{};
    for (final record in records) {
      final season = getSeason(record.date);
      seasonGroups.putIfAbsent(season, () => []).add(record.unitPrice);
    }

    return seasonGroups.entries.map((entry) {
      final prices = entry.value;
      final avg = prices.fold<double>(0, (s, p) => s + p) / prices.length;

      return SeasonalPriceStat(
        season: entry.key,
        itemName: itemName,
        avgPrice: avg,
        minPrice: prices.reduce((a, b) => a < b ? a : b),
        maxPrice: prices.reduce((a, b) => a > b ? a : b),
        sampleCount: prices.length,
      );
    }).toList()..sort((a, b) => a.season.index.compareTo(b.season.index));
  }

  /// 제철 식품 추천
  static List<String> getSeasonalRecommendations(DateTime date) {
    return seasonalItems[date.month] ?? [];
  }

  /// 날씨 종합 리포트 생성
  static String generateWeatherPriceReport({
    required List<Transaction> transactions,
    required WeatherSnapshot currentWeather,
  }) {
    final buffer = StringBuffer();
    final temp = currentWeather.tempC ?? 20.0;
    final now = DateTime.now();
    final month = now.month;

    // 현재 날씨 요약
    buffer.writeln('## 현재 날씨 분석');
    buffer.writeln('기온: ${temp.toStringAsFixed(1)}도');

    if (temp >= 30) {
      buffer.writeln('\n### 폭염 주의보');
      buffer.writeln('• 엽채류(배추, 시금치, 상추) 가격 상승 예상');
      buffer.writeln('• 여름 과일(수박, 참외) 출하량 증가로 가격 하락 예상');
      buffer.writeln('• 추천: 채소는 미리, 과일은 조금 기다렸다 구매');
    } else if (temp <= -5) {
      buffer.writeln('\n### 한파 주의보');
      buffer.writeln('• 채소류 전반 가격 상승 예상');
      buffer.writeln('• 난방 관련 비용 증가');
      buffer.writeln('• 추천: 김장 채소 미리 확보, 뿌리채소 비축');
    } else if (temp >= 25) {
      buffer.writeln('\n### 더운 날씨');
      buffer.writeln('• 냉장 보관 필요 품목 유의');
      buffer.writeln('• 제철 과일 구매 적기');
    }

    // 제철 식품 추천
    buffer.writeln('\n## $month월 제철 식품');
    final seasonal = getSeasonalRecommendations(now);
    if (seasonal.isNotEmpty) {
      buffer.writeln(seasonal.join(', '));
      buffer.writeln('\n• 제철 식품은 맛과 영양이 좋고 가격도 저렴해요!');
    }

    // 구매 타이밍 조언
    buffer.writeln('\n## 구매 타이밍 조언');
    if (month >= 6 && month <= 8) {
      buffer.writeln('• 여름 과일: 지금이 가장 저렴한 시기');
      buffer.writeln('• 채소류: 장마/폭염 전 미리 구매 추천');
    } else if (month >= 9 && month <= 11) {
      buffer.writeln('• 가을 과일(사과, 배, 포도): 제철로 가격 좋음');
      buffer.writeln('• 김장 채소: 11월 초중순이 가장 적기');
    } else if (month == 12 || month <= 2) {
      buffer.writeln('• 한파 전 채소 비축 추천');
      buffer.writeln('• 겨울 수산물(굴, 명태) 제철');
    } else {
      buffer.writeln('• 봄 채소(냉이, 달래, 미나리) 제철');
      buffer.writeln('• 딸기 시즌 마지막 기회');
    }

    return buffer.toString();
  }

  // ========== 유틸리티 메서드 ==========

  /// 날짜로부터 계절 판단
  static Season getSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.autumn;
    return Season.winter;
  }

  /// 계절 라벨
  static String getSeasonLabel(Season season) {
    return switch (season) {
      Season.spring => '봄 (3~5월)',
      Season.summer => '여름 (6~8월)',
      Season.autumn => '가을 (9~11월)',
      Season.winter => '겨울 (12~2월)',
    };
  }

  // ========== Private 헬퍼 메서드 ==========

  /// 날씨 조건 분류
  static WeatherConditionType _classifyWeather(WeatherSnapshot weather) {
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

  /// 거래 데이터에서 품목별 가격 이력 추출 (내부 전용)
  static Map<String, List<PriceRecord>> _extractPriceHistory(
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

      // 날씨 직접 사용 (Transaction에 WeatherSnapshot으로 저장됨)
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
  static double _getWeatherImpact(String weatherKey, String itemName) {
    final rules = weatherImpactRules[weatherKey];
    if (rules == null) return 0;

    // 품목명 직접 매칭
    if (rules.containsKey(itemName)) {
      return rules[itemName]!;
    }

    // 카테고리 매칭
    final category = _getItemCategory(itemName);
    if (rules.containsKey(category)) {
      return rules[category]!;
    }

    // 엽채류 특별 처리
    if (rules.containsKey('엽채류') && _isLeafyVegetable(itemName)) {
      return rules['엽채류']!;
    }

    return 0;
  }

  /// 품목의 카테고리 반환
  static String _getItemCategory(String itemName) {
    for (final entry in weatherSensitiveItems.entries) {
      if (entry.value.contains(itemName)) {
        return entry.key;
      }
    }
    return '기타';
  }

  /// 엽채류 여부 확인
  static bool _isLeafyVegetable(String itemName) {
    const leafyVegetables = ['배추', '시금치', '상추', '깻잎', '양배추', '청경채'];
    return leafyVegetables.contains(itemName);
  }

  /// 피어슨 상관계수 계산 (단순화)
  static double _calculateCorrelation(List<double> x, List<double> y) {
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
  static double _calculateConfidence({
    required int sampleCount,
    required double sensitivity,
    required bool hasWeatherData,
  }) {
    var confidence = 0.3; // 기본값

    // 샘플 수 기반
    if (sampleCount >= 50) {
      confidence += 0.3;
    } else if (sampleCount >= 20) {
      confidence += 0.2;
    } else if (sampleCount >= 10) {
      confidence += 0.1;
    }

    // 민감도 기반
    confidence += sensitivity * 0.2;

    // 날씨 데이터 유무
    if (hasWeatherData) confidence += 0.1;

    return confidence.clamp(0.0, 1.0);
  }
}

/// 가격 레코드
class PriceRecord {
  final DateTime date;
  final double unitPrice;
  final WeatherSnapshot? weather;

  const PriceRecord({
    required this.date,
    required this.unitPrice,
    this.weather,
  });
}

extension on double {
  double sqrt() => this > 0 ? _sqrt(this) : 0;

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    var guess = x / 2;
    for (var i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
