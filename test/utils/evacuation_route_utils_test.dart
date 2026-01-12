import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/evacuation_route_utils.dart';
import 'package:smart_ledger/utils/weather_price_sensitivity.dart';
import 'package:smart_ledger/utils/weather_utils.dart';

void main() {
  group('EvacuationRoutePlanner', () {
    test('generatePlan uses region config when location matches', () {
      final weather = WeatherData(
        condition: WeatherCondition.typhoon,
        temperature: 26,
        humidity: 85,
        timestamp: DateTime(2026),
        location: 'Miami Beach',
      );

      final plan = EvacuationRoutePlanner.generatePlan(weather: weather, familySize: 3);

      expect(plan.condition, WeatherCondition.typhoon);
      expect(plan.adviceLevel, EvacuationAdviceLevel.evacuate);
      expect(plan.routes, isNotEmpty);
      expect(plan.routes.any((r) => r.shelterAddress.contains('Miami')), isTrue);
      expect(plan.familySize, 3);
      expect(plan.safetyMessage, contains('대피 권고'));

      // With current keyword ordering, 'miami' is treated as urban.
      expect(plan.environmentAdvisory, isNotNull);
      expect(plan.environmentAdvisory, contains('도심'));
    });

    test('generatePlan falls back to default routes when region not detected', () {
      final weather = WeatherData(
        condition: WeatherCondition.snowy,
        temperature: -1,
        humidity: 60,
        timestamp: DateTime(2026),
        location: 'UnknownTown',
      );

      final plan = EvacuationRoutePlanner.generatePlan(weather: weather);
      expect(plan.routes, isNotEmpty);
      expect(plan.routes.first.safetyLevel, EvacuationSafetyLevel.primary);
      expect(plan.checkpoints, isNotEmpty);
    });
  });
}
