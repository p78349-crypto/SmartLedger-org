import 'dart:math';
import '../models/financial_analytics_models.dart';
import '../models/transaction.dart';
import '../models/asset.dart';
import '../utils/financial_analytics_helper.dart';
import 'transaction_service.dart';
import 'asset_service.dart';
import 'account_service.dart';
import 'gemini_ai_service.dart'; // AI 기반 예측 추가

part 'financial_analytics_service_extensions.dart';
part 'financial_analytics_service_utils.dart';

/// Financial Analytics Service
/// Advanced financial analysis, forecasting and performance metrics
class FinancialAnalyticsService {
  static final FinancialAnalyticsService _instance =
      FinancialAnalyticsService._internal();
  factory FinancialAnalyticsService() => _instance;
  FinancialAnalyticsService._internal();

  final TransactionService _transactionService = TransactionService();
  final AssetService _assetService = AssetService();
  final AccountService _accountService = AccountService();

  /// Generates comprehensive cash flow forecast
  Future<List<CashFlowForecast>> generateCashFlowForecast({
    required DateTime startDate,
    required DateTime endDate,
    int forecastDays = 90,
  }) async {
    try {
      final historicalTransactions = await _getHistoricalTransactions(
        startDate,
        endDate,
      );
      final forecasts = <CashFlowForecast>[];

      // Analyze historical patterns
      final inflowPattern = _analyzeInflowPattern(historicalTransactions);
      final outflowPattern = _analyzeOutflowPattern(historicalTransactions);

      double cumulativeCash = await _getCurrentCashPosition();

      for (int i = 0; i < forecastDays; i++) {
        final forecastDate = DateTime.now().add(Duration(days: i + 1));

        final projectedInflow = _predictDailyCashFlow(
          forecastDate,
          inflowPattern,
          isInflow: true,
        );

        final projectedOutflow = _predictDailyCashFlow(
          forecastDate,
          outflowPattern,
          isInflow: false,
        );

        final netCashFlow = projectedInflow - projectedOutflow;
        cumulativeCash += netCashFlow;

        final confidenceInterval = _calculateForecastConfidence(
          netCashFlow,
          historicalTransactions,
          i + 1,
        );

        final riskFactors = _identifyRiskFactors(
          projectedInflow,
          projectedOutflow,
          cumulativeCash,
        );

        forecasts.add(
          CashFlowForecast(
            forecastDate: forecastDate,
            projectedInflow: projectedInflow,
            projectedOutflow: projectedOutflow,
            netCashFlow: netCashFlow,
            cumulativeCashFlow: cumulativeCash,
            confidenceInterval: confidenceInterval,
            riskFactors: riskFactors,
          ),
        );
      }

      return forecasts;
    } catch (e) {
      throw Exception('Failed to generate cash flow forecast: $e');
    }
  }

  /// Analyzes investment performance and calculates ROI metrics
  Future<List<InvestmentPerformance>> analyzeInvestmentPerformance({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final assets = await _assetService.getAllAssets();
      final performances = <InvestmentPerformance>[];

      for (final asset in assets) {
        final performance = await _calculateAssetPerformance(
          asset,
          startDate,
          endDate,
        );

        if (performance != null) {
          performances.add(performance);
        }
      }

      // Sort by annualized return (descending)
      performances.sort(
        (a, b) => b.annualizedReturn.compareTo(a.annualizedReturn),
      );

      return performances;
    } catch (e) {
      throw Exception('Failed to analyze investment performance: $e');
    }
  }

  /// Calculates comprehensive financial ratios
  Future<FinancialRatios> calculateFinancialRatios() async {
    try {
      final assets = await _assetService.getAllAssets();
      final accounts = await _accountService.getAllAccounts();
      final recentTransactions = await _getRecentTransactions(90);

      final totalAssets = assets.fold(0.0, (sum, asset) => sum + asset.amount);

      final liquidAssets = assets
          .where((a) => _isLiquidAsset(a.category.name))
          .fold(0.0, (sum, asset) => sum + asset.amount);

      final investments = assets
          .where((a) => _isInvestmentAsset(a.category.name))
          .fold(0.0, (sum, asset) => sum + asset.amount);

      final monthlyIncome = _calculateMonthlyIncome(recentTransactions);
      final monthlyExpenses = _calculateMonthlyExpenses(recentTransactions);
      final monthlySavings = monthlyIncome - monthlyExpenses;

      return FinancialRatios(
        liquidityRatio: liquidAssets / max(monthlyExpenses, 1),
        debtToEquityRatio: 0.0, // Implement if debt tracking exists
        savingsRate: monthlyIncome > 0
            ? (monthlySavings / monthlyIncome) * 100
            : 0.0,
        expenseRatio: monthlyIncome > 0
            ? (monthlyExpenses / monthlyIncome) * 100
            : 0.0,
        investmentRatio: totalAssets > 0
            ? (investments / totalAssets) * 100
            : 0.0,
        emergencyFundRatio: liquidAssets / max(monthlyExpenses * 6, 1),
      );
    } catch (e) {
      throw Exception('Failed to calculate financial ratios: $e');
    }
  }
}
