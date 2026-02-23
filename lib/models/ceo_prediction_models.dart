/// CEO Dashboard Prediction Models
/// Handles predictive analytics for executive-level financial insights
class CeoPredictionModel {
  const CeoPredictionModel({
    required this.targetDate,
    required this.predictedCashFlow,
    required this.confidenceLevel,
    required this.keyFactors,
    required this.riskScore,
  });

  final DateTime targetDate;
  final double predictedCashFlow;
  final double confidenceLevel; // 0.0 to 1.0
  final List<String> keyFactors;
  final RiskScore riskScore;

  Map<String, dynamic> toJson() => {
    'targetDate': targetDate.toIso8601String(),
    'predictedCashFlow': predictedCashFlow,
    'confidenceLevel': confidenceLevel,
    'keyFactors': keyFactors,
    'riskScore': riskScore.toJson(),
  };

  factory CeoPredictionModel.fromJson(Map<String, dynamic> json) => CeoPredictionModel(
    targetDate: DateTime.parse(json['targetDate']),
    predictedCashFlow: json['predictedCashFlow'].toDouble(),
    confidenceLevel: json['confidenceLevel'].toDouble(),
    keyFactors: List<String>.from(json['keyFactors']),
    riskScore: RiskScore.fromJson(json['riskScore']),
  );
}

class RiskScore {
  const RiskScore({
    required this.overall,
    required this.liquidity,
    required this.market,
    required this.operational,
  });

  final double overall; // 0.0 (low) to 1.0 (high)
  final double liquidity;
  final double market;
  final double operational;

  Map<String, dynamic> toJson() => {
    'overall': overall,
    'liquidity': liquidity,
    'market': market,
    'operational': operational,
  };

  factory RiskScore.fromJson(Map<String, dynamic> json) => RiskScore(
    overall: json['overall'].toDouble(),
    liquidity: json['liquidity'].toDouble(),
    market: json['market'].toDouble(),
    operational: json['operational'].toDouble(),
  );
}

class CeoWeeklyForecast {
  const CeoWeeklyForecast({
    required this.weekStartDate,
    required this.dailyPredictions,
    required this.weeklyTrends,
    required this.recommendations,
  });

  final DateTime weekStartDate;
  final List<CeoPredictionModel> dailyPredictions;
  final Map<String, double> weeklyTrends;
  final List<String> recommendations;

  Map<String, dynamic> toJson() => {
    'weekStartDate': weekStartDate.toIso8601String(),
    'dailyPredictions': dailyPredictions.map((p) => p.toJson()).toList(),
    'weeklyTrends': weeklyTrends,
    'recommendations': recommendations,
  };
}