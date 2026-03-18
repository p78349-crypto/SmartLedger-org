part of 'ai_investment_advisor_screen.dart';

/// AI 투자 참고정보 화면 유틸리티 메서드들 (완전 오프라인 기반)
extension AiInvestmentAdvisorScreenUtils on _AiInvestmentAdvisorScreenState {
  Widget _buildOfflineNoticeCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '오프라인 AI 분석',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('이 분석은 완전히 오프라인으로 수행됩니다:'),
            const SizedBox(height: 8),
            const Text('• 인터넷 연결 불필요'),
            const Text('• 개인정보 외부 전송 없음'),
            const Text('• 로컬 데이터만 사용'),
            const Text('• AI 알고리즘 내장'),
            const SizedBox(height: 8),
            const Text(
              '※ 본 화면은 참고용 정보이며 투자 권유가 아닙니다.\n'
              '개별 종목 추천, 매수/매도 지시, 진입시점 제시는 제공하지 않습니다.\n'
              '최종 투자 판단과 결과에 대한 모든 책임은 본인에게 있습니다.\n'
              '투자 손실 또는 분쟁 발생 시 국내외(미국 포함)에서 민사상 분쟁/소송이 제기될 수 있습니다.\n'
              '관련 법령이 허용하는 범위에서 앱 판매자/제공자는 직접·간접 손해에 대해 책임을 지지 않습니다.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiskMeter(String title, double riskScore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: riskScore,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(_getRiskColor(riskScore)),
        ),
        const SizedBox(height: 4),
        Text(
          '${(riskScore * 100).toInt()}%',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDiversificationMeter(String title, double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            _getDiversificationColor(score),
          ),
        ),
        const SizedBox(height: 4),
        Text('${(score * 100).toInt()}%', style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildAllocationBar(String assetType, double percentage) {
    final displayName = _getAssetTypeDisplayName(assetType);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(displayName, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage / 100.0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getAssetTypeColor(assetType),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            child: Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationTile(InvestmentRecommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getAssetTypeIcon(recommendation.assetType), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_getAssetTypeDisplayName(recommendation.assetType.name)} 분석 기준 비중 ${recommendation.recommendedAllocation.toStringAsFixed(1)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(recommendation.confidenceScore),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '신뢰도 ${(recommendation.confidenceScore * 100).toInt()}%',
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            recommendation.reasoning,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
