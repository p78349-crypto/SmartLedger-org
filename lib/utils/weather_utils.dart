// 날씨 기반 물가 예측 엔진 (Weather-Price Engine)
//
// 날씨 정보를 기반으로 품목별 가격 변동을 예측하고,
// 사용자에게 구매 타이밍을 추천합니다.

import 'package:flutter/foundation.dart';
import 'weather_price_sensitivity.dart';
import 'cache_utils.dart';

/// 날씨 데이터 모델
class WeatherData {
  final WeatherCondition condition;
  final double temperature;
  final int humidity;
  final DateTime timestamp;
  final String location;

  const WeatherData({
    required this.condition,
    required this.temperature,
    required this.humidity,
    required this.timestamp,
    required this.location,
  });

  /// 한파 여부 (-10도 이하)
  bool get isColdWave => temperature <= -10;

  /// 폭염 여부 (33도 이상)
  bool get isHeatWave => temperature >= 33;

  /// 실제 날씨 조건 (한파/폭염 우선 판단)
  WeatherCondition get effectiveCondition {
    if (isColdWave) return WeatherCondition.coldWave;
    if (isHeatWave) return WeatherCondition.heatWave;
    return condition;
  }

  @override
  String toString() {
    return 'WeatherData(condition: ${weatherConditionNames[effectiveCondition]}, '
        'temp: $temperature°C, humidity: $humidity%, location: $location)';
  }
}

/// 가격 변동 예측 결과
class PricePrediction {
  final String itemName;
  final PriceCategory category;
  final double sensitivity; // -1.0 ~ +1.0
  final double predictedChange; // 예상 변동률 (%)
  final String recommendation; // 한국어 추천 메시지
  final String reason; // 변동 이유
  final WeatherCondition weatherCondition;

  const PricePrediction({
    required this.itemName,
    required this.category,
    required this.sensitivity,
    required this.predictedChange,
    required this.recommendation,
    required this.reason,
    required this.weatherCondition,
  });

  /// 가격 상승 예상 여부
  bool get isPriceIncreasing => predictedChange > 0;

  /// 가격 하락 예상 여부
  bool get isPriceDecreasing => predictedChange < 0;

  /// 큰 폭 변동 여부 (±10% 이상)
  bool get isSignificantChange => predictedChange.abs() >= 10.0;

  @override
  String toString() {
    return 'PricePrediction($itemName: ${predictedChange > 0 ? '+' : ''}${predictedChange.toStringAsFixed(1)}%, $recommendation)';
  }
}

/// 날씨 기반 물가 예측 유틸리티
class WeatherUtils {
  /// 캐시 (5분 TTL)
  static final _cache = SimpleCache<String, List<PricePrediction>>(
    maxAge: const Duration(minutes: 5),
  );

  /// 날씨 데이터를 기반으로 품목별 가격 변동 예측
  ///
  /// [weather] 현재 날씨 정보
  /// [items] 예측할 품목 목록 (null이면 전체)
  /// [minSensitivity] 최소 민감도 필터 (기본값: 0.3, 30% 이상만 반환)
  static List<PricePrediction> predictPriceChanges({
    required WeatherData weather,
    List<String>? items,
    double minSensitivity = 0.3,
  }) {
    // 캐시 확인
    final cacheKey =
        '${weather.effectiveCondition}_${items?.join(',') ?? 'all'}_$minSensitivity';
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      return cached;
    }

    final predictions = <PricePrediction>[];
    final condition = weather.effectiveCondition;

    // 대상 품목 필터링
    final targetItems = items != null
        ? weatherPriceSensitivityDatabase
              .where((item) => items.contains(item.itemName))
              .toList()
        : weatherPriceSensitivityDatabase;

    for (final item in targetItems) {
      final sensitivity = item.sensitivity[condition];
      if (sensitivity == null || sensitivity.abs() < minSensitivity) {
        continue; // 민감도가 낮으면 제외
      }

      // 예상 변동률 계산 (민감도 * 기본 변동률 20%)
      final predictedChange = sensitivity * 20.0;

      // 추천 메시지 생성
      final recommendation = _generateRecommendation(
        itemName: item.itemName,
        sensitivity: sensitivity,
        condition: condition,
      );

      predictions.add(
        PricePrediction(
          itemName: item.itemName,
          category: item.category,
          sensitivity: sensitivity,
          predictedChange: predictedChange,
          recommendation: recommendation,
          reason: item.reason,
          weatherCondition: condition,
        ),
      );
    }

    // 민감도 절대값 기준 내림차순 정렬
    predictions.sort((a, b) {
      return b.sensitivity.abs().compareTo(a.sensitivity.abs());
    });

    // 캐시 저장
    _cache.set(cacheKey, predictions);

