part of 'ceo_prediction_dashboard_screen.dart';

/// CEO 예측 대시보드 유틸리티 메서드들
extension CeoPredictionDashboardScreenUtils on _CeoPredictionDashboardScreenState {
  
  Widget _buildMetricColumn(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDayPredictionTile(CeoPredictionModel prediction, int dayIndex) {
    final dayNames = ['월', '화', '수', '목', '금', '토', '일'];
    final dayName = dayNames[prediction.targetDate.weekday - 1];
    final isPositiveFlow = prediction.predictedCashFlow >= 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        color: isPositiveFlow ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: isPositiveFlow ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPositiveFlow ? Colors.green : Colors.red,
            ),
            child: Center(
              child: Text(
                dayName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₩${_formatCurrency(prediction.predictedCashFlow)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPositiveFlow ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                Text('신뢰도: ${(prediction.confidenceLevel * 100).toInt()}%'),
                if (prediction.riskScore.overall > 0.7)
                  Row(
                    children: [
                      const Icon(Icons.warning, size: 16, color: Colors.orange),
                      const SizedBox(width: 4),
                      const Text('높은 위험도', style: TextStyle(fontSize: 12, color: Colors.orange)),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return amount.toStringAsFixed(0);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}