import 'dart:math';
import '../models/transaction.dart';
import '../models/asset.dart';
import '../models/ceo_prediction_models.dart';

/// CEO Prediction Helper
/// Provides analytical utilities for executive decision making
class CeoPredictionHelper {
  static const double _minConfidenceThreshold = 0.6;
  static const int _minDataPointsRequired = 30;

  /// Calculates trend velocity from historical data
  static double calculateTrendVelocity(List<double> values) {
    if (values.length < 2) return 0.0;

    double totalChange = 0.0;
    for (int i = 1; i < values.length; i++) {
      totalChange += values[i] - values[i - 1];
    }

    return totalChange / (values.length - 1);
  }

  /// Analyzes seasonal patterns in financial data
  static Map<String, double> analyzeSeasonality(
    List<Transaction> transactions,
    DateTime startDate,
    DateTime endDate,
  ) {
    final monthlyTotals = <int, double>{};

    for (final transaction in transactions) {
      if (transaction.date.isAfter(startDate) &&
          transaction.date.isBefore(endDate)) {
        final month = transaction.date.month;
        monthlyTotals[month] =
            (monthlyTotals[month] ?? 0.0) + transaction.amount;
      }
    }

    final avgMonthly = monthlyTotals.values.isNotEmpty
        ? monthlyTotals.values.reduce((a, b) => a + b) / monthlyTotals.length
        : 0.0;

    return monthlyTotals.map(
      (month, total) =>
          MapEntry(month.toString(), (total - avgMonthly) / avgMonthly),
    );
  }

  /// Calculates confidence level based on data quality
  static double calculateConfidenceLevel(
    int dataPoints,
    double variance,
    double trendStrength,
  ) {
    final dataQuality = min(dataPoints / _minDataPointsRequired, 1.0);
    final stabilityScore = max(0.0, 1.0 - (variance / 10.0));
    final trendReliability = min(trendStrength.abs() / 100.0, 1.0);

    final confidence =
        (dataQuality * 0.4) + (stabilityScore * 0.4) + (trendReliability * 0.2);

    return max(_minConfidenceThreshold, min(1.0, confidence));
  }

  /// Generates risk assessment based on portfolio composition
  static RiskScore assessRiskLevel(
    List<Asset> assets,
    List<Transaction> recentTransactions,
    double cashFlowVolatility,
  ) {
    final liquidity = _calculateLiquidityRisk(assets);
    final market = _calculateMarketRisk(assets);
    final operational = _calculateOperationalRisk(
      recentTransactions,
      cashFlowVolatility,
    );
    final overall = (liquidity + market + operational) / 3.0;

    return RiskScore(
      overall: overall,
      liquidity: liquidity,
      market: market,
      operational: operational,
    );
  }

  static double _calculateLiquidityRisk(List<Asset> assets) {
    if (assets.isEmpty) return 0.8;

    final liquidAssets = assets
        .where(
          (a) =>
              a.category.name.toLowerCase().contains('cash') ||
              a.category.name.toLowerCase().contains('deposit'),
        )
        .length;

    return max(0.0, 1.0 - (liquidAssets / assets.length));
  }

  static double _calculateMarketRisk(List<Asset> assets) {
    final marketAssets = assets
        .where(
          (a) =>
              a.category.name.toLowerCase().contains('stock') ||
              a.category.name.toLowerCase().contains('crypto'),
        )
        .length;

    return min(1.0, marketAssets / max(assets.length, 1) * 1.5);
  }

  static double _calculateOperationalRisk(
    List<Transaction> transactions,
    double volatility,
  ) {
    return min(1.0, volatility / 1000.0 + (transactions.isEmpty ? 0.5 : 0.0));
  }
}
