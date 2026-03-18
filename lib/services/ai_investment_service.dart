import 'dart:math';
import '../models/ai_investment_models.dart';
import '../models/asset.dart';
import '../utils/ai_investment_helper.dart';
import 'asset_service.dart';
import 'user_pref_service.dart';
import 'gemini_ai_service.dart'; // 실제 AI 모델 추가
import 'aicore_gemini_service.dart'; // 오프라인 AI 추가

part 'ai_investment_service_extensions.dart';
part 'ai_investment_service_utils.dart';

/// AI Investment Insight Service
/// Provides investment reference information and portfolio analysis
class AiInvestmentService {
  static final AiInvestmentService _instance = AiInvestmentService._internal();
  factory AiInvestmentService() => _instance;
  AiInvestmentService._internal();

  final AssetService _assetService = AssetService();
  final UserPrefService _userPrefService = UserPrefService();

  /// Analyzes current portfolio and provides investment reference information
  Future<PortfolioAnalysis> analyzePortfolio({
    InvestmentRiskLevel? riskPreference,
    InvestmentTimeHorizon? timeHorizon,
  }) async {
    try {
      final assets = await _assetService.getAllAssets();
      final userAge = await _getUserAge();

      riskPreference ??= await _getUserRiskPreference();
      timeHorizon ??= await _getUserTimeHorizon();

      final currentAllocation = _calculateCurrentAllocation(assets);
      final riskScore = AiInvestmentHelper.calculatePortfolioRisk(
        currentAllocation,
      );
      final diversificationScore =
          AiInvestmentHelper.calculateDiversificationScore(currentAllocation);

      final recommendations = await _generateRecommendations(
        currentAllocation,
        riskPreference,
        timeHorizon,
        userAge,
        riskScore,
        diversificationScore,
      );

      final rebalanceRequired = _shouldRebalance(
        currentAllocation,
        riskScore,
        diversificationScore,
      );

      return PortfolioAnalysis(
        currentAllocation: currentAllocation,
        riskScore: riskScore,
        diversificationScore: diversificationScore,
        recommendations: recommendations,
        rebalanceRequired: rebalanceRequired,
        analysisDate: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to analyze portfolio: $e');
    }
  }

  /// Generates personalized investment reference information
  Future<List<InvestmentRecommendation>> generateInvestmentAdvice({
    required double investmentAmount,
    InvestmentRiskLevel? riskLevel,
    InvestmentTimeHorizon? timeHorizon,
  }) async {
    try {
      final userAge = await _getUserAge();

      riskLevel ??= await _getUserRiskPreference();
      timeHorizon ??= await _getUserTimeHorizon();

      final optimalAllocation = AiInvestmentHelper.suggestOptimalAllocation(
        riskLevel,
        timeHorizon,
        userAge,
      );

      return _createRecommendationsFromAllocation(
        optimalAllocation,
        investmentAmount,
        riskLevel,
        timeHorizon,
      );
    } catch (e) {
      throw Exception(
        'Failed to generate investment reference information: $e',
      );
    }
  }

  Map<InvestmentAssetType, double> _calculateCurrentAllocation(
    List<Asset> assets,
  ) {
    final allocation = <InvestmentAssetType, double>{};
    double totalValue = 0.0;

    // Calculate total portfolio value
    for (final asset in assets) {
      totalValue += asset.amount;
    }

    if (totalValue == 0) return allocation;

    // Map assets to investment types and calculate percentages
    for (final asset in assets) {
      final investmentType = _mapAssetToInvestmentType(asset.category);
      final percentage = (asset.amount / totalValue) * 100.0;
      allocation[investmentType] =
          (allocation[investmentType] ?? 0.0) + percentage;
    }

    return allocation;
  }

  InvestmentAssetType _mapAssetToInvestmentType(AssetCategory category) {
    switch (category) {
      case AssetCategory.stock:
        return InvestmentAssetType.stocks;
      case AssetCategory.bond:
        return InvestmentAssetType.bonds;
      case AssetCategory.crypto:
        return InvestmentAssetType.cryptocurrency;
      case AssetCategory.realEstate:
      case AssetCategory.company:
        return InvestmentAssetType.realEstate;
      case AssetCategory.deposit:
      case AssetCategory.cash:
        return InvestmentAssetType.cash;
      case AssetCategory.other:
        return InvestmentAssetType.stocks; // Default fallback
    }
  }
}
