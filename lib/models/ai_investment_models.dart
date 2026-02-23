/// AI Investment Advisory Models
/// Defines data structures for AI-powered investment recommendations
class InvestmentRecommendation {
  const InvestmentRecommendation({
    required this.symbol,
    required this.assetType,
    required this.recommendedAllocation,
    required this.confidenceScore,
    required this.riskLevel,
    required this.expectedReturn,
    required this.reasoning,
    required this.timeHorizon,
  });

  final String symbol;
  final InvestmentAssetType assetType;
  final double recommendedAllocation; // Percentage 0.0 to 100.0
  final double confidenceScore; // 0.0 to 1.0
  final InvestmentRiskLevel riskLevel;
  final double expectedReturn; // Annual percentage
  final String reasoning;
  final InvestmentTimeHorizon timeHorizon;

  Map<String, dynamic> toJson() => {
    'symbol': symbol,
    'assetType': assetType.name,
    'recommendedAllocation': recommendedAllocation,
    'confidenceScore': confidenceScore,
    'riskLevel': riskLevel.name,
    'expectedReturn': expectedReturn,
    'reasoning': reasoning,
    'timeHorizon': timeHorizon.name,
  };

  factory InvestmentRecommendation.fromJson(Map<String, dynamic> json) => 
    InvestmentRecommendation(
      symbol: json['symbol'],
      assetType: InvestmentAssetType.values.byName(json['assetType']),
      recommendedAllocation: json['recommendedAllocation'].toDouble(),
      confidenceScore: json['confidenceScore'].toDouble(),
      riskLevel: InvestmentRiskLevel.values.byName(json['riskLevel']),
      expectedReturn: json['expectedReturn'].toDouble(),
      reasoning: json['reasoning'],
      timeHorizon: InvestmentTimeHorizon.values.byName(json['timeHorizon']),
    );
}

enum InvestmentAssetType {
  stocks,
  bonds,
  etf,
  cryptocurrency,
  commodities,
  realEstate,
  cash,
}

enum InvestmentRiskLevel {
  conservative,
  moderate,
  aggressive,
  speculative,
}

enum InvestmentTimeHorizon {
  shortTerm, // 1-2 years
  mediumTerm, // 3-7 years
  longTerm, // 8+ years
}

class PortfolioAnalysis {
  const PortfolioAnalysis({
    required this.currentAllocation,
    required this.riskScore,
    required this.diversificationScore,
    required this.recommendations,
    required this.rebalanceRequired,
    required this.analysisDate,
  });

  final Map<InvestmentAssetType, double> currentAllocation;
  final double riskScore; // 0.0 to 1.0
  final double diversificationScore; // 0.0 to 1.0
  final List<InvestmentRecommendation> recommendations;
  final bool rebalanceRequired;
  final DateTime analysisDate;

  Map<String, dynamic> toJson() => {
    'currentAllocation': currentAllocation.map((k, v) => MapEntry(k.name, v)),
    'riskScore': riskScore,
    'diversificationScore': diversificationScore,
    'recommendations': recommendations.map((r) => r.toJson()).toList(),
    'rebalanceRequired': rebalanceRequired,
    'analysisDate': analysisDate.toIso8601String(),
  };
}