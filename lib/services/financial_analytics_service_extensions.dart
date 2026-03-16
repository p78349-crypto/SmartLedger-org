part of 'financial_analytics_service.dart';

/// Financial Analytics Service Extensions
/// Advanced analysis methods and calculations
extension FinancialAnalyticsServiceExtensions on FinancialAnalyticsService {
  /// Analyzes inflow patterns from historical data
  Map<String, dynamic> _analyzeInflowPattern(List<Transaction> transactions) {
    final inflowTransactions = transactions.where((t) => t.amount > 0).toList();
    
    if (inflowTransactions.isEmpty) {
      return {'dailyAverage': 0.0, 'weeklyPattern': <double>[], 'monthlyPattern': <double>[]};
    }
    
    final dailyTotals = <int, double>{}; // Day of week -> total
    final monthlyTotals = <int, double>{}; // Day of month -> total
    
    for (final transaction in inflowTransactions) {
      final dayOfWeek = transaction.date.weekday;
      final dayOfMonth = transaction.date.day;
      
      dailyTotals[dayOfWeek] = (dailyTotals[dayOfWeek] ?? 0.0) + transaction.amount;
      monthlyTotals[dayOfMonth] = (monthlyTotals[dayOfMonth] ?? 0.0) + transaction.amount;
    }
    
    final totalInflow = inflowTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final avgDaily = totalInflow / max(1, _getDaysSpanned(inflowTransactions));
    
    return {
      'dailyAverage': avgDaily,
      'weeklyPattern': List.generate(7, (i) => dailyTotals[i + 1] ?? 0.0),
      'monthlyPattern': List.generate(31, (i) => monthlyTotals[i + 1] ?? 0.0),
    };
  }

  /// Analyzes outflow patterns from historical data
  Map<String, dynamic> _analyzeOutflowPattern(List<Transaction> transactions) {
    final outflowTransactions = transactions.where((t) => t.amount < 0).toList();
    
    if (outflowTransactions.isEmpty) {
      return {'dailyAverage': 0.0, 'weeklyPattern': <double>[], 'monthlyPattern': <double>[]};
    }
    
    final dailyTotals = <int, double>{};
    final monthlyTotals = <int, double>{};
    
    for (final transaction in outflowTransactions) {
      final dayOfWeek = transaction.date.weekday;
      final dayOfMonth = transaction.date.day;
      final absAmount = transaction.amount.abs();
      
      dailyTotals[dayOfWeek] = (dailyTotals[dayOfWeek] ?? 0.0) + absAmount;
      monthlyTotals[dayOfMonth] = (monthlyTotals[dayOfMonth] ?? 0.0) + absAmount;
    }
    
    final totalOutflow = outflowTransactions.fold(0.0, (sum, t) => sum + t.amount.abs());
    final avgDaily = totalOutflow / max(1, _getDaysSpanned(outflowTransactions));
    
    return {
      'dailyAverage': avgDaily,
      'weeklyPattern': List.generate(7, (i) => dailyTotals[i + 1] ?? 0.0),
      'monthlyPattern': List.generate(31, (i) => monthlyTotals[i + 1] ?? 0.0),
    };
  }

  /// Predicts daily cash flow based on historical patterns
  double _predictDailyCashFlow(
    DateTime forecastDate,
    Map<String, dynamic> pattern,
    {required bool isInflow}
  ) {
    final dailyAverage = pattern['dailyAverage'] as double;
    final weeklyPattern = pattern['weeklyPattern'] as List<double>;
    final monthlyPattern = pattern['monthlyPattern'] as List<double>;
    
    // Base prediction from daily average
    double prediction = dailyAverage;
    
    // Apply weekly seasonality
    if (weeklyPattern.isNotEmpty) {
      final dayOfWeek = forecastDate.weekday - 1;
      if (dayOfWeek < weeklyPattern.length) {
        final weeklyFactor = weeklyPattern[dayOfWeek] / 
            (weeklyPattern.reduce((a, b) => a + b) / weeklyPattern.length);
        prediction *= weeklyFactor;
      }
    }
    
    // Apply monthly seasonality
    if (monthlyPattern.isNotEmpty) {
      final dayOfMonth = min(forecastDate.day - 1, monthlyPattern.length - 1);
      final monthlyFactor = monthlyPattern[dayOfMonth] /
          (monthlyPattern.reduce((a, b) => a + b) / monthlyPattern.length);
      prediction *= monthlyFactor * 0.5 + 0.5; // Dampen monthly effect
    }
    
    return max(0.0, prediction);
  }

  /// Calculates confidence interval for cash flow forecast
  ConfidenceInterval _calculateForecastConfidence(
    double predictedValue,
    List<Transaction> historicalData,
    int daysAhead,
  ) {
    if (historicalData.isEmpty) {
      return ConfidenceInterval(
        lowerBound: predictedValue * 0.5,
        upperBound: predictedValue * 1.5,
        confidenceLevel: 0.5,
      );
    }
    
    // Calculate historical variance
    final amounts = historicalData.map((t) => t.amount).toList();
    final variance = FinancialAnalyticsHelper.calculateVolatility(amounts);
    
    // Increase uncertainty with forecast horizon
    final horizonFactor = 1.0 + (daysAhead * 0.02);
    final adjustedStdError = variance * horizonFactor;
    
    return FinancialAnalyticsHelper.calculateConfidenceInterval(
      predictedValue,
      adjustedStdError,
      0.95,
    );
  }

  /// Identifies potential risk factors in forecast
  List<String> _identifyRiskFactors(
    double projectedInflow,
    double projectedOutflow,
    double cumulativeCash,
  ) {
    final riskFactors = <String>[];
    
    if (cumulativeCash < 0) {
      riskFactors.add('Negative cash balance projected');
    }
    
    if (projectedOutflow > projectedInflow * 2) {
      riskFactors.add('High expense-to-income ratio');
    }
    
    if (projectedInflow < 100) {
      riskFactors.add('Low income predictability');
    }
    
    if (cumulativeCash < projectedOutflow * 7) {
      riskFactors.add('Low cash reserves');
    }
    
    return riskFactors;
  }

  int _getDaysSpanned(List<Transaction> transactions) {
    if (transactions.isEmpty) return 1;

    final sorted = transactions.map((t) => t.date).toList()..sort();
    return sorted.last.difference(sorted.first).inDays + 1;
  }
}