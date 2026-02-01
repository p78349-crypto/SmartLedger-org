import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/shopping_workflow_utils.dart';
import 'package:smart_ledger/utils/smart_ledger_integration_utils.dart';
import 'package:smart_ledger/utils/weather_capture_utils.dart';

void main() {
  test('SmartLedgerIntegrationUtils stats and report are consistent', () {
    final startedAt = DateTime(2026, 1, 11, 9);
    final weather = WeatherSnapshot(
      condition: '맑음',
      tempC: 25,
      capturedAt: startedAt,
      source: 'auto',
    );

    final session = SmartLedgerSession(
      sessionId: 's1',
      startedAt: startedAt,
      weather: weather,
      cartItems: [
        CartItem(
          id: 'c1',
          name: '우유',
          quantity: '2',
          estimatedPrice: '2500',
          isChecked: true,
        ),
        CartItem(id: 'c2', name: '빵', estimatedPrice: '3000'),
      ],
      transactions: [
        Transaction(
          id: 't1',
          type: TransactionType.expense,
          description: '우유',
          amount: 5000,
          date: startedAt,
          quantity: 2,
          unitPrice: 2500,
          mainCategory: '식비',
        ),
      ],
    );

    final stats = SmartLedgerIntegrationUtils.getSessionStatistics(session);
    expect(stats.totalItems, 2);
    expect(stats.checkedItems, 1);
    expect(stats.totalCartAmount, 8000);
    expect(stats.transactionCount, 1);
    expect(stats.totalSpent, 5000);
    expect(stats.weather.condition, '맑음');

    final report = SmartLedgerIntegrationUtils.generateSessionReport(session);
    expect(report, contains('Smart Ledger 세션 리포트'));
    expect(report, contains('우유'));
    expect(report, contains('🌤️ 오늘의 날씨'));
  });
}
