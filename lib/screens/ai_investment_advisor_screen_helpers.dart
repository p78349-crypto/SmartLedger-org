part of 'ai_investment_advisor_screen.dart';

/// AI 투자자문 화면 추가 유틸리티들
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
          title: const Text('포트폴리오 재조정 가이드'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('현재 포트폴리오 개선 방안:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('1. 위험도가 높은 자산의 비중을 줄이세요'),
                Text('2. 다양한 자산군에 분산투자하세요'),
                Text('3. 안전자산(채권, 현금)의 비중을 늘리세요'),
                Text('4. 정기적으로 포트폴리오를 점검하세요'),
                SizedBox(height: 16),
                Text('※ 이는 일반적인 가이드라인이며, 개인의 투자성향과 목표에 따라 달라질 수 있습니다.', 
                     style: TextStyle(fontSize: 12, color: Colors.grey)),
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