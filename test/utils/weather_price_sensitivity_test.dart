import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/weather_price_sensitivity.dart';

void main() {
  group('weather_price_sensitivity', () {
    test('name maps cover all enum values', () {
      expect(
        weatherConditionNames.keys.toSet(),
        WeatherCondition.values.toSet(),
      );
      expect(priceCategoryNames.keys.toSet(), PriceCategory.values.toSet());
    });

    test('database has entries with bounded sensitivity values', () {
      expect(weatherPriceSensitivityDatabase, isNotEmpty);
      expect(
        weatherPriceSensitivityDatabase.any((e) => e.itemName == '배추'),
        isTrue,
      );

      for (final entry in weatherPriceSensitivityDatabase) {
        expect(entry.itemName.trim(), isNotEmpty);
        expect(entry.reason.trim(), isNotEmpty);
        expect(entry.sensitivity, isNotEmpty);
        for (final v in entry.sensitivity.values) {
          expect(v, inInclusiveRange(-1.0, 1.0));
        }
      }
    });
  });
}
