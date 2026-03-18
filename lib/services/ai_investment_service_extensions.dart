part of 'ai_investment_service.dart';

/// AI Investment Service Extensions
/// Additional methods for investment analysis and reference information
extension AiInvestmentServiceExtensions on AiInvestmentService {
  /// Generates reference information based on portfolio analysis
  Future<List<InvestmentRecommendation>> _generateRecommendations(
    Map<InvestmentAssetType, double> currentAllocation,
    InvestmentRiskLevel riskLevel,
    InvestmentTimeHorizon timeHorizon,
    double userAge,
    double riskScore,
    double diversificationScore,
  ) async {
    final recommendations = <InvestmentRecommendation>[];

    final optimalAllocation = AiInvestmentHelper.suggestOptimalAllocation(
      riskLevel,
      timeHorizon,
      userAge,
    );

    // Compare current vs optimal allocation and generate reference information
    optimalAllocation.forEach((assetType, optimalPercentage) {
      final currentPercentage = currentAllocation[assetType] ?? 0.0;
      final difference = optimalPercentage - currentPercentage;

      if (difference.abs() > 5.0) {
        // Significant deviation threshold
        final recommendation = _createRecommendation(
          assetType,
          difference,
          riskLevel,
          timeHorizon,
          riskScore,
        );

        if (recommendation != null) {
          recommendations.add(recommendation);
        }
      }
    });

    return recommendations;
  }

  /// Creates individual investment reference information item
  InvestmentRecommendation? _createRecommendation(
    InvestmentAssetType assetType,
    double allocationDifference,
    InvestmentRiskLevel riskLevel,
    InvestmentTimeHorizon timeHorizon,
    double portfolioRisk,
  ) {
    if (allocationDifference == 0) return null;

    final action = allocationDifference > 0 ? 'increase' : 'decrease';
    final confidenceScore = _calculateRecommendationConfidence(
      assetType,
      riskLevel,
      portfolioRisk,
    );

    return InvestmentRecommendation(
      symbol: _getDefaultSymbol(assetType),
      assetType: assetType,
      recommendedAllocation: allocationDifference.abs(),
      confidenceScore: confidenceScore,
      riskLevel: _getAssetRiskLevel(assetType),
      expectedReturn: _getExpectedReturn(assetType, timeHorizon),
      reasoning: _generateReasoning(
        assetType,
        action,
        allocationDifference.abs(),
      ),
      timeHorizon: timeHorizon,
    );
  }

  /// Creates reference information from optimal allocation
  List<InvestmentRecommendation> _createRecommendationsFromAllocation(
    Map<InvestmentAssetType, double> allocation,
    double totalAmount,
    InvestmentRiskLevel riskLevel,
    InvestmentTimeHorizon timeHorizon,
  ) {
    return allocation.entries.map((entry) {
      final assetType = entry.key;
      final percentage = entry.value;
      final amount = (totalAmount * percentage / 100.0);

      return InvestmentRecommendation(
        symbol: _getDefaultSymbol(assetType),
        assetType: assetType,
        recommendedAllocation: percentage,
        confidenceScore: _calculateRecommendationConfidence(
          assetType,
          riskLevel,
          0.5,
        ),
        riskLevel: _getAssetRiskLevel(assetType),
        expectedReturn: _getExpectedReturn(assetType, timeHorizon),
        reasoning:
            'Optimal allocation for ${riskLevel.name} investor with ${timeHorizon.name} horizon',
        timeHorizon: timeHorizon,
      );
    }).toList();
  }

  double _calculateRecommendationConfidence(
    InvestmentAssetType assetType,
    InvestmentRiskLevel riskLevel,
    double portfolioRisk,
  ) {
    // Base confidence based on asset type stability
    const baseConfidence = {
      InvestmentAssetType.bonds: 0.9,
      InvestmentAssetType.etf: 0.85,
      InvestmentAssetType.stocks: 0.7,
      InvestmentAssetType.realEstate: 0.75,
      InvestmentAssetType.commodities: 0.6,
      InvestmentAssetType.cryptocurrency: 0.4,
      InvestmentAssetType.cash: 0.95,
    };

    final base = baseConfidence[assetType] ?? 0.5;
    final riskAdjustment = 1.0 - (portfolioRisk * 0.2);

    return (base * riskAdjustment).clamp(0.3, 1.0);
  }
}
