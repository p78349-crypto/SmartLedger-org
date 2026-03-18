part of 'ai_investment_advisor_screen.dart';

/// AI 투자 참고정보 화면 확장 기능들 (완전 오프라인 기반)
extension AiInvestmentAdvisorScreenExtensions
    on _AiInvestmentAdvisorScreenState {
  Widget _buildPortfolioOverviewCard() {
    final riskLevel = _getRiskLevelText(_portfolioAnalysis!.riskScore);
    final diversificationText = _getDiversificationText(
      _portfolioAnalysis!.diversificationScore,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.analytics, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  '포트폴리오 분석',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.offline_bolt, size: 16, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        '오프라인',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    '전체 위험도',
                    riskLevel,
                    _getRiskColor(_portfolioAnalysis!.riskScore),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    '다각화 지수',
                    diversificationText,
                    _getDiversificationColor(
                      _portfolioAnalysis!.diversificationScore,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskAnalysisCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '위험 분석',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('분석 기준: ${_formatDate(_portfolioAnalysis!.analysisDate)}'),
            const SizedBox(height: 16),
            _buildRiskMeter('전체 위험도', _portfolioAnalysis!.riskScore),
            const SizedBox(height: 8),
            _buildDiversificationMeter(
              '다각화 수준',
              _portfolioAnalysis!.diversificationScore,
            ),
            const SizedBox(height: 16),
            if (_portfolioAnalysis!.rebalanceRequired)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(child: Text('포트폴리오 리스크 점검이 필요합니다')),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllocationChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '현재 자산 배분',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._portfolioAnalysis!.currentAllocation.entries.map(
              (entry) => _buildAllocationBar(entry.key.name, entry.value),
            ),
            const SizedBox(height: 12),
            const Text(
              '* 자산 배분은 현재 보유 자산을 기준으로 계산됩니다',
              style: TextStyle(fontSize: 12, color: Colors.grey),
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
            const Text(
              'AI 투자 분석 참고자료',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_portfolioAnalysis!.recommendations.isEmpty)
              const Text('현재 포트폴리오에서 특이 점검 항목이 크지 않습니다.')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _portfolioAnalysis!.recommendations.length,
                itemBuilder: (context, index) {
                  final recommendation =
                      _portfolioAnalysis!.recommendations[index];
                  return _buildRecommendationTile(recommendation);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRebalanceWarningCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  '리스크 점검 필요',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('현재 포트폴리오의 위험도 또는 분산도에 대한 추가 점검이 필요합니다.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _showRebalanceDialog,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                '분석 포인트 보기',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
