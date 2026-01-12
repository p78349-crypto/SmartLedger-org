import 'package:flutter/foundation.dart';
import 'weather_price_sensitivity.dart';
import 'cache_utils.dart';

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

  bool get isColdWave => temperature <= -10;

  bool get isHeatWave => temperature >= 33;

  WeatherCondition get effectiveCondition {
    if (isColdWave) return WeatherCondition.coldWave;
    if (isHeatWave) return WeatherCondition.heatWave;
    return condition;
  }

  @override
  String toString() {
    return 'WeatherData('
        'condition: ${weatherConditionNames[effectiveCondition]}, '
        'temp: $temperature°C, '
        'humidity: $humidity%, '
        'location: $location'
        ')';
  }
}

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

  bool get isPriceIncreasing => predictedChange > 0;

  bool get isPriceDecreasing => predictedChange < 0;

  bool get isSignificantChange => predictedChange.abs() >= 10.0;

  @override
  String toString() {
    final sign = predictedChange > 0 ? '+' : '';
    final percent = '${predictedChange.toStringAsFixed(1)}%';
    return 'PricePrediction('
        '$itemName: '
        '$sign$percent, '
        '$recommendation'
        ')';
  }
}

class WeatherUtils {
  static final _cache = SimpleCache<String, List<PricePrediction>>(
    maxAge: const Duration(minutes: 5),
  );

  static List<PricePrediction> predictPriceChanges({
    required WeatherData weather,
    List<String>? items,
    double minSensitivity = 0.3,
  }) {
    final cacheKey =
        '${weather.effectiveCondition}_'
        '${items?.join(',') ?? 'all'}_'
        '$minSensitivity';
    final cached = _cache.get(cacheKey);
    if (cached != null) {
      return cached;
    }

    final predictions = <PricePrediction>[];
    final condition = weather.effectiveCondition;

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

      final predictedChange = sensitivity * 20.0;

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

    predictions.sort((a, b) {
      return b.sensitivity.abs().compareTo(a.sensitivity.abs());
    });

    _cache.set(cacheKey, predictions);

    return predictions;
  }

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

  static List<PricePrediction> getBuyRecommendations(
    List<PricePrediction> predictions, {
    int limit = 5,
  }) {
    final buyList = predictions.where((p) => p.isPriceDecreasing).toList();
    buyList.sort((a, b) => a.predictedChange.compareTo(b.predictedChange));
    return buyList.take(limit).toList();
  }

  static List<PricePrediction> getAvoidRecommendations(
    List<PricePrediction> predictions, {
    int limit = 5,
  }) {
    final avoidList = predictions.where((p) => p.isPriceIncreasing).toList();
    avoidList.sort((a, b) => b.predictedChange.compareTo(a.predictedChange));
    return avoidList.take(limit).toList();
  }

  static String generateVoiceSummary({
    required WeatherData weather,
    required List<PricePrediction> predictions,
    int maxItems = 3,
  }) {
    final weatherName =
        weatherConditionNames[weather.effectiveCondition] ?? '현재 날씨';
    final buffer = StringBuffer('$weatherName입니다. ');

    final rising = getAvoidRecommendations(predictions, limit: maxItems);
    if (rising.isNotEmpty) {
      final risingText = rising
          .map((p) {
            final percent = p.predictedChange.toStringAsFixed(0);
            return '${p.itemName}은 $percent% 상승 예상';
          })
          .join(', ');
      buffer.write('$risingText입니다. ');
    }

    final falling = getBuyRecommendations(predictions, limit: maxItems);
    if (falling.isNotEmpty) {
      final fallingText = falling
          .map((p) {
            final percent = p.predictedChange.abs().toStringAsFixed(0);
            return '${p.itemName}은 $percent% 하락';
          })
          .join(', ');
      buffer.write('지금 $fallingText 예상이니 구매 적기입니다.');
    }

    return buffer.toString();
  }

  static void clearCache() {
    _cache.clear();
  }

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
