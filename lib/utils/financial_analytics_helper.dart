import 'dart:math';
import '../models/financial_analytics_models.dart';
import '../models/transaction.dart';
import '../models/asset.dart';

/// Financial Analytics Helper
/// Advanced mathematical and statistical utilities for financial analysis
class FinancialAnalyticsHelper {
  static const double _riskFreeRate = 0.02; // 2% annual risk-free rate
  static const int _tradingDaysPerYear = 252;

  /// Calculates Sharpe Ratio for investment performance
  static double calculateSharpeRatio(
    double averageReturn,
    double standardDeviation,
    double riskFreeRate,
  ) {
    if (standardDeviation == 0) return 0.0;
    return (averageReturn - riskFreeRate) / standardDeviation;
  }

  /// Calculates annualized return from total return and time period
  static double calculateAnnualizedReturn(
    double totalReturn,
    int durationDays,
  ) {
    if (durationDays <= 0) return 0.0;
    final years = durationDays / 365.25;
    return pow(1 + totalReturn / 100.0, 1 / years) - 1.0;
  }

  /// Calculates volatility (standard deviation) of returns
  static double calculateVolatility(List<double> returns) {
    if (returns.length < 2) return 0.0;

    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final squaredDifferences = returns.map((r) => pow(r - mean, 2));
    final variance =
        squaredDifferences.reduce((a, b) => a + b) / (returns.length - 1);

    return sqrt(variance);
  }

  /// Performs linear regression for trend analysis
  static Map<String, double> calculateLinearRegression(
    List<double> xValues,
    List<double> yValues,
  ) {
    if (xValues.length != yValues.length || xValues.length < 2) {
      return {'slope': 0.0, 'intercept': 0.0, 'correlation': 0.0};
    }

    final n = xValues.length;
    final sumX = xValues.reduce((a, b) => a + b);
    final sumY = yValues.reduce((a, b) => a + b);
    final sumXY = List.generate(
      n,
      (i) => xValues[i] * yValues[i],
    ).reduce((a, b) => a + b);
    final sumXX = xValues.map((x) => x * x).reduce((a, b) => a + b);
    final sumYY = yValues.map((y) => y * y).reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // Calculate correlation coefficient
    final numerator = n * sumXY - sumX * sumY;
    final denominator = sqrt(
      (n * sumXX - sumX * sumX) * (n * sumYY - sumY * sumY),
    );
    final correlation = denominator != 0 ? numerator / denominator : 0.0;

    return {'slope': slope, 'intercept': intercept, 'correlation': correlation};
  }

  /// Creates confidence interval for predictions
  static ConfidenceInterval calculateConfidenceInterval(
    double predictedValue,
    double standardError,
    double confidenceLevel,
  ) {
    // Using normal distribution approximation
    final zScore = _getZScore(confidenceLevel);
    final margin = zScore * standardError;

    return ConfidenceInterval(
      lowerBound: predictedValue - margin,
      upperBound: predictedValue + margin,
      confidenceLevel: confidenceLevel,
    );
  }

  /// Performs seasonal decomposition analysis
  static Map<String, List<double>> seasonalDecomposition(
    List<double> timeSeries,
    int seasonalPeriod,
  ) {
    if (timeSeries.length < seasonalPeriod * 2) {
      return {'trend': timeSeries, 'seasonal': [], 'residual': []};
    }

    // Simple moving average for trend
    final trend = <double>[];
    for (int i = 0; i < timeSeries.length; i++) {
      if (i < seasonalPeriod ~/ 2 ||
          i >= timeSeries.length - seasonalPeriod ~/ 2) {
        trend.add(timeSeries[i]);
      } else {
        final start = i - seasonalPeriod ~/ 2;
        final end = i + seasonalPeriod ~/ 2;
        final avg =
            timeSeries.sublist(start, end + 1).reduce((a, b) => a + b) /
            seasonalPeriod;
        trend.add(avg);
      }
    }

    // Calculate seasonal components
    final seasonal = List<double>.filled(timeSeries.length, 0.0);
    final detrended = List.generate(
      timeSeries.length,
      (i) => timeSeries[i] - trend[i],
    );

    for (int s = 0; s < seasonalPeriod; s++) {
      final seasonalValues = <double>[];
      for (int i = s; i < detrended.length; i += seasonalPeriod) {
        seasonalValues.add(detrended[i]);
      }
      final avgSeasonal = seasonalValues.isNotEmpty
          ? seasonalValues.reduce((a, b) => a + b) / seasonalValues.length
          : 0.0;

      for (int i = s; i < seasonal.length; i += seasonalPeriod) {
        seasonal[i] = avgSeasonal;
      }
    }

    // Calculate residual
    final residual = List.generate(
      timeSeries.length,
      (i) => timeSeries[i] - trend[i] - seasonal[i],
    );

    return {'trend': trend, 'seasonal': seasonal, 'residual': residual};
  }

  static double _getZScore(double confidenceLevel) {
    // Common z-scores for confidence levels
    if (confidenceLevel >= 0.99) return 2.576;
    if (confidenceLevel >= 0.95) return 1.96;
    if (confidenceLevel >= 0.9) return 1.645;
    return 1.96; // Default to 95%
  }
}
