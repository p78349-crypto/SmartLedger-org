import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/weather_snapshot.dart';

void main() {
  group('WeatherSnapshot', () {
    test('creates with required condition', () {
      const snapshot = WeatherSnapshot(condition: 'sunny');

      expect(snapshot.condition, 'sunny');
      expect(snapshot.tempC, isNull);
      expect(snapshot.source, 'manual'); // 기본값
    });

    test('creates with all fields', () {
      final capturedAt = DateTime(2026, 1, 11, 10, 30);
      final snapshot = WeatherSnapshot(
        condition: 'cloudy',
        tempC: 5.2,
        feelsLikeC: 2.1,
        humidityPct: 65,
        windSpeedMs: 3.5,
        precipitation1hMm: 0.0,
        capturedAt: capturedAt,
        lat: 37.5,
        lon: 127.0,
        source: 'api',
      );

      expect(snapshot.condition, 'cloudy');
      expect(snapshot.tempC, 5.2);
      expect(snapshot.feelsLikeC, 2.1);
      expect(snapshot.humidityPct, 65);
      expect(snapshot.windSpeedMs, 3.5);
      expect(snapshot.precipitation1hMm, 0.0);
      expect(snapshot.capturedAt, capturedAt);
      expect(snapshot.lat, 37.5);
      expect(snapshot.lon, 127.0);
      expect(snapshot.source, 'api');
    });

    group('toJson', () {
      test('serializes required fields', () {
        const snapshot = WeatherSnapshot(condition: 'rain');

        final json = snapshot.toJson();

        expect(json['condition'], 'rain');
        expect(json['source'], 'manual');
      });

      test('omits null optional fields', () {
        const snapshot = WeatherSnapshot(condition: 'snow');

        final json = snapshot.toJson();

        expect(json.containsKey('tempC'), isFalse);
        expect(json.containsKey('humidityPct'), isFalse);
        expect(json.containsKey('capturedAt'), isFalse);
        expect(json.containsKey('lat'), isFalse);
      });

      test('includes all set fields', () {
        const snapshot = WeatherSnapshot(
          condition: 'sunny',
          tempC: 20.0,
          humidityPct: 50,
          source: 'api',
        );

        final json = snapshot.toJson();

        expect(json['tempC'], 20.0);
        expect(json['humidityPct'], 50);
        expect(json['source'], 'api');
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'condition': 'cloudy',
          'tempC': 15.5,
          'feelsLikeC': 13.0,
          'humidityPct': 70,
          'windSpeedMs': 2.5,
          'precipitation1hMm': 0.5,
          'capturedAt': '2026-01-11T12:00:00.000',
          'lat': 37.5665,
          'lon': 126.978,
          'source': 'api',
        };

        final snapshot = WeatherSnapshot.fromJson(json);

        expect(snapshot.condition, 'cloudy');
        expect(snapshot.tempC, 15.5);
        expect(snapshot.feelsLikeC, 13.0);
        expect(snapshot.humidityPct, 70);
        expect(snapshot.windSpeedMs, 2.5);
        expect(snapshot.precipitation1hMm, 0.5);
        expect(snapshot.capturedAt, isNotNull);
        expect(snapshot.lat, 37.5665);
        expect(snapshot.lon, 126.978);
        expect(snapshot.source, 'api');
      });

      test('handles missing optional fields', () {
        final json = {
          'condition': 'sunny',
        };

        final snapshot = WeatherSnapshot.fromJson(json);

        expect(snapshot.condition, 'sunny');
        expect(snapshot.tempC, isNull);
        expect(snapshot.source, 'manual');
      });

      test('handles int values as proper types', () {
        final json = {
          'condition': 'rain',
          'tempC': 10, // int
          'humidityPct': 80, // int
          'lat': 38, // int
        };

        final snapshot = WeatherSnapshot.fromJson(json);

        expect(snapshot.tempC, 10.0);
        expect(snapshot.humidityPct, 80);
        expect(snapshot.lat, 38.0);
      });

      test('defaults condition to empty string when null', () {
        final json = <String, dynamic>{};

        final snapshot = WeatherSnapshot.fromJson(json);

        expect(snapshot.condition, '');
      });
    });

    test('serialization roundtrip preserves data', () {
      final original = WeatherSnapshot(
        condition: 'sunny',
        tempC: 25.3,
        feelsLikeC: 27.0,
        humidityPct: 45,
        windSpeedMs: 1.2,
        capturedAt: DateTime(2026, 1, 11, 14, 30),
        lat: 37.5,
        lon: 127.0,
        source: 'api',
      );

      final json = original.toJson();
      final restored = WeatherSnapshot.fromJson(json);

      expect(restored.condition, original.condition);
      expect(restored.tempC, original.tempC);
      expect(restored.feelsLikeC, original.feelsLikeC);
      expect(restored.humidityPct, original.humidityPct);
      expect(restored.windSpeedMs, original.windSpeedMs);
      expect(restored.lat, original.lat);
      expect(restored.lon, original.lon);
      expect(restored.source, original.source);
    });
  });
}
