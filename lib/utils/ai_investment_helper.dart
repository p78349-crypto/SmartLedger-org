import 'dart:math';
import '../models/ai_investment_models.dart';
import '../models/asset.dart';

/// AI Investment Helper
/// Provides analytical utilities for investment decision making
class AiInvestmentHelper {
  static const double _maxRiskThreshold = 0.8;
  static const double _minDiversificationScore = 0.6;

  /// Calculates portfolio risk score based on asset allocation
  static double calculatePortfolioRisk(
    Map<InvestmentAssetType, double> allocation,
  ) {
    const riskWeights = {
      InvestmentAssetType.cash: 0.0,
      InvestmentAssetType.bonds: 0.2,
      InvestmentAssetType.stocks: 0.6,
      InvestmentAssetType.etf: 0.4,
      InvestmentAssetType.realEstate: 0.5,
      InvestmentAssetType.commodities: 0.7,
      InvestmentAssetType.cryptocurrency: 0.9,
    };

    double weightedRisk = 0.0;
    double totalAllocation = 0.0;

    allocation.forEach((assetType, percentage) {
      final risk = riskWeights[assetType] ?? 0.5;
      weightedRisk += risk * (percentage / 100.0);
      totalAllocation += percentage / 100.0;
    });

    return totalAllocation > 0 ? weightedRisk / totalAllocation : 0.0;
  }

  /// Evaluates portfolio diversification score
  static double calculateDiversificationScore(
    Map<InvestmentAssetType, double> allocation,
  ) {
    if (allocation.isEmpty) return 0.0;

    // Calculate Herfindahl-Hirschman Index (HHI) for concentration
    double hhi = 0.0;
    final totalAllocation = allocation.values.reduce((a, b) => a + b);

    if (totalAllocation == 0) return 0.0;

    allocation.forEach((_, percentage) {
      final marketShare = percentage / totalAllocation;
      hhi += marketShare * marketShare;
    });

    // Convert HHI to diversification score (0 = concentrated, 1 = diversified)
    final normalizedHhi =
        1.0 -
        ((hhi - (1.0 / allocation.length)) / (1.0 - (1.0 / allocation.length)));

    return max(0.0, min(1.0, normalizedHhi));
  }

  /// Suggests optimal asset allocation based on risk profile
  static Map<InvestmentAssetType, double> suggestOptimalAllocation(
    InvestmentRiskLevel riskLevel,
    InvestmentTimeHorizon timeHorizon,
    double currentAge,
  ) {
    // Age-based stock allocation rule: 100 - age = stock percentage
    final baseStockAllocation = max(20.0, min(80.0, 100.0 - currentAge));

    switch (riskLevel) {
      case InvestmentRiskLevel.conservative:
        return _getConservativeAllocation(baseStockAllocation * 0.6);
      case InvestmentRiskLevel.moderate:
        return _getModerateAllocation(baseStockAllocation * 0.8);
      case InvestmentRiskLevel.aggressive:
        return _getAggressiveAllocation(baseStockAllocation * 1.2);
      case InvestmentRiskLevel.speculative:
        return _getSpeculativeAllocation(baseStockAllocation * 1.4);
    }
  }

  static Map<InvestmentAssetType, double> _getConservativeAllocation(
    double stockPct,
  ) {
    final stocks = min(stockPct, 40.0);
    return {
      InvestmentAssetType.bonds: 50.0,
      InvestmentAssetType.stocks: stocks,
      InvestmentAssetType.etf: 20.0,
      InvestmentAssetType.cash: 15.0,
      InvestmentAssetType.realEstate: 10.0,
      InvestmentAssetType.commodities: 3.0,
      InvestmentAssetType.cryptocurrency: 2.0,
    };
  }

  static Map<InvestmentAssetType, double> _getModerateAllocation(
    double stockPct,
  ) {
    final stocks = min(stockPct, 60.0);
    return {
      InvestmentAssetType.stocks: stocks,
      InvestmentAssetType.etf: 25.0,
      InvestmentAssetType.bonds: 30.0,
      InvestmentAssetType.realEstate: 15.0,
      InvestmentAssetType.commodities: 5.0,
      InvestmentAssetType.cash: 8.0,
      InvestmentAssetType.cryptocurrency: 2.0,
    };
  }

  static Map<InvestmentAssetType, double> _getAggressiveAllocation(
    double stockPct,
  ) {
    return {
      InvestmentAssetType.stocks: min(stockPct, 70.0),
      InvestmentAssetType.etf: 20.0,
      InvestmentAssetType.cryptocurrency: 8.0,
      InvestmentAssetType.commodities: 10.0,
      InvestmentAssetType.realEstate: 15.0,
      InvestmentAssetType.bonds: 12.0,
      InvestmentAssetType.cash: 5.0,
    };
  }

  static Map<InvestmentAssetType, double> _getSpeculativeAllocation(
    double stockPct,
  ) {
    return {
      InvestmentAssetType.stocks: min(stockPct, 50.0),
      InvestmentAssetType.cryptocurrency: 20.0,
      InvestmentAssetType.commodities: 15.0,
      InvestmentAssetType.etf: 10.0,
      InvestmentAssetType.realEstate: 10.0,
      InvestmentAssetType.bonds: 8.0,
      InvestmentAssetType.cash: 7.0,
    };
  }
}
