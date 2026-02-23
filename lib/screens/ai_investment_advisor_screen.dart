import 'package:flutter/material.dart';
import '../services/ai_investment_service.dart';
import '../models/ai_investment_models.dart';

part 'ai_investment_advisor_screen_extensions.dart';
part 'ai_investment_advisor_screen_utils.dart';
part 'ai_investment_advisor_screen_helpers.dart';

/// AI 투자 자문 화면
/// 포트폴리오 분석 및 AI 기반 투자 추천 제공
class AiInvestmentAdvisorScreen extends StatefulWidget {
  const AiInvestmentAdvisorScreen({super.key});

  @override
  State<AiInvestmentAdvisorScreen> createState() => _AiInvestmentAdvisorScreenState();
}

class _AiInvestmentAdvisorScreenState extends State<AiInvestmentAdvisorScreen> {
  final AiInvestmentService _investmentService = AiInvestmentService();
  
  bool _isLoading = false;
  PortfolioAnalysis? _portfolioAnalysis;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPortfolioAnalysis();
  }

  Future<void> _loadPortfolioAnalysis() async {
    setState(() => _isLoading = true);
    
    try {
      final analysis = await _investmentService.analyzePortfolio();
      setState(() {
        _portfolioAnalysis = analysis;
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
        title: const Text('AI 투자자문'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadPortfolioAnalysis,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _portfolioAnalysis != null
                  ? _buildAnalysisContent()
                  : const Center(child: Text('분석 중...')),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('분석 중 오류가 발생했습니다:\n$_errorMessage', 
                 textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPortfolioAnalysis,
              child: const Text('다시 분석'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPortfolioOverviewCard(),
          const SizedBox(height: 16),
          _buildRiskAnalysisCard(),
          const SizedBox(height: 16),
          _buildAllocationChart(),
          const SizedBox(height: 16),
          _buildRecommendationsCard(),
          const SizedBox(height: 16),
          if (_portfolioAnalysis!.rebalanceRequired)
            _buildRebalanceWarningCard(),
          const SizedBox(height: 16),
          _buildOfflineNoticeCard(),
        ],
      ),
    );
  }
}