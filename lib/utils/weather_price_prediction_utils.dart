/// 날씨 기반 식료품 가격 예측 유틸리티
///
/// 1년 날씨 데이터와 구매 기록을 분석하여 식료품 가격 등락을 예측합니다.
/// - 기온/강수량과 가격의 상관관계 분석
/// - 계절별 가격 패턴 학습
/// - 다음 달 가격 예측 및 알림
library;

import '../models/transaction.dart';
import '../models/weather_snapshot.dart';

part 'weather_price_prediction_utils_models.dart';
part 'weather_price_prediction_utils_data_helpers.dart';
part 'weather_price_prediction_utils_alerts_report.dart';

/// 날씨 기반 가격 예측 유틸리티
class WeatherPricePredictionUtils {
  WeatherPricePredictionUtils._();

  // ========== 공개 상수 데이터 ==========

  static const weatherSensitiveItems = _weatherSensitiveItems;
  static const itemWeatherSensitivity = _itemWeatherSensitivity;
  static const weatherImpactRules = _weatherImpactRules;
  static const seasonalItems = _seasonalItems;

  // ========== 핵심 예측 메서드 ==========

  /// 현재 날씨와 과거 데이터를 기반으로 품목 가격 예측
  static PricePrediction? predictPrice({
    required String itemName,
    required List<Transaction> transactions,
    required WeatherSnapshot currentWeather,
    DateTime? targetDate,
  }) {
    final now = DateTime.now();
    final oneYearAgo = now.subtract(const Duration(days: 365));

    final priceHistory = _extractPriceHistory(
      transactions,
      startDate: oneYearAgo,
    );

    final records = priceHistory[itemName] ?? [];
    if (records.length < 3) return null;

    final recentDate = now.subtract(const Duration(days: 30));
    final recentRecords = records
        .where((r) => r.date.isAfter(recentDate))
        .toList();
    if (recentRecords.isEmpty) return null;

    final currentPrice =
        recentRecords.fold<double>(0, (s, r) => s + r.unitPrice) /
        recentRecords.length;

    var predictedPrice = currentPrice;
    var reason = '';
    final recommendations = <String>[];

    // 1. 날씨 영향 분석
    final sensitivity = _itemWeatherSensitivity[itemName] ?? 0.5;
    final weatherType = _classifyWeather(currentWeather);

    final temp = currentWeather.tempC ?? 20.0;
    if (temp >= 30) {
      final impact = _getWeatherImpact('hot', itemName);
      predictedPrice *= 1 + impact;
      if (impact != 0) {
        reason = '폭염으로 인한 가격 ${impact > 0 ? "상승" : "하락"} 예상';
        if (impact > 0) recommendations.add('지금 구매하시면 좋아요!');
      }
    } else if (temp <= -5) {
      final impact = _getWeatherImpact('cold', itemName);
      predictedPrice *= 1 + impact;
      if (impact != 0) {
        reason = '한파로 인한 가격 ${impact > 0 ? "상승" : "하락"} 예상';
      }
    }

    final precipitation = currentWeather.precipitation1hMm ?? 0;
    if (precipitation > 10 || weatherType == WeatherConditionType.rainy) {
      final impact = _getWeatherImpact('rainy', itemName);
      predictedPrice *= 1 + impact * sensitivity;
      if (impact != 0 && reason.isEmpty) {
        reason = '장마/비로 인한 가격 변동 예상';
      }
    }

    // 2. 계절 영향
    final targetSeason = getSeason(targetDate ?? now);
    final seasonalStats = calculateSeasonalStats(itemName, transactions);
    final seasonStat = seasonalStats
        .where((s) => s.season == targetSeason)
        .firstOrNull;

    if (seasonStat != null && seasonStat.sampleCount >= 3) {
      final seasonalAdjustment = seasonStat.avgPrice / currentPrice;
      if (seasonalAdjustment > 1.1 || seasonalAdjustment < 0.9) {
        predictedPrice *= 1.0 + (seasonalAdjustment - 1.0) * 0.3;
        reason += '\n${getSeasonLabel(targetSeason)} 계절적 가격 변동 반영';
      }
    }

    final changePercent =
        ((predictedPrice - currentPrice) / currentPrice) * 100;
    final trend = changePercent > 5
        ? PriceTrend.rising
        : changePercent < -5
        ? PriceTrend.falling
        : PriceTrend.stable;

    final confidence = _calculateConfidence(
      sampleCount: records.length,
      sensitivity: sensitivity,
      hasWeatherData: records.any((r) => r.weather != null),
    );

    return PricePrediction(
      itemName: itemName,
      predictionDate: targetDate ?? now.add(const Duration(days: 7)),
      currentPrice: currentPrice,
      predictedPrice: predictedPrice,
      trend: trend,
      confidence: confidence,
      reason: reason.isEmpty ? '안정적인 가격 흐름 예상' : reason,
      recommendations: recommendations,
    );
  }

