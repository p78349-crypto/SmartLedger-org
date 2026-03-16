import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ai_investment_service.dart';
import '../models/ai_investment_models.dart';
import '../utils/pref_keys.dart';

part 'ai_investment_advisor_screen_extensions.dart';
part 'ai_investment_advisor_screen_utils.dart';
part 'ai_investment_advisor_screen_helpers.dart';

/// AI 투자 참고정보 화면
/// 포트폴리오 분석 및 AI 기반 참고정보 제공
class AiInvestmentAdvisorScreen extends StatefulWidget {
  const AiInvestmentAdvisorScreen({super.key});

  @override
  State<AiInvestmentAdvisorScreen> createState() => _AiInvestmentAdvisorScreenState();
}

class _AiInvestmentAdvisorScreenState extends State<AiInvestmentAdvisorScreen> {
  final AiInvestmentService _investmentService = AiInvestmentService();
  static const String _consentVersion = 'ai_investment_notice_2026_02_28_v1';
  
  bool _isLoading = false;
  bool _consentChecked = false;
  PortfolioAnalysis? _portfolioAnalysis;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkConsentThenLoad();
    });
  }

  Future<void> _checkConsentThenLoad() async {
    final canProceed = await _ensureInvestmentConsent();
    if (!mounted) return;

    if (!canProceed) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() => _consentChecked = true);
    _loadPortfolioAnalysis();
  }

  Future<bool> _ensureInvestmentConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final accepted = prefs.getBool(PrefKeys.aiInvestmentConsentAccepted) ?? false;
    final savedVersion = prefs.getString(PrefKeys.aiInvestmentConsentVersion) ?? '';

    if (accepted && savedVersion == _consentVersion) {
      return true;
    }

    if (!mounted) return false;

    bool agreed = false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('AI 투자 분석 고지 및 동의'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('본 기능은 투자 분석 참고자료 제공용이며 투자 권유가 아닙니다.'),
                    const SizedBox(height: 8),
                    const Text('개별 종목 추천, 매수/매도 지시, 진입시점 제시는 제공하지 않습니다.'),
                    const SizedBox(height: 8),
                    const Text('최종 투자 판단과 결과 책임은 사용자 본인에게 있으며, 관련 법령 허용 범위에서 앱 판매자/제공자는 직접·간접 손해 책임을 지지 않습니다.'),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: agreed,
                      onChanged: (value) {
                        setDialogState(() {
                          agreed = value ?? false;
                        });
                      },
                      title: const Text('위 내용을 확인하고 동의합니다.'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: agreed
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: const Text('동의 후 계속'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true) {
      return false;
    }

    if (!mounted) return false;
    final localeTag = Localizations.localeOf(context).toLanguageTag();
    await prefs.setBool(PrefKeys.aiInvestmentConsentAccepted, true);
    await prefs.setInt(
      PrefKeys.aiInvestmentConsentAcceptedAtMs,
      DateTime.now().millisecondsSinceEpoch,
    );
    await prefs.setString(PrefKeys.aiInvestmentConsentVersion, _consentVersion);
    await prefs.setString(PrefKeys.aiInvestmentConsentLocale, localeTag);
    return true;
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
    if (!_consentChecked) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI 투자 참고정보'),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 투자 참고정보'),
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