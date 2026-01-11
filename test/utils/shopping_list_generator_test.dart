import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/shopping_list_generator.dart';
import 'package:smart_ledger/utils/weather_price_sensitivity.dart';
import 'package:smart_ledger/widgets/weather_alert_widget.dart';

void main() {
  group('ShoppingListGenerator', () {
    test('returns empty list when weather is not extreme', () {
      final forecast = WeatherForecast(
        condition: WeatherCondition.sunny,
        forecastDate: DateTime(2026, 1, 1),
        daysUntil: 1,
        temperature: 10,
        location: 'Seoul',
        confidence: 0.9,
      );

      final result = ShoppingListGenerator.generateShoppingList(
        forecast: forecast,
        familySize: 2,
      );

      expect(result.items, isEmpty);
      expect(result.totalCost, 0);
      expect(result.potentialSavings, 0);
      expect(result.urgentMessage, contains('정상 날씨'));
    });

    test('generates items and adjusts quantities by family size', () {
      final forecast = WeatherForecast(
        condition: WeatherCondition.typhoon,
        forecastDate: DateTime(2026, 1, 1),
        daysUntil: 1,
        temperature: 20,
        location: 'Busan',
        confidence: 0.8,
      );

      final result = ShoppingListGenerator.generateShoppingList(
        forecast: forecast,
        familySize: 4,
      );

      expect(result.items, isNotEmpty);
      expect(result.totalCost, greaterThan(0));

      // Typhoon DB includes water + safety items.
      final water = result.items.firstWhere((i) => i.name == '생수');
      expect(water.category, PrepCategory.water);
      expect(water.quantity, 40); // 20 * 4 / 2

      final flashlight = result.items.firstWhere((i) => i.name == '손전등');
      expect(flashlight.category, PrepCategory.safety);
      expect(flashlight.quantity, 2); // safety category is fixed

      expect(result.urgentItems.any((i) => i.isUrgent), isTrue);

      // Total cost should equal sum of each item totalCost.
      final sum = result.items.fold<int>(0, (s, item) => s + item.totalCost);
      expect(result.totalCost, sum);
    });

    test('formatPrice uses thousands separators', () {
      expect(ShoppingListGenerator.formatPrice(1234567), '1,234,567');
    });
  });
}
