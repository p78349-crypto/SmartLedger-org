import '../models/visit_price_entry.dart';
import '../services/visit_price_repository.dart';

/// 날씨/사용자 데이터를 결합한 가격 보정 결과
class PriceCorrectionResult {
  final double finalUnitPrice;
  final String currency;
  final VisitPriceEntry referenceEntry;
  final VisitPriceEntry baselineEntry;
  final WeatherPriceAdjustment? weatherAdjustment;

  const PriceCorrectionResult({
    required this.finalUnitPrice,
    required this.currency,
    required this.referenceEntry,
    required this.baselineEntry,
    this.weatherAdjustment,
  });

  /// 사용자 데이터 기준 변동률 (baseline 대비)
  double get userDeltaPercent {
    final baselinePrice = baselineEntry.effectiveUnitPrice;
    if (baselinePrice == 0) return 0;
    return ((referenceEntry.effectiveUnitPrice - baselinePrice) / baselinePrice) * 100;
  }

  /// 날씨 보정까지 포함한 최종 변동률 (baseline 대비)
  double get finalDeltaPercent {
    final baselinePrice = baselineEntry.effectiveUnitPrice;
    if (baselinePrice == 0) return 0;
    return ((finalUnitPrice - baselinePrice) / baselinePrice) * 100;
  }

  bool get usedUserContribution =>
      referenceEntry.source == VisitPriceSource.userReceipt ||
      referenceEntry.source == VisitPriceSource.crowdContribution;
}

/// 날씨 기반 가격 보정 파라미터
class WeatherPriceAdjustment {
  final double multiplier; // 0~n (1.0 = 영향 없음)
  final String reason;
  final DateTime generatedAt;

  const WeatherPriceAdjustment({
    required this.multiplier,
    required this.reason,
    required this.generatedAt,
  });

  double apply(double value) => value * multiplier;

  WeatherPriceAdjustment copyWith({
    double? multiplier,
    String? reason,
    DateTime? generatedAt,
  }) {
    return WeatherPriceAdjustment(
      multiplier: multiplier ?? this.multiplier,
      reason: reason ?? this.reason,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

/// 가격 보정 유틸리티 (공시가 + 실방문 데이터 + 날씨)
class PriceCorrectionUtils {
  PriceCorrectionUtils._();

  static const Duration defaultRecentWindow = Duration(days: 7);

  /// 실방문 가격과 날씨 지수를 결합해 오늘 예상 단가를 계산합니다.
  static PriceCorrectionResult calculateEffectivePrice({
    required VisitPriceEntry baseline,
    required String storeId,
    required String skuId,
    Duration recentWindow = defaultRecentWindow,
    WeatherPriceAdjustment? weatherAdjustment,
    VisitPriceRepository? repository,
  }) {
    final repo = repository ?? VisitPriceRepository.instance;
    final recentEntries = repo.getRecentEntries(
      skuId: skuId,
      storeId: storeId,
      within: recentWindow,
    );

    final referenceEntry = _pickReferenceEntry(baseline, recentEntries);
    final weatherAdjustedPrice = weatherAdjustment?.apply(referenceEntry.effectiveUnitPrice) ??
        referenceEntry.effectiveUnitPrice;

    return PriceCorrectionResult(
      finalUnitPrice: _roundToWon(weatherAdjustedPrice),
      currency: referenceEntry.currency,
      referenceEntry: referenceEntry,
      baselineEntry: baseline,
      weatherAdjustment: weatherAdjustment,
    );
  }

  static VisitPriceEntry _pickReferenceEntry(
    VisitPriceEntry baseline,
    List<VisitPriceEntry> recentEntries,
  ) {
    if (recentEntries.isEmpty) {
      return baseline;
    }

    // 우선순위: 사용자 > 크라우드 > 공시 + 최신성
    recentEntries.sort((a, b) {
      final sourceScore = _priorityValue(b.source).compareTo(_priorityValue(a.source));
      if (sourceScore != 0) return sourceScore;
      return b.capturedAt.compareTo(a.capturedAt);
    });

    final latest = recentEntries.firstWhere(
      (entry) => !entry.discount.isExpired,
      orElse: () => recentEntries.first,
    );

    return latest;
  }

  static int _priorityValue(VisitPriceSource source) {
    switch (source) {
      case VisitPriceSource.userReceipt:
        return 3;
      case VisitPriceSource.crowdContribution:
        return 2;
      case VisitPriceSource.officialBaseline:
        return 1;
    }
  }

  static double _roundToWon(double value) {
    if (value == 0) return 0;
    return (value / 10).round() * 10; // 10원 단위 반올림
  }

  /// 날씨 인덱스와 사용자 보정치를 포맷해 UI에 전달할 요약 메시지 생성
  static String buildSummary(PriceCorrectionResult result) {
    final buffer = StringBuffer();
    final ref = result.referenceEntry;
    final baseline = result.baselineEntry;

    final baselinePrice = baseline.effectiveUnitPrice;
    final refPrice = ref.effectiveUnitPrice;
    final delta = refPrice - baselinePrice;

    if (result.usedUserContribution) {
      buffer.writeln('실방문 최신가 ${_formatWon(refPrice)} (${_formatDelta(delta)})');
    } else {
      buffer.writeln('공시가 기준 ${_formatWon(refPrice)}');
    }

    final weatherAdjustment = result.weatherAdjustment;
    if (weatherAdjustment != null && weatherAdjustment.multiplier != 1.0) {
      final weatherDelta = result.finalUnitPrice - refPrice;
      buffer.writeln('날씨 영향: ${weatherAdjustment.reason} (${_formatDelta(weatherDelta)})');
    }

    buffer.writeln('최종 추정가: ${_formatWon(result.finalUnitPrice)}');
    return buffer.toString().trim();
  }

  static String _formatWon(double value) {
    final absValue = value.abs();
    final formatted = absValue >= 1000
        ? _thousandsSeparator(absValue.round())
        : absValue.round().toString();
    return value < 0 ? '-$formatted원' : '$formatted원';
  }

  static String _thousandsSeparator(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      final index = str.length - i;
      buffer.write(str[i]);
      if (index > 1 && index % 3 == 1 && i != str.length - 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  static String _formatDelta(double delta) {
    final sign = delta > 0 ? '+' : '';
    return '$sign${delta.round()}원';
  }
}
