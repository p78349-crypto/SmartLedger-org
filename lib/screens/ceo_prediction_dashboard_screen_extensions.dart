part of 'ceo_prediction_dashboard_screen.dart';

/// CEO 예측 대시보드 화면 확장 기능들
extension CeoPredictionDashboardScreenExtensions on _CeoPredictionDashboardScreenState {
  
  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('주간 예측 요약', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricColumn('주간 총액', '₩${_formatCurrency(_weeklyForecast!.weeklyTrends['weekly_total'] ?? 0.0)}'),
                _buildMetricColumn('일평균', '₩${_formatCurrency(_weeklyForecast!.weeklyTrends['daily_average'] ?? 0.0)}'),
                _buildMetricColumn('신뢰도', '${(_weeklyForecast!.weeklyTrends['avg_confidence']! * 100).toInt()}%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendsCard() {
    final trendStrength = _weeklyForecast!.weeklyTrends['trend_strength'] ?? 0.0;
    final isPositiveTrend = trendStrength > 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('트렌드 분석', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                  color: isPositiveTrend ? Colors.green : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPositiveTrend ? '상승 추세' : '하락 추세',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPositiveTrend ? Colors.green : Colors.red,
                        ),
                      ),
                      Text('트렌드 강도: ${trendStrength.abs().toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI 권장사항', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_weeklyForecast!.recommendations.isEmpty)
              const Text('현재 특별한 권장사항이 없습니다.')
            else
              ...(_weeklyForecast!.recommendations.map((recommendation) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(recommendation)),
                  ],
                ),
              ))),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyPredictionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('7일 예측 상세', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _weeklyForecast!.dailyPredictions.length,
              itemBuilder: (context, index) {
                final prediction = _weeklyForecast!.dailyPredictions[index];
                return _buildDayPredictionTile(prediction, index);
              },
            ),
          ],
        ),
      ),
    );
  }
}