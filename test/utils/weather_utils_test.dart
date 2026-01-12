import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/weather_price_sensitivity.dart';
import 'package:smart_ledger/utils/weather_utils.dart';

void main() {
  group('WeatherData', () {
    test('effectiveCondition prioritizes cold/heat waves by temperature', () {
      final cold = WeatherData(
        condition: WeatherCondition.sunny,
        temperature: -10,
        humidity: 50,
        timestamp: DateTime(2026),
        location: 'Seoul',
      );
      expect(cold.isColdWave, isTrue);
      expect(cold.effectiveCondition, WeatherCondition.coldWave);

      final hot = WeatherData(
        condition: WeatherCondition.rainy,
        temperature: 33,
        humidity: 50,
        timestamp: DateTime(2026),
        location: 'Seoul',
      );
      expect(hot.isHeatWave, isTrue);
      expect(hot.effectiveCondition, WeatherCondition.heatWave);

      final normal = WeatherData(
        condition: WeatherCondition.cloudy,
        temperature: 20,
        humidity: 50,
        timestamp: DateTime(2026),
        location: 'Seoul',
      );
      expect(normal.isColdWave, isFalse);
      expect(normal.isHeatWave, isFalse);
      expect(normal.effectiveCondition, WeatherCondition.cloudy);
    });
  });

  group('WeatherUtils', () {
    setUp(WeatherUtils.clearCache);

    test('parseWeatherCondition recognizes Korean/English inputs', () {
      expect(WeatherUtils.parseWeatherCondition('맑음'), WeatherCondition.sunny);
      expect(WeatherUtils.parseWeatherCondition('clear'), WeatherCondition.sunny);
      expect(WeatherUtils.parseWeatherCondition('cloudy'), WeatherCondition.cloudy);
      expect(WeatherUtils.parseWeatherCondition('폭우'), WeatherCondition.heavyRain);
      expect(WeatherUtils.parseWeatherCondition('rain'), WeatherCondition.rainy);
      expect(WeatherUtils.parseWeatherCondition('snow'), WeatherCondition.snowy);
      expect(WeatherUtils.parseWeatherCondition('typhoon'), WeatherCondition.typhoon);
      expect(WeatherUtils.parseWeatherCondition('cold_wave'), WeatherCondition.coldWave);
      expect(WeatherUtils.parseWeatherCondition('heat_wave'), WeatherCondition.heatWave);
      expect(WeatherUtils.parseWeatherCondition('unknown'), isNull);
    });

    test('inferConditionFromTemperature matches thresholds', () {
      expect(
        WeatherUtils.inferConditionFromTemperature(-10, WeatherCondition.sunny),
        WeatherCondition.coldWave,
      );
      expect(
        WeatherUtils.inferConditionFromTemperature(33, WeatherCondition.rainy),
        WeatherCondition.heatWave,
      );
      expect(
        WeatherUtils.inferConditionFromTemperature(20, WeatherCondition.rainy),
        WeatherCondition.rainy,
      );
    });

    test('predictPriceChanges filters by items and uses cache', () {
      final weather = WeatherData(
        condition: WeatherCondition.typhoon,
        temperature: 25,
        humidity: 80,
        timestamp: DateTime(2026),
        location: 'Seoul',
      );

      final first = WeatherUtils.predictPriceChanges(
        weather: weather,
        items: const ['배추', '사과'],
        minSensitivity: 0.0,
      );
      expect(first, isNotEmpty);
      expect(first.every((p) => p.itemName == '배추' || p.itemName == '사과'), isTrue);
      expect(first.first.recommendation, contains(first.first.itemName));

      final second = WeatherUtils.predictPriceChanges(
        weather: weather,
        items: const ['배추', '사과'],
        minSensitivity: 0.0,
      );

      // Cache returns the exact same list instance.
      expect(identical(first, second), isTrue);
    });

    test('generateVoiceSummary includes weather name and item names', () {
      final weather = WeatherData(
        condition: WeatherCondition.sunny,
        temperature: 20,
        humidity: 30,
        timestamp: DateTime(2026),
        location: 'Seoul',
      );

      final predictions = WeatherUtils.predictPriceChanges(
        weather: weather,
        minSensitivity: 0.1,
      );

      final summary = WeatherUtils.generateVoiceSummary(
        weather: weather,
        predictions: predictions,
        maxItems: 2,
      );

      expect(summary, contains('맑음'));
      // Summary should mention at least one predicted item.
      expect(
        predictions.any((p) => summary.contains(p.itemName)),
        isTrue,
      );
    });
  });
}
