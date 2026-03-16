part of 'ai_investment_advisor_screen.dart';

/// AI 투자 참고정보 화면 추가 유틸리티들
extension AiInvestmentAdvisorScreenHelpers on _AiInvestmentAdvisorScreenState {
  
  String _getRiskLevelText(double riskScore) {
    if (riskScore < 0.3) return '낮음';
    if (riskScore < 0.6) return '보통';
    if (riskScore < 0.8) return '높음';
    return '매우 높음';
  }

  String _getDiversificationText(double score) {
    if (score < 0.4) return '부족';
    if (score < 0.7) return '보통';
    return '우수';
  }

  Color _getRiskColor(double riskScore) {
    if (riskScore < 0.3) return Colors.green;
    if (riskScore < 0.6) return Colors.yellow.shade700;
    if (riskScore < 0.8) return Colors.orange;
    return Colors.red;
  }

  Color _getDiversificationColor(double score) {
    if (score < 0.4) return Colors.red;
    if (score < 0.7) return Colors.orange;
    return Colors.green;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence < 0.5) return Colors.red;
    if (confidence < 0.7) return Colors.orange;
    return Colors.green;
  }

  Color _getAssetTypeColor(String assetType) {
    switch (assetType.toLowerCase()) {
      case 'stocks':
        return Colors.blue;
      case 'bonds':
        return Colors.green;
      case 'etf':
        return Colors.purple;
      case 'cryptocurrency':
        return Colors.orange;
      case 'commodities':
        return Colors.brown;
      case 'realestate':
        return Colors.teal;
      case 'cash':
        return Colors.grey;
      default:
        return Colors.indigo;
    }
  }

  IconData _getAssetTypeIcon(InvestmentAssetType assetType) {
    switch (assetType) {
      case InvestmentAssetType.stocks:
        return Icons.trending_up;
      case InvestmentAssetType.bonds:
        return Icons.account_balance;
      case InvestmentAssetType.etf:
        return Icons.pie_chart;
      case InvestmentAssetType.cryptocurrency:
        return Icons.currency_bitcoin;
      case InvestmentAssetType.commodities:
        return Icons.landscape;
      case InvestmentAssetType.realEstate:
        return Icons.home;
      case InvestmentAssetType.cash:
        return Icons.attach_money;
    }
  }

  String _getAssetTypeDisplayName(String assetTypeName) {
    switch (assetTypeName.toLowerCase()) {
      case 'stocks':
        return '주식';
      case 'bonds':
        return '채권';
      case 'etf':
        return 'ETF';
      case 'cryptocurrency':
        return '암호화폐';
      case 'commodities':
        return '원자재';
      case 'realestate':
        return '부동산';
      case 'cash':
        return '현금';
      default:
        return assetTypeName;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showRebalanceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('포트폴리오 분석 포인트'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('현재 포트폴리오 점검 포인트:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('1. 위험도가 높은 자산 비중 변화 여부를 우선 점검하세요'),
                Text('2. 자산군 집중도와 분산 수준을 함께 확인하세요'),
                Text('3. 안전자산(채권, 현금) 비중의 변동 추이를 확인하세요'),
                Text('4. 정기적으로 동일 기준으로 포트폴리오를 비교 점검하세요'),
                SizedBox(height: 16),
                Text(
                  '※ 이는 일반적인 가이드라인이며, 개인의 투자성향과 목표에 따라 달라질 수 있습니다.\n'
                  '최종 투자 판단과 결과에 대한 모든 책임은 본인에게 있습니다.\n'
                  '투자 손실 또는 분쟁 발생 시 국내외(미국 포함)에서 민사상 분쟁/소송이 제기될 수 있습니다.\n'
                  '관련 법령이 허용하는 범위에서 앱 판매자/제공자는 직접·간접 손해에 대해 책임을 지지 않습니다.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
}