part of 'weather_price_prediction_utils.dart';

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

/// 날씨 요소 유형
enum WeatherFactorType {
  temperature, // 기온
  precipitation, // 강수량
  humidity, // 습도
  condition, // 날씨 상태
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
