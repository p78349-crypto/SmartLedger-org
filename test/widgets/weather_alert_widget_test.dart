import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/weather_price_sensitivity.dart';
import 'package:smart_ledger/widgets/weather_alert_widget.dart';

void main() {
  group('isExtremeWeather', () {
    test('returns true for typhoon', () {
      expect(isExtremeWeather(WeatherCondition.typhoon), isTrue);
    });

    test('returns true for coldWave', () {
      expect(isExtremeWeather(WeatherCondition.coldWave), isTrue);
    });

    test('returns true for heavyRain', () {
      expect(isExtremeWeather(WeatherCondition.heavyRain), isTrue);
    });

    test('returns true for heatWave', () {
      expect(isExtremeWeather(WeatherCondition.heatWave), isTrue);
    });

    test('returns false for sunny', () {
      expect(isExtremeWeather(WeatherCondition.sunny), isFalse);
    });

    test('returns false for cloudy', () {
      expect(isExtremeWeather(WeatherCondition.cloudy), isFalse);
    });

    test('returns false for rainy', () {
      expect(isExtremeWeather(WeatherCondition.rainy), isFalse);
    });

    test('returns false for snowy', () {
      expect(isExtremeWeather(WeatherCondition.snowy), isFalse);
    });
  });

  group('getWeatherRiskLevel', () {
    test('typhoon is critical', () {
      expect(getWeatherRiskLevel(WeatherCondition.typhoon), WeatherRiskLevel.critical);
    });

    test('coldWave is high', () {
      expect(getWeatherRiskLevel(WeatherCondition.coldWave), WeatherRiskLevel.high);
    });

    test('heavyRain is high', () {
      expect(getWeatherRiskLevel(WeatherCondition.heavyRain), WeatherRiskLevel.high);
    });

    test('heatWave is medium', () {
      expect(getWeatherRiskLevel(WeatherCondition.heatWave), WeatherRiskLevel.medium);
    });

    test('snowy is medium', () {
      expect(getWeatherRiskLevel(WeatherCondition.snowy), WeatherRiskLevel.medium);
    });

    test('sunny is low', () {
      expect(getWeatherRiskLevel(WeatherCondition.sunny), WeatherRiskLevel.low);
    });

    test('cloudy is low', () {
      expect(getWeatherRiskLevel(WeatherCondition.cloudy), WeatherRiskLevel.low);
    });
  });

  group('PrepItem', () {
    test('creates with all fields', () {
      const item = PrepItem(
        name: '생수',
        category: PrepCategory.water,
        reason: '단수 대비',
        quantity: 20,
        unit: '리터',
        daysNeeded: 3,
      );

      expect(item.name, '생수');
      expect(item.category, PrepCategory.water);
      expect(item.reason, '단수 대비');
      expect(item.quantity, 20);
      expect(item.unit, '리터');
      expect(item.daysNeeded, 3);
    });
  });

  group('weatherPrepDatabase', () {
    test('typhoon has prep items', () {
      final items = weatherPrepDatabase[WeatherCondition.typhoon];
      expect(items, isNotNull);
      expect(items, isNotEmpty);
    });

    test('coldWave has prep items', () {
      final items = weatherPrepDatabase[WeatherCondition.coldWave];
      expect(items, isNotNull);
      expect(items, isNotEmpty);
    });

    test('prep items have required fields', () {
      for (final entry in weatherPrepDatabase.entries) {
        for (final item in entry.value) {
          expect(item.name, isNotEmpty);
          expect(item.quantity, greaterThan(0));
          expect(item.unit, isNotEmpty);
          expect(item.daysNeeded, greaterThan(0));
        }
      }
    });
  });

  group('WeatherRiskLevel', () {
    test('has all expected values', () {
      expect(WeatherRiskLevel.values, contains(WeatherRiskLevel.low));
      expect(WeatherRiskLevel.values, contains(WeatherRiskLevel.medium));
      expect(WeatherRiskLevel.values, contains(WeatherRiskLevel.high));
      expect(WeatherRiskLevel.values, contains(WeatherRiskLevel.critical));
    });
  });

  group('PrepCategory', () {
    test('has all expected values', () {
      expect(PrepCategory.values, contains(PrepCategory.safety));
      expect(PrepCategory.values, contains(PrepCategory.freshFood));
      expect(PrepCategory.values, contains(PrepCategory.storableFood));
      expect(PrepCategory.values, contains(PrepCategory.medicine));
      expect(PrepCategory.values, contains(PrepCategory.energy));
      expect(PrepCategory.values, contains(PrepCategory.water));
    });
  });
}
