import 'package:flutter/material.dart';
import '../services/financial_analytics_service.dart';
import '../models/financial_analytics_models.dart';

/// 고급 재무분석 화면
/// 현금흐름 예측, ROI 분석, 재무비율 계산 (완전 오프라인)
class AdvancedFinancialAnalyticsScreen extends StatefulWidget {
  const AdvancedFinancialAnalyticsScreen({super.key});

  @override
  State<AdvancedFinancialAnalyticsScreen> createState() =>
      _AdvancedFinancialAnalyticsScreenState();
}

class _AdvancedFinancialAnalyticsScreenState
    extends State<AdvancedFinancialAnalyticsScreen> {
  final FinancialAnalyticsService _analyticsService =
      FinancialAnalyticsService();

  bool _isLoading = false;
  List<CashFlowForecast>? _cashFlowForecast;
  List<InvestmentPerformance>? _investmentPerformance;
  FinancialRatios? _financialRatios;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final futures = await Future.wait([
        _analyticsService.generateCashFlowForecast(
          startDate: DateTime.now().subtract(const Duration(days: 90)),
          endDate: DateTime.now(),
          forecastDays: 30,
        ),
        _analyticsService.analyzeInvestmentPerformance(),
        _analyticsService.calculateFinancialRatios(),
      ]);

      setState(() {
        _cashFlowForecast = futures[0] as List<CashFlowForecast>;
        _investmentPerformance = futures[1] as List<InvestmentPerformance>;
        _financialRatios = futures[2] as FinancialRatios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('분석 로딩 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('고급 재무분석'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadAnalytics,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildOfflineIndicator(),
                  const SizedBox(height: 16),
                  if (_financialRatios != null) _buildFinancialRatiosCard(),
                  const SizedBox(height: 16),
                  if (_cashFlowForecast != null) _buildCashFlowForecastCard(),
                  const SizedBox(height: 16),
                  if (_investmentPerformance != null)
                    _buildInvestmentPerformanceCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildOfflineIndicator() {
    return Card(
      color: Colors.green.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.offline_bolt, color: Colors.green),
            SizedBox(width: 12),
            Expanded(child: Text('완전 오프라인 분석 - 모든 계산이 로컬에서 수행됩니다')),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialRatiosCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '재무비율 분석',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildRatioRow('유동성 비율', _financialRatios!.liquidityRatio, '배'),
            _buildRatioRow('저축률', _financialRatios!.savingsRate, '%'),
            _buildRatioRow('투자비율', _financialRatios!.investmentRatio, '%'),
            _buildRatioRow(
              '비상자금 비율',
              _financialRatios!.emergencyFundRatio,
              '배',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatioRow(String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${value.toStringAsFixed(2)}$unit',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowForecastCard() {
    final weeklyForecast = _cashFlowForecast!.take(7).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '현금흐름 예측 (7일)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...weeklyForecast.map(_buildForecastRow),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastRow(CashFlowForecast forecast) {
    final isPositive = forecast.netCashFlow >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '${forecast.forecastDate.month}/${forecast.forecastDate.day}',
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: (forecast.netCashFlow.abs() / 10000).clamp(0.0, 1.0),
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '₩${_formatAmount(forecast.netCashFlow)}',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvestmentPerformanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '투자 성과 분석',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_investmentPerformance!.isEmpty)
              const Text('투자 자산이 없습니다')
            else
              ..._investmentPerformance!.take(5).map(_buildPerformanceRow),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceRow(InvestmentPerformance performance) {
    final isPositive = performance.totalReturn >= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(child: Text(performance.assetName)),
          Text(
            '${performance.totalReturn.toStringAsFixed(1)}%',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount.abs() >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }
}
