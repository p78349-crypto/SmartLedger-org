part of 'financial_analytics_service.dart';

/// Financial Analytics Service Utils
/// Helper methods for data retrieval and calculations
extension FinancialAnalyticsServiceUtils on FinancialAnalyticsService {
  /// Gets historical transactions for analysis
  Future<List<Transaction>> _getHistoricalTransactions(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _transactionService.getTransactionsBetween(startDate, endDate);
  }

  /// Gets recent transactions for ratio calculations
  Future<List<Transaction>> _getRecentTransactions(int days) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));
    return await _transactionService.getTransactionsBetween(startDate, endDate);
  }

  /// Gets current cash position across all accounts
  Future<double> _getCurrentCashPosition() async {
    final accounts = await _accountService.getAllAccounts();
    return accounts.fold(0.0, (sum, account) => sum + account.balance);
  }

  /// Calculates performance metrics for individual asset
  Future<InvestmentPerformance?> _calculateAssetPerformance(
    Asset asset,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    try {
      // For this implementation, we'll use asset's purchase price as initial investment
      final initialInvestment = asset.purchasePrice ?? asset.currentValue;
      final currentValue = asset.currentValue;
      
      if (initialInvestment <= 0) return null;
      
      final purchaseDate = asset.purchaseDate ?? DateTime.now().subtract(const Duration(days: 365));
      final evaluationDate = endDate ?? DateTime.now();
      final durationDays = evaluationDate.difference(purchaseDate).inDays;
      
      if (durationDays <= 0) return null;
      
      final totalReturn = ((currentValue - initialInvestment) / initialInvestment) * 100;
      final annualizedReturn = FinancialAnalyticsHelper.calculateAnnualizedReturn(
        totalReturn,
        durationDays,
      ) * 100;
      
      // Simplified volatility calculation (would need historical prices for accuracy)
      final estimatedVolatility = _estimateAssetVolatility(asset.assetType);
      
      final sharpeRatio = FinancialAnalyticsHelper.calculateSharpeRatio(
        annualizedReturn / 100,
        estimatedVolatility,
        0.02,
      );
      
      return InvestmentPerformance(
        assetId: asset.id,
        assetName: asset.name,
        initialInvestment: initialInvestment,
        currentValue: currentValue,
        totalReturn: totalReturn,
        annualizedReturn: annualizedReturn,
        volatility: estimatedVolatility,
        sharpeRatio: sharpeRatio,
        performancePeriod: PerformancePeriod(
          startDate: purchaseDate,
          endDate: evaluationDate,
          durationDays: durationDays,
        ),
      );
      
    } catch (_) {
      return null;
    }
  }

  /// Estimates asset volatility based on asset type
  double _estimateAssetVolatility(String assetType) {
    const volatilityMap = {
      'stock': 0.20,
      'bond': 0.05,
      'crypto': 0.50,
      'real_estate': 0.15,
      'commodity': 0.25,
      'cash': 0.01,
      'etf': 0.12,
    };
    
    final type = assetType.toLowerCase();
    for (final entry in volatilityMap.entries) {
      if (type.contains(entry.key)) {
        return entry.value;
      }
    }
    
    return 0.15; // Default moderate volatility
  }

  /// Calculates average monthly income from transactions
  double _calculateMonthlyIncome(List<Transaction> transactions) {
    final incomeTransactions = transactions.where((t) => t.amount > 0).toList();
    
    if (incomeTransactions.isEmpty) return 0.0;
    
    final totalIncome = incomeTransactions.fold(0.0, (sum, t) => sum + t.amount);
    final daysSpanned = _getDaysSpanned(incomeTransactions);
    
    return (totalIncome / daysSpanned) * 30.44; // Average days per month
  }

  /// Calculates average monthly expenses from transactions
  double _calculateMonthlyExpenses(List<Transaction> transactions) {
    final expenseTransactions = transactions.where((t) => t.amount < 0).toList();
    
    if (expenseTransactions.isEmpty) return 0.0;
    
    final totalExpenses = expenseTransactions.fold(0.0, (sum, t) => sum + t.amount.abs());
    final daysSpanned = _getDaysSpanned(expenseTransactions);
    
    return (totalExpenses / daysSpanned) * 30.44; // Average days per month
  }

  /// Determines if asset type is considered liquid
  bool _isLiquidAsset(String assetType) {
    const liquidTypes = ['cash', 'savings', 'checking', 'money_market'];
    return liquidTypes.any((type) => assetType.toLowerCase().contains(type));
  }

  /// Determines if asset type is considered an investment
  bool _isInvestmentAsset(String assetType) {
    const investmentTypes = ['stock', 'bond', 'etf', 'mutual_fund', 'crypto', 'real_estate'];
    return investmentTypes.any((type) => assetType.toLowerCase().contains(type));
  }
}