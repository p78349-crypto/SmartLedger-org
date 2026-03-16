import 'dart:math';
import '../models/ceo_prediction_models.dart';
import '../models/transaction.dart';
import '../models/asset.dart';
import '../utils/ceo_prediction_helper.dart';
import 'transaction_service.dart';
import 'asset_service.dart';
import 'gemini_ai_service.dart'; // 실제 AI 모델 추가

part 'ceo_prediction_service_extensions.dart';

/// CEO Prediction Service
/// Provides predictive analytics and forecasting for executive dashboards
class CeoPredictionService {
  static final CeoPredictionService _instance = CeoPredictionService._internal();
  factory CeoPredictionService() => _instance;
  CeoPredictionService._internal();

  final TransactionService _transactionService = TransactionService();
  final AssetService _assetService = AssetService();

  /// Generates weekly cash flow predictions
  Future<CeoWeeklyForecast> generateWeeklyForecast(DateTime startDate) async {
    try {
      final historicalData = await _getHistoricalData(startDate);
      final dailyPredictions = <CeoPredictionModel>[];
      
      // Generate 7-day forecast
      for (int i = 0; i < 7; i++) {
        final targetDate = startDate.add(Duration(days: i));
        final prediction = await _predictDailyMetrics(targetDate, historicalData);
        dailyPredictions.add(prediction);
      }
      
      final weeklyTrends = _calculateWeeklyTrends(dailyPredictions);
      final recommendations = _generateRecommendations(dailyPredictions, weeklyTrends);
      
      return CeoWeeklyForecast(
        weekStartDate: startDate,
        dailyPredictions: dailyPredictions,
        weeklyTrends: weeklyTrends,
        recommendations: recommendations,
      );
      
    } catch (e) {
      throw Exception('Failed to generate weekly forecast: $e');
    }
  }

  /// Predicts financial metrics for a specific date
  Future<CeoPredictionModel> _predictDailyMetrics(
    DateTime targetDate,
    Map<String, dynamic> historicalData,
  ) async {
    final transactions = historicalData['transactions'] as List<Transaction>;
    final assets = historicalData['assets'] as List<Asset>;
    
    // Calculate base prediction using trend analysis
    final recentTransactions = transactions.take(30).toList();
    final cashFlowTrend = _calculateCashFlowTrend(recentTransactions);
    final predictedFlow = _extrapolateCashFlow(cashFlowTrend, targetDate);
    
    // Calculate confidence based on data quality
    final variance = _calculateVariance(recentTransactions);
    final confidence = CeoPredictionHelper.calculateConfidenceLevel(
      transactions.length,
      variance,
      cashFlowTrend,
    );
    
    // Identify key influencing factors
    final keyFactors = _identifyKeyFactors(recentTransactions, assets);
    
    // Assess risk levels
    final riskScore = CeoPredictionHelper.assessRiskLevel(
      assets,
      recentTransactions,
      variance,
    );
    
    return CeoPredictionModel(
      targetDate: targetDate,
      predictedCashFlow: predictedFlow,
      confidenceLevel: confidence,
      keyFactors: keyFactors,
      riskScore: riskScore,
    );
  }

  Future<Map<String, dynamic>> _getHistoricalData(DateTime fromDate) async {
    final startDate = fromDate.subtract(const Duration(days: 90));
    final transactions = await _transactionService.getTransactionsBetween(startDate, fromDate);
    final assets = await _assetService.getAllAssets();
    
    return {
      'transactions': transactions,
      'assets': assets,
      'dateRange': {'start': startDate, 'end': fromDate},
    };
  }

}