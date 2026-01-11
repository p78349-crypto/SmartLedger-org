import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/weather_capture_utils.dart';

void main() {
  test('shouldCaptureToday returns true when lastCaptureDate is null', () {
    expect(WeatherCaptureUtils.shouldCaptureToday(null), isTrue);
  });

  test('shouldCaptureToday returns false when same day', () {
    final now = DateTime.now();
    expect(WeatherCaptureUtils.shouldCaptureToday(now), isFalse);
  });

  test('getWeatherIcon and color return expected values', () {
    expect(WeatherCaptureUtils.getWeatherIcon('맑음'), isA<IconData>());
    expect(
      WeatherCaptureUtils.getWeatherColor('맑음').value,
      Colors.orange.shade300.value,
    );
    expect(
      WeatherCaptureUtils.getWeatherColor('비').value,
      Colors.blue.shade300.value,
    );
  });

  test('captureWeather completes and returns a snapshot', () {
    fakeAsync((async) {
      WeatherSnapshot? result;
      WeatherCaptureUtils.captureWeather(isAuto: true).then((v) => result = v);

      async.elapse(const Duration(milliseconds: 1500));
      async.flushMicrotasks();

      expect(result, isNotNull);
      expect(result!.source, 'auto');
      expect(result!.tempC, inInclusiveRange(20.0, 29.0));
      expect(['맑음', '흐림', '비', '눈'], contains(result!.condition));
    });
  });
}
