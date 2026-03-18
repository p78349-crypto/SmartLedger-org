part of 'ceo_prediction_service.dart';

/// CEO Prediction Service Extensions
/// Additional analytical methods for executive forecasting
extension CeoPredictionServiceExtensions on CeoPredictionService {
  /// Calculates cash flow trend from historical transactions
  double _calculateCashFlowTrend(List<Transaction> transactions) {
    if (transactions.length < 7) return 0.0;

    final dailyTotals = <DateTime, double>{};

    for (final transaction in transactions) {
      final day = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      dailyTotals[day] = (dailyTotals[day] ?? 0.0) + transaction.amount;
    }

    final values = dailyTotals.values.toList();
    return CeoPredictionHelper.calculateTrendVelocity(values);
  }

  /// Extrapolates future cash flow based on current trends
  double _extrapolateCashFlow(double trend, DateTime targetDate) {
    final daysFromNow = targetDate.difference(DateTime.now()).inDays;
    final baseFlow = trend * 7; // Weekly base
    final projectedChange = trend * daysFromNow;

    return baseFlow + projectedChange;
  }

  /// Calculates variance in transaction amounts
  double _calculateVariance(List<Transaction> transactions) {
    if (transactions.isEmpty) return 0.0;

    final amounts = transactions.map((t) => t.amount).toList();
    final mean = amounts.reduce((a, b) => a + b) / amounts.length;

    final squaredDiffs = amounts.map((amount) => pow(amount - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / amounts.length;
  }

  /// Identifies key factors affecting financial performance
  List<String> _identifyKeyFactors(
    List<Transaction> transactions,
    List<Asset> assets,
  ) {
    final factors = <String>[];

    // Analyze transaction patterns
    final categoryTotals = <String, double>{};
    for (final transaction in transactions) {
      final category = transaction.mainCategory;
      categoryTotals[category] =
          (categoryTotals[category] ?? 0.0) + transaction.amount.abs();
    }

    // Find top spending categories
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isNotEmpty) {
      factors.add('Major expense: ${sortedCategories.first.key}');
    }

    // Asset composition analysis
    if (assets.isNotEmpty) {
      final assetTypes = assets.map((a) => a.category.name).toSet();
      if (assetTypes.length > 3) {
        factors.add('Diversified portfolio (${assetTypes.length} asset types)');
      } else {
        factors.add('Concentrated holdings in ${assetTypes.join(", ")}');
      }
    }

    return factors.take(5).toList();
  }

  /// Calculates weekly trend indicators
  Map<String, double> _calculateWeeklyTrends(
    List<CeoPredictionModel> predictions,
  ) {
    if (predictions.isEmpty) return {};

    final cashFlows = predictions.map((p) => p.predictedCashFlow).toList();
    final avgConfidence =
        predictions.map((p) => p.confidenceLevel).reduce((a, b) => a + b) /
        predictions.length;
    final totalWeeklyFlow = cashFlows.reduce((a, b) => a + b);

    return {
      'weekly_total': totalWeeklyFlow,
      'daily_average': totalWeeklyFlow / 7,
      'avg_confidence': avgConfidence,
      'trend_strength': CeoPredictionHelper.calculateTrendVelocity(cashFlows),
    };
  }

  /// Generates actionable recommendations for executives
  List<String> _generateRecommendations(
    List<CeoPredictionModel> predictions,
    Map<String, double> trends,
  ) {
    final recommendations = <String>[];
    final avgRisk =
        predictions.map((p) => p.riskScore.overall).reduce((a, b) => a + b) /
        predictions.length;

    if (trends['weekly_total']! < 0) {
      recommendations.add(
        'Monitor cash flow - projected weekly deficit detected',
      );
    }

    if (avgRisk > 0.7) {
      recommendations.add(
        'High risk detected - consider portfolio rebalancing',
      );
    }

    if (trends['avg_confidence']! < 0.7) {
      recommendations.add(
        'Low prediction confidence - gather more financial data',
      );
    }

    return recommendations;
  }
}
