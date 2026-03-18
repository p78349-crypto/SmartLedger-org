import 'package:flutter/material.dart';
import '../services/ceo_prediction_service.dart';
import '../models/ceo_prediction_models.dart';

part 'ceo_prediction_dashboard_screen_extensions.dart';
part 'ceo_prediction_dashboard_screen_utils.dart';

/// CEO 예측 대시보드 화면
/// 경영진 수준의 예측 분석 및 위험도 평가 제공
class CeoPredictionDashboardScreen extends StatefulWidget {
  const CeoPredictionDashboardScreen({super.key});

  @override
  State<CeoPredictionDashboardScreen> createState() =>
      _CeoPredictionDashboardScreenState();
}

class _CeoPredictionDashboardScreenState
    extends State<CeoPredictionDashboardScreen> {
  final CeoPredictionService _predictionService = CeoPredictionService();

  bool _isLoading = false;
  CeoWeeklyForecast? _weeklyForecast;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWeeklyForecast();
  }

  Future<void> _loadWeeklyForecast() async {
    setState(() => _isLoading = true);

    try {
      final forecast = await _predictionService.generateWeeklyForecast(
        DateTime.now(),
      );
      setState(() {
        _weeklyForecast = forecast;
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CEO 예측 대시보드'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadWeeklyForecast,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget()
          : _weeklyForecast != null
          ? _buildForecastContent()
          : const Center(child: Text('데이터를 불러오는 중...')),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('오류가 발생했습니다:\n$_errorMessage', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadWeeklyForecast,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildTrendsCard(),
          const SizedBox(height: 16),
          _buildRecommendationsCard(),
          const SizedBox(height: 16),
          _buildDailyPredictionsCard(),
        ],
      ),
    );
  }
}
