part of 'ai_investment_service.dart';

/// AI Investment Service Utilities
/// Helper methods for investment calculations and user preferences
extension AiInvestmentServiceUtils on AiInvestmentService {
  /// Gets user's age from preferences
  Future<double> _getUserAge() async {
    // Default age if not available
    return 35.0;
  }

  /// Gets user's risk preference
  Future<InvestmentRiskLevel> _getUserRiskPreference() async {
    // Default risk preference
    return InvestmentRiskLevel.moderate;
  }

  /// Gets user's investment time horizon
  Future<InvestmentTimeHorizon> _getUserTimeHorizon() async {
    // Default time horizon
    return InvestmentTimeHorizon.mediumTerm;
  }

  /// Determines if portfolio rebalancing is required
  bool _shouldRebalance(
    Map<InvestmentAssetType, double> allocation,
    double riskScore,
    double diversificationScore,
  ) {
    return riskScore > 0.8 || diversificationScore < 0.4;
  }

  /// Gets default symbol for asset type
  String _getDefaultSymbol(InvestmentAssetType assetType) {
    const symbols = {
      InvestmentAssetType.stocks: 'SPY',
      InvestmentAssetType.bonds: 'BND',
      InvestmentAssetType.etf: 'VTI',
      InvestmentAssetType.cryptocurrency: 'BTC',
      InvestmentAssetType.commodities: 'GLD',
      InvestmentAssetType.realEstate: 'VNQ',
      InvestmentAssetType.cash: 'USD',
    };

    return symbols[assetType] ?? 'MIXED';
  }

  /// Gets risk level for specific asset type
  InvestmentRiskLevel _getAssetRiskLevel(InvestmentAssetType assetType) {
    const riskLevels = {
      InvestmentAssetType.cash: InvestmentRiskLevel.conservative,
      InvestmentAssetType.bonds: InvestmentRiskLevel.conservative,
      InvestmentAssetType.etf: InvestmentRiskLevel.moderate,
      InvestmentAssetType.realEstate: InvestmentRiskLevel.moderate,
      InvestmentAssetType.stocks: InvestmentRiskLevel.aggressive,
      InvestmentAssetType.commodities: InvestmentRiskLevel.aggressive,
      InvestmentAssetType.cryptocurrency: InvestmentRiskLevel.speculative,
    };

    return riskLevels[assetType] ?? InvestmentRiskLevel.moderate;
  }

  /// Calculates expected return for asset type and time horizon
  double _getExpectedReturn(
    InvestmentAssetType assetType,
    InvestmentTimeHorizon timeHorizon,
  ) {
    const baseReturns = {
      InvestmentAssetType.cash: 2.0,
      InvestmentAssetType.bonds: 4.0,
      InvestmentAssetType.etf: 8.0,
      InvestmentAssetType.realEstate: 7.0,
      InvestmentAssetType.stocks: 10.0,
      InvestmentAssetType.commodities: 6.0,
      InvestmentAssetType.cryptocurrency: 15.0,
    };

    final baseReturn = baseReturns[assetType] ?? 5.0;

    // Adjust for time horizon
    switch (timeHorizon) {
      case InvestmentTimeHorizon.shortTerm:
        return baseReturn * 0.8; // Lower returns for short term
      case InvestmentTimeHorizon.mediumTerm:
        return baseReturn;
      case InvestmentTimeHorizon.longTerm:
        return baseReturn * 1.2; // Higher potential for long term
    }
  }

  /// Generates reasoning text for investment reference information
  String _generateReasoning(
    InvestmentAssetType assetType,
    String action,
    double percentage,
  ) {
    final assetName = assetType.name.replaceAll('_', ' ');
    final direction = action == 'increase' ? '높은 편' : '낮은 편';
    return '$assetName 비중이 기준 대비 $direction으로 관찰됩니다 '
        '(${percentage.toStringAsFixed(1)}%p 차이). 분산도와 변동성 관점의 점검 참고자료입니다.';
  }
}
