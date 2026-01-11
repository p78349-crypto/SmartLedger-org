import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/models/weather_snapshot.dart';
import 'package:smart_ledger/utils/weather_price_prediction_utils.dart';

void main() {
  test('getSeason classifies months correctly', () {
    expect(WeatherPricePredictionUtils.getSeason(DateTime(2026, 3, 1)), Season.spring);
    expect(WeatherPricePredictionUtils.getSeason(DateTime(2026, 6, 1)), Season.summer);
    expect(WeatherPricePredictionUtils.getSeason(DateTime(2026, 9, 1)), Season.autumn);
    expect(WeatherPricePredictionUtils.getSeason(DateTime(2026, 12, 1)), Season.winter);
  });

  test('predictPrice returns a prediction when enough transaction data exists', () {
    final now = DateTime(2026, 1, 11);

    Transaction tx({required int idx, required double unitPrice}) {
      return Transaction(
        id: 't$idx',
        type: TransactionType.expense,
        description: '배추',
        amount: unitPrice,
        date: now.subtract(Duration(days: idx * 5)),
        unitPrice: unitPrice,
        mainCategory: '식비',
        weather: WeatherSnapshot(
          condition: '맑음',
          tempC: 22 + idx.toDouble(),
          precipitation1hMm: 0,
          capturedAt: now.subtract(Duration(days: idx * 5)),
          source: 'api',
        ),
      );
    }

    final transactions = [
      tx(idx: 0, unitPrice: 3000),
      tx(idx: 1, unitPrice: 3100),
      tx(idx: 2, unitPrice: 3050),
      tx(idx: 3, unitPrice: 3200),
      tx(idx: 4, unitPrice: 3150),
    ];

    final currentWeather = WeatherSnapshot(
      condition: '맑음',
      tempC: 32.0,
      precipitation1hMm: 0,
      capturedAt: now,
      source: 'api',
    );

    final prediction = WeatherPricePredictionUtils.predictPrice(
      itemName: '배추',
      transactions: transactions,
      currentWeather: currentWeather,
      targetDate: now.add(const Duration(days: 7)),
    );

    expect(prediction, isNotNull);
    expect(prediction!.itemName, '배추');
    expect(prediction.currentPrice, greaterThan(0));
    expect(prediction.predictedPrice, greaterThan(0));
    expect(prediction.confidence, inInclusiveRange(0.0, 1.0));
  });

  test('generateAlerts returns hot-weather alerts when temp >= 30', () {
    final now = DateTime(2026, 1, 11);
    final alerts = WeatherPricePredictionUtils.generateAlerts(
      transactions: const [],
      currentWeather: WeatherSnapshot(
        condition: '맑음',
        tempC: 33.0,
        capturedAt: now,
        source: 'api',
      ),
    );

    expect(alerts, isNotEmpty);
    expect(alerts.map((a) => a.itemName), contains('배추'));
  });
}