    return predictions;
  }

  /// 추천 메시지 생성 (한국어)
  static String _generateRecommendation({
    required String itemName,
    required double sensitivity,
    required WeatherCondition condition,
  }) {
    final weatherName = weatherConditionNames[condition] ?? '날씨 변화';

    if (sensitivity >= 0.8) {
      return '🔴 $itemName 가격 급등 예상 ($weatherName) - 빨리 구매하세요!';
    } else if (sensitivity >= 0.5) {
      return '🟡 $itemName 가격 상승 예상 ($weatherName) - 구매 고려하세요';
    } else if (sensitivity >= 0.3) {
      return '🟠 $itemName 가격 소폭 상승 ($weatherName)';
    } else if (sensitivity <= -0.5) {
      return '🟢 $itemName 가격 하락 예상 ($weatherName) - 구매 적기!';
    } else if (sensitivity <= -0.3) {
      return '🔵 $itemName 가격 소폭 하락 ($weatherName)';
    } else {
      return '⚪ $itemName 가격 안정적';
    }
  }

  /// 카테고리별 가격 변동 요약
  ///
  /// 예: "채소류 평균 +15% 예상"
  static Map<PriceCategory, double> summarizeByCategory(
    List<PricePrediction> predictions,
  ) {
    final categoryChanges = <PriceCategory, List<double>>{};

    for (final prediction in predictions) {
      categoryChanges.putIfAbsent(prediction.category, () => []);
      categoryChanges[prediction.category]!.add(prediction.predictedChange);
    }

    return categoryChanges.map((category, changes) {
      final average = changes.reduce((a, b) => a + b) / changes.length;
      return MapEntry(category, average);
    });
  }

  /// 구매 추천 품목 (가격 하락 예상)
  ///
  /// 지금 사면 저렴한 품목들
  static List<PricePrediction> getBuyRecommendations(
    List<PricePrediction> predictions, {
    int limit = 5,
  }) {
    final buyList = predictions.where((p) => p.isPriceDecreasing).toList();
    buyList.sort((a, b) => a.predictedChange.compareTo(b.predictedChange));
    return buyList.take(limit).toList();
  }

  /// 구매 보류 추천 품목 (가격 상승 예상)
  ///
  /// 지금 사면 비싼 품목들
  static List<PricePrediction> getAvoidRecommendations(
    List<PricePrediction> predictions, {
    int limit = 5,
  }) {
    final avoidList = predictions.where((p) => p.isPriceIncreasing).toList();
    avoidList.sort((a, b) => b.predictedChange.compareTo(a.predictedChange));
    return avoidList.take(limit).toList();
  }

  /// 음성 비서용 요약 메시지 생성
  ///
  /// 예: "장마철입니다. 배추 가격이 18% 상승 예상됩니다.
  ///      지금 사과는 가격이 6% 하락 예상이니 구매 적기입니다."
  static String generateVoiceSummary({
    required WeatherData weather,
    required List<PricePrediction> predictions,
    int maxItems = 3,
  }) {
    final weatherName =
        weatherConditionNames[weather.effectiveCondition] ?? '현재 날씨';
    final buffer = StringBuffer('$weatherName입니다. ');

    // 가격 상승 품목
    final rising = getAvoidRecommendations(predictions, limit: maxItems);
    if (rising.isNotEmpty) {
      final risingText = rising
          .map((p) {
            return '${p.itemName}은 ${p.predictedChange.toStringAsFixed(0)}% 상승 예상';
          })
          .join(', ');
      buffer.write('$risingText입니다. ');
    }

    // 가격 하락 품목 (구매 추천)
    final falling = getBuyRecommendations(predictions, limit: maxItems);
    if (falling.isNotEmpty) {
      final fallingText = falling
          .map((p) {
            return '${p.itemName}은 ${p.predictedChange.abs().toStringAsFixed(0)}% 하락';
          })
          .join(', ');
      buffer.write('지금 $fallingText 예상이니 구매 적기입니다.');
    }

    return buffer.toString();
  }

  /// 캐시 초기화
  static void clearCache() {
    _cache.clear();
  }

  /// 날씨 조건 문자열을 열거형으로 변환
  ///
  /// 음성 비서나 외부 API에서 받은 문자열을 파싱
  static WeatherCondition? parseWeatherCondition(String condition) {
    final normalized = condition.toLowerCase().trim();

    if (normalized.contains('맑') ||
        normalized == 'sunny' ||
        normalized == 'clear') {
      return WeatherCondition.sunny;
    } else if (normalized.contains('흐') || normalized == 'cloudy') {
      return WeatherCondition.cloudy;
    } else if (normalized.contains('폭우') ||
        normalized.contains('장마') ||
        normalized == 'heavy_rain') {
      return WeatherCondition.heavyRain;
    } else if (normalized.contains('비') ||
        normalized == 'rainy' ||
        normalized == 'rain') {
      return WeatherCondition.rainy;
    } else if (normalized.contains('눈') ||
        normalized == 'snowy' ||
        normalized == 'snow') {
      return WeatherCondition.snowy;
    } else if (normalized.contains('태풍') || normalized == 'typhoon') {
      return WeatherCondition.typhoon;
    } else if (normalized.contains('한파') || normalized == 'cold_wave') {
      return WeatherCondition.coldWave;
    } else if (normalized.contains('폭염') || normalized == 'heat_wave') {
      return WeatherCondition.heatWave;
    }

    return null;
  }

  /// 온도로 날씨 조건 추론 (한파/폭염)
  static WeatherCondition inferConditionFromTemperature(
    double temperature,
    WeatherCondition baseCondition,
  ) {
    if (temperature <= -10) {
      return WeatherCondition.coldWave;
    } else if (temperature >= 33) {
      return WeatherCondition.heatWave;
    }
    return baseCondition;
  }

  /// 디버그용: 모든 민감도 데이터 출력
  @visibleForTesting
  static void printAllSensitivity() {
    for (final category in PriceCategory.values) {
      debugPrint('\n========== ${priceCategoryNames[category]} ==========');
      final items = getWeatherSensitivityByCategory(category);
      for (final item in items) {
        debugPrint('${item.itemName}:');
        for (final entry in item.sensitivity.entries) {
          debugPrint('  ${weatherConditionNames[entry.key]}: ${entry.value}');
        }
        debugPrint('  이유: ${item.reason}');
      }
    }
  }
}
