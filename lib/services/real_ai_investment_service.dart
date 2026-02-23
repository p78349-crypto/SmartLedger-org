import 'dart:convert';
import '../services/gemini_ai_service.dart';
import '../services/aicore_gemini_service.dart';
import '../services/ai_model_preferences_service.dart';
import '../config/ai_security_seal.dart';
import '../models/ai_investment_models.dart';
import '../models/asset.dart';

/// 실제 AI 기반 투자 자문 서비스 (Gemini 모델 활용)
/// 🔒 현재 보안상 이유로 AI 기능 봉인됨 (2026-02-21)
/// 하이브리드 AI: 수학적 계산 + AI 해석 결합
/// 사용자 설정에 따라 AI 모델 선택 가능
class RealAiInvestmentService {
  static final RealAiInvestmentService _instance = RealAiInvestmentService._internal();
  factory RealAiInvestmentService() => _instance;
  RealAiInvestmentService._internal();

  final GeminiAiService _geminiService = GeminiAiService.instance;
  final AICoreGeminiService _aicoreService = AICoreGeminiService();

  /// 사용자 설정 기반 AI 투자 자문 생성 (🔒 보안 봉인 적용)
  Future<Map<String, dynamic>> generateAiInvestmentAdvice({
    required List<Asset> assets,
    required Map<InvestmentAssetType, double> currentAllocation,
    required InvestmentRiskLevel riskLevel,
    required InvestmentTimeHorizon timeHorizon,
    required double userAge,
  }) async {
    // 🔒 보안 봉인 체크
    if (AiSecuritySeal.isSealed && !AiSecuritySeal.isDeveloperModeEnabled) {
      print('🔒 AI 기능 보안 봉인: 전통적 알고리즘만 사용');
      return _getFallbackInvestmentAdvice(assets, currentAllocation);
    }
    final prefs = AiModelPreferencesService.instance;
    final shouldUseAi = await prefs.shouldUseAiFor(AiFeature.investment);
    
    if (!shouldUseAi) {
      return _getFallbackInvestmentAdvice(assets, currentAllocation);
    }

    final portfolioSnapshot = _preparePortfolioSnapshot(
      assets, currentAllocation, riskLevel, timeHorizon, userAge);
    final modelPriority = await prefs.getModelPriority();
    
    for (final model in modelPriority) {
      try {
        switch (model) {
          case AiModelType.geminiNano:
            if (await _aicoreService.isAvailable()) {
              return await _getOfflineInvestmentAdvice(portfolioSnapshot);
            }
            continue;
          case AiModelType.geminiFlasch:
            return await _getOnlineInvestmentAdvice(portfolioSnapshot);
          case AiModelType.traditional:
            return _getFallbackInvestmentAdvice(assets, currentAllocation);
        }
      } catch (e) {
        print('AI 모델 $model 실패, 다음 모델 시도: $e');
        continue;
      }
    }

    // 모든 AI 모델 실패 시 전통적 알고리즘 사용
    return _getFallbackInvestmentAdvice(assets, currentAllocation);
    }
  }

  /// 오프라인 AI로 투자 조언 생성
  Future<Map<String, dynamic>> _getOfflineInvestmentAdvice(
    Map<String, dynamic> portfolioSnapshot) async {
    
    final prompt = _buildInvestmentAdvicePrompt(portfolioSnapshot, isOffline: true);
    
    try {
      final response = await _aicoreService.generateText(prompt);
      return _parseInvestmentResponse(response);
    } catch (e) {
      throw Exception('Offline AI investment advice failed: $e');
    }
  }

  /// 온라인 AI로 투자 조언 생성  
  Future<Map<String, dynamic>> _getOnlineInvestmentAdvice(
    Map<String, dynamic> portfolioSnapshot) async {
    
    final prompt = _buildInvestmentAdvicePrompt(portfolioSnapshot, isOffline: false);
    
    try {
      final response = await _geminiService.analyzeInvestment(
        portfolioData: portfolioSnapshot,
        riskLevel: portfolioSnapshot['riskLevel'],
        timeHorizon: portfolioSnapshot['timeHorizon'],
      );
      return _parseInvestmentResponse(response);
    } catch (e) {
      throw Exception('Online AI investment advice failed: $e');
    }
  }

  /// AI 투자 자문을 위한 프롬프트 구성
  String _buildInvestmentAdvicePrompt(
    Map<String, dynamic> portfolioSnapshot, 
    {required bool isOffline}) {
    
    return '''
당신은 SmartLedger의 전문 AI 투자 자문관입니다. 다음 포트폴리오를 분석하여 개인맞춤 투자 조언을 제공하세요.

👤 **투자자 프로필:**
- 연령: ${portfolioSnapshot['age']}세
- 위험성향: ${portfolioSnapshot['riskLevel']} 
- 투자기간: ${portfolioSnapshot['timeHorizon']}
- 총 자산가치: ₩${portfolioSnapshot['totalValue']}

💼 **현재 포트폴리오:**
${portfolioSnapshot['allocationDetails']}

🎯 **요청사항:**
1. 현재 포트폴리오 평가 (강점/약점)
2. 맞춤형 자산배분 제안 (구체적 비율)
3. 투자 위험도 분석
4. 단계별 포트폴리오 개선 방안
5. 시장 상황 고려한 타이밍 조언

📋 **응답 형식 (JSON):**
{
  "portfolio_evaluation": {
    "strengths": ["강점1", "강점2"],
    "weaknesses": ["약점1", "약점2"],
    "overall_score": 85
  },
  "recommended_allocation": {
    "stocks": 40.0,
    "bonds": 30.0,
    "etf": 20.0,
    "cash": 10.0
  },
  "risk_analysis": {
    "current_risk_level": "medium",
    "recommended_adjustments": ["조정사항1", "조정사항2"]
  },
  "action_plan": {
    "immediate_actions": ["즉시실행1", "즉시실행2"],
    "medium_term_goals": ["중기목표1", "중기목표2"]
  },
  "market_timing": {
    "current_market_view": "시장전망",
    "entry_points": ["진입시점1", "진입시점2"]
  },
  "confidence_level": 90,
  "ai_model": "${isOffline ? 'Gemini Nano (오프라인)' : 'Gemini 1.5 Flash (온라인)'}",
  "disclaimer": "본 조언은 AI 분석 결과이며, 실제 투자 시 전문가 상담을 권장합니다"
}''';
  }

  Map<String, dynamic> _preparePortfolioSnapshot(
    List<Asset> assets,
    Map<InvestmentAssetType, double> allocation,
    InvestmentRiskLevel riskLevel,
    InvestmentTimeHorizon timeHorizon,
    double userAge,
  ) {
    final totalValue = assets.fold(0.0, (sum, asset) => sum + asset.currentValue);
    
    final allocationDetails = allocation.entries
        .map((e) => '• ${_getAssetTypeKorean(e.key)}: ${e.value.toStringAsFixed(1)}%')
        .join('\n');
    
    return {
      'age': userAge.toInt(),
      'riskLevel': _getRiskLevelKorean(riskLevel),
      'timeHorizon': _getTimeHorizonKorean(timeHorizon), 
      'totalValue': totalValue.toStringAsFixed(0),
      'allocationDetails': allocationDetails,
      'assetCount': assets.length,
    };
  }

  Map<String, dynamic> _parseInvestmentResponse(String response) {
    try {
      final jsonResponse = jsonDecode(response);
      return {
        'success': true,
        'ai_generated': true,
        'evaluation': jsonResponse['portfolio_evaluation'] ?? {},
        'recommended_allocation': jsonResponse['recommended_allocation'] ?? {},
        'risk_analysis': jsonResponse['risk_analysis'] ?? {},
        'action_plan': jsonResponse['action_plan'] ?? {},
        'market_timing': jsonResponse['market_timing'] ?? {},
        'confidence_level': jsonResponse['confidence_level'] ?? 75,
        'ai_model': jsonResponse['ai_model'] ?? 'Unknown',
        'disclaimer': jsonResponse['disclaimer'] ?? '',
      };
    } catch (e) {
      return {
        'success': false,
        'ai_generated': false,
        'error': 'AI 응답 파싱 실패: $e',
        'confidence_level': 0,
      };
    }
  }

  Map<String, dynamic> _getFallbackInvestmentAdvice(
    List<Asset> assets,
    Map<InvestmentAssetType, double> allocation,
  ) {
    return {
      'success': true,
      'ai_generated': false,
      'evaluation': {
        'strengths': ['다양한 자산 보유', '기본적 포트폴리오 구성'],
        'weaknesses': ['AI 분석 서비스 일시 중단'],
        'overall_score': 70,
      },
      'recommended_allocation': allocation,
      'confidence_level': 50,
      'ai_model': 'Fallback Algorithm',
      'disclaimer': '전통적 알고리즘 기반 결과입니다',
    };
  }

  String _getAssetTypeKorean(InvestmentAssetType type) {
    switch (type) {
      case InvestmentAssetType.stocks: return '주식';
      case InvestmentAssetType.bonds: return '채권';
      case InvestmentAssetType.etf: return 'ETF';
      case InvestmentAssetType.cryptocurrency: return '암호화폐';
      case InvestmentAssetType.commodities: return '원자재';
      case InvestmentAssetType.realEstate: return '부동산';
      case InvestmentAssetType.cash: return '현금';
    }
  }

  String _getRiskLevelKorean(InvestmentRiskLevel level) {
    switch (level) {
      case InvestmentRiskLevel.conservative: return '안전형';
      case InvestmentRiskLevel.moderate: return '균형형';
      case InvestmentRiskLevel.aggressive: return '적극형';
      case InvestmentRiskLevel.speculative: return '공격형';
    }
  }

  String _getTimeHorizonKorean(InvestmentTimeHorizon horizon) {
    switch (horizon) {
      case InvestmentTimeHorizon.shortTerm: return '단기 (1-2년)';
      case InvestmentTimeHorizon.mediumTerm: return '중기 (3-7년)';
      case InvestmentTimeHorizon.longTerm: return '장기 (8년 이상)';
    }
  }
}