  /// 현재 날씨 기반 가격 알림 생성
  static List<WeatherPriceAlert> generateAlerts({
    required List<Transaction> transactions,
    required WeatherSnapshot currentWeather,
  }) => _generateAlertsImpl(
    transactions: transactions,
    currentWeather: currentWeather,
  );

  /// 품목의 날씨-가격 상관관계 분석
  static WeatherPriceCorrelation? analyzeWeatherCorrelation(
    String itemName,
    List<Transaction> transactions,
  ) {
    final priceHistory = _extractPriceHistory(transactions);
    final records = priceHistory[itemName] ?? [];

    final weatherRecords = records.where((r) => r.weather != null).toList();
    if (weatherRecords.length < 5) return null;

    final temps = weatherRecords.map((r) => r.weather!.tempC ?? 20.0).toList();
    final prices = weatherRecords.map((r) => r.unitPrice).toList();

    final correlation = _calculateCorrelation(temps, prices);
    final category = _getItemCategory(itemName);
    final sensitivity = _itemWeatherSensitivity[itemName] ?? 0.5;

    String explanation;
    if (correlation > 0.3) {
      explanation = '기온이 올라갈수록 $itemName 가격이 상승하는 경향이 있습니다.';
    } else if (correlation < -0.3) {
      explanation = '기온이 올라갈수록 $itemName 가격이 하락하는 경향이 있습니다.';
    } else {
      explanation = '$itemName는 날씨 변화에 비교적 안정적인 가격을 유지합니다.';
    }

    return WeatherPriceCorrelation(
      itemName: itemName,
      category: category,
      correlationCoeff: correlation * sensitivity,
      weatherFactor: WeatherFactorType.temperature,
      explanation: explanation,
    );
  }

  /// 계절별 가격 통계 계산
  static List<SeasonalPriceStat> calculateSeasonalStats(
    String itemName,
    List<Transaction> transactions,
  ) {
    final priceHistory = _extractPriceHistory(transactions);
    final records = priceHistory[itemName] ?? [];
    if (records.isEmpty) return [];

    final seasonGroups = <Season, List<double>>{};
    for (final record in records) {
      final season = _getSeason(record.date);
      seasonGroups.putIfAbsent(season, () => []).add(record.unitPrice);
    }

    return seasonGroups.entries.map((entry) {
      final prices = entry.value;
      final avg = prices.fold<double>(0, (s, p) => s + p) / prices.length;

      return SeasonalPriceStat(
        season: entry.key,
        itemName: itemName,
        avgPrice: avg,
        minPrice: prices.reduce((a, b) => a < b ? a : b),
        maxPrice: prices.reduce((a, b) => a > b ? a : b),
        sampleCount: prices.length,
      );
    }).toList()..sort((a, b) => a.season.index.compareTo(b.season.index));
  }

  /// 제철 식품 추천
  static List<String> getSeasonalRecommendations(DateTime date) {
    return _seasonalItems[date.month] ?? [];
  }

  /// 날씨 종합 리포트 생성
  static String generateWeatherPriceReport({
    required List<Transaction> transactions,
    required WeatherSnapshot currentWeather,
  }) => _generateWeatherPriceReportImpl(
    transactions: transactions,
    currentWeather: currentWeather,
  );

  /// 날짜로부터 계절 판단
  static Season getSeason(DateTime date) => _getSeason(date);

  /// 계절 라벨
  static String getSeasonLabel(Season season) => _getSeasonLabel(season);
}
