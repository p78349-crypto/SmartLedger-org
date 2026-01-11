import 'dart:async';

import '../models/visit_price_entry.dart';
import '../utils/price_correction_utils.dart';
import 'visit_price_repository.dart';

/// 가격 보정 결과를 이벤트 기반으로 제공하는 서비스
class PriceCorrectionService {
  PriceCorrectionService._();

  static final PriceCorrectionService instance = PriceCorrectionService._();

  Stream<PriceCorrectionResult> watchEffectivePrice({
    required VisitPriceEntry baseline,
    WeatherPriceAdjustment? weatherAdjustment,
    Duration recentWindow = PriceCorrectionUtils.defaultRecentWindow,
    VisitPriceRepository? repository,
  }) {
    final repo = repository ?? VisitPriceRepository.instance;
    StreamSubscription<VisitPriceEvent>? subscription;
    late final StreamController<PriceCorrectionResult> controller;

    controller = StreamController<PriceCorrectionResult>.broadcast(
      onListen: () {
        final initial = PriceCorrectionUtils.calculateEffectivePrice(
          baseline: baseline,
          storeId: baseline.storeId,
          skuId: baseline.skuId,
          recentWindow: recentWindow,
          weatherAdjustment: weatherAdjustment,
          repository: repo,
        );
        controller.add(initial);

        subscription = repo.events.listen((event) {
          if (event.entry.storeId != baseline.storeId ||
              event.entry.skuId != baseline.skuId) {
            return;
          }
          final recalculated = PriceCorrectionUtils.calculateEffectivePrice(
            baseline: baseline,
            storeId: baseline.storeId,
            skuId: baseline.skuId,
            recentWindow: recentWindow,
            weatherAdjustment: weatherAdjustment,
            repository: repo,
          );
          controller.add(recalculated);
        });
      },
      onCancel: () async {
        await subscription?.cancel();
        await controller.close();
      },
    );

    return controller.stream;
  }

  String buildFeedbackMessage(PriceCorrectionResult result) {
    final reference = result.referenceEntry;
    final baseline = result.baselineEntry;
    final referencePrice = reference.effectiveUnitPrice.round();
    final baselinePrice = baseline.effectiveUnitPrice.round();
    final difference = referencePrice - baselinePrice;
    final weatherInfo = result.weatherAdjustment;

    final buffer = StringBuffer();
    if (result.usedUserContribution) {
      buffer.writeln('실방문 단가 $referencePrice원으로 업데이트했어요.');
    } else {
      buffer.writeln('공시가 $baselinePrice원을 유지합니다.');
    }

    if (difference != 0) {
      final sign = difference > 0 ? '+' : '';
      buffer.writeln('공시가 대비 $sign$difference원 변동되었습니다.');
    }

    if (weatherInfo != null && weatherInfo.multiplier != 1.0) {
      final weatherDelta = result.finalUnitPrice.round() - referencePrice;
      if (weatherDelta != 0) {
        final sign = weatherDelta > 0 ? '+' : '';
        buffer.writeln('날씨 영향: ${weatherInfo.reason} ($sign$weatherDelta원)');
      }
    }

    buffer.writeln('최종 추정가 ${result.finalUnitPrice.round()}원');
    return buffer.toString().trim();
  }
}
