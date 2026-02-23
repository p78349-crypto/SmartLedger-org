/// Advanced Financial Analytics Models
/// Sophisticated financial analysis and forecasting data structures
class CashFlowForecast {
  const CashFlowForecast({
    required this.forecastDate,
    required this.projectedInflow,
    required this.projectedOutflow,
    required this.netCashFlow,
    required this.cumulativeCashFlow,
    required this.confidenceInterval,
    required this.riskFactors,
  });

  final DateTime forecastDate;
  final double projectedInflow;
  final double projectedOutflow;
  final double netCashFlow;
  final double cumulativeCashFlow;
  final ConfidenceInterval confidenceInterval;
  final List<String> riskFactors;

  Map<String, dynamic> toJson() => {
    'forecastDate': forecastDate.toIso8601String(),
    'projectedInflow': projectedInflow,
    'projectedOutflow': projectedOutflow,
    'netCashFlow': netCashFlow,
    'cumulativeCashFlow': cumulativeCashFlow,
    'confidenceInterval': confidenceInterval.toJson(),
    'riskFactors': riskFactors,
  };
}

class ConfidenceInterval {
  const ConfidenceInterval({
    required this.lowerBound,
    required this.upperBound,
    required this.confidenceLevel,
  });

  final double lowerBound;
  final double upperBound;
  final double confidenceLevel; // e.g., 0.95 for 95% confidence

  Map<String, dynamic> toJson() => {
    'lowerBound': lowerBound,
    'upperBound': upperBound,
    'confidenceLevel': confidenceLevel,
  };
}

class InvestmentPerformance {
  const InvestmentPerformance({
    required this.assetId,
    required this.assetName,
    required this.initialInvestment,
    required this.currentValue,
    required this.totalReturn,
    required this.annualizedReturn,
    required this.volatility,
    required this.sharpeRatio,
    required this.performancePeriod,
  });

  final String assetId;
  final String assetName;
  final double initialInvestment;
  final double currentValue;
  final double totalReturn; // Percentage
  final double annualizedReturn; // Percentage
  final double volatility; // Standard deviation
  final double sharpeRatio;
  final PerformancePeriod performancePeriod;

  Map<String, dynamic> toJson() => {
    'assetId': assetId,
    'assetName': assetName,
    'initialInvestment': initialInvestment,
    'currentValue': currentValue,
    'totalReturn': totalReturn,
    'annualizedReturn': annualizedReturn,
    'volatility': volatility,
    'sharpeRatio': sharpeRatio,
    'performancePeriod': performancePeriod.toJson(),
  };
}

class PerformancePeriod {
  const PerformancePeriod({
    required this.startDate,
    required this.endDate,
    required this.durationDays,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;

  Map<String, dynamic> toJson() => {
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'durationDays': durationDays,
  };
}

class FinancialRatios {
  const FinancialRatios({
    required this.liquidityRatio,
    required this.debtToEquityRatio,
    required this.savingsRate,
    required this.expenseRatio,
    required this.investmentRatio,
    required this.emergencyFundRatio,
  });

  final double liquidityRatio;
  final double debtToEquityRatio;
  final double savingsRate; // Percentage of income saved
  final double expenseRatio; // Expenses to income ratio
  final double investmentRatio; // Investments to total assets
  final double emergencyFundRatio; // Emergency fund to monthly expenses

  Map<String, dynamic> toJson() => {
    'liquidityRatio': liquidityRatio,
    'debtToEquityRatio': debtToEquityRatio,
    'savingsRate': savingsRate,
    'expenseRatio': expenseRatio,
    'investmentRatio': investmentRatio,
    'emergencyFundRatio': emergencyFundRatio,
  };
}