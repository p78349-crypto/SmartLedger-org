import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/visit_price_entry.dart';
import 'package:smart_ledger/services/visit_price_repository.dart';
import 'package:smart_ledger/utils/price_correction_utils.dart';

void main() {
  group('PriceCorrectionUtils', () {
    test('uses baseline when no recent entries exist', () {
      final baseline = VisitPriceEntry.create(
        skuId: 'sku_test_baseline_only',
        storeId: 'store_test_baseline_only',
        regionCode: 'KR-11',
        unitPrice: 1234,
        currency: 'KRW',
        source: VisitPriceSource.officialBaseline,
        capturedAt: DateTime(2026, 1, 1),
      );

      final result = PriceCorrectionUtils.calculateEffectivePrice(
        baseline: baseline,
        storeId: baseline.storeId,
        skuId: baseline.skuId,
        repository: VisitPriceRepository.instance,
      );

      expect(result.referenceEntry.id, baseline.id);
      // Rounded to the nearest 10 won.
      expect(result.finalUnitPrice, 1230);
      expect(result.currency, 'KRW');
      expect(result.usedUserContribution, isFalse);

      final summary = PriceCorrectionUtils.buildSummary(result);
      expect(summary, contains('공시가 기준'));
      expect(summary, contains('최종 추정가:'));
    });

    test('picks highest-priority non-expired entry and applies weather', () async {
      final skuId = 'sku_test_priority_weather';
      final storeId = 'store_test_priority_weather';

      final baseline = VisitPriceEntry.create(
        skuId: skuId,
        storeId: storeId,
        regionCode: 'KR-11',
        unitPrice: 1000,
        currency: 'KRW',
        source: VisitPriceSource.officialBaseline,
        capturedAt: DateTime(2026, 1, 1),
      );

      // Highest priority but expired discount -> should be skipped.
      final userExpired = VisitPriceEntry.create(
        skuId: skuId,
        storeId: storeId,
        regionCode: 'KR-11',
        unitPrice: 1500,
        currency: 'KRW',
        source: VisitPriceSource.userReceipt,
        discount: DiscountContext(
          type: DiscountType.timeSale,
          multiplier: 0.5,
          label: 'expired',
          expiresAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        capturedAt: DateTime.now().subtract(const Duration(days: 2)),
      );

      final crowd = VisitPriceEntry.create(
        skuId: skuId,
        storeId: storeId,
        regionCode: 'KR-11',
        unitPrice: 1200,
        currency: 'KRW',
        source: VisitPriceSource.crowdContribution,
        discount: DiscountContext.none(),
        capturedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      await VisitPriceRepository.instance.upsert(userExpired);
      await VisitPriceRepository.instance.upsert(crowd);

      final weather = WeatherPriceAdjustment(
        multiplier: 1.1,
        reason: 'test',
        generatedAt: DateTime.now(),
      );

      final result = PriceCorrectionUtils.calculateEffectivePrice(
        baseline: baseline,
        storeId: storeId,
        skuId: skuId,
        repository: VisitPriceRepository.instance,
        weatherAdjustment: weather,
      );

      expect(result.referenceEntry.id, crowd.id);
      expect(result.usedUserContribution, isTrue);
      // 1200 * 1.1 = 1320, already in 10-won increments.
      expect(result.finalUnitPrice, 1320);

      final summary = PriceCorrectionUtils.buildSummary(result);
      expect(summary, contains('실방문 최신가'));
      expect(summary, contains('+200원'));
      expect(summary, contains('날씨 영향'));
      expect(summary, contains('+120원'));
      expect(summary, contains('최종 추정가:'));
    });
  });
}
