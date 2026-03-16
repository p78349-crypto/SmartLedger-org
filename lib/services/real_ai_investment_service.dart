import 'dart:convert';
import '../services/gemini_ai_service.dart';
import '../services/aicore_gemini_service.dart';
import '../services/ai_model_preferences_service.dart';
import '../config/ai_security_seal.dart';
import '../models/ai_investment_models.dart';
import '../models/asset.dart';

/// 실제 AI 기반 투자 참고정보 서비스 (Gemini 모델 활용)
/// 🔒 현재 보안상 이유로 AI 기능 봉인됨 (2026-02-21)
/// 하이브리드 AI: 수학적 계산 + AI 해석 결합
/// 사용자 설정에 따라 AI 모델 선택 가능
class RealAiInvestmentService {
  static final RealAiInvestmentService _instance = RealAiInvestmentService._internal();
  factory RealAiInvestmentService() => _instance;
  RealAiInvestmentService._internal();

  final GeminiAiService _geminiService = GeminiAiService.instance;
  final AICoreGeminiService _aicoreService = AICoreGeminiService();

  /// 사용자 설정 기반 AI 투자 참고정보 생성 (🔒 보안 봉인 적용)
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

  /// 오프라인 AI로 투자 참고정보 생성
  Future<Map<String, dynamic>> _getOfflineInvestmentAdvice(
    Map<String, dynamic> portfolioSnapshot) async {
    
    final prompt = _buildInvestmentAdvicePrompt(portfolioSnapshot, isOffline: true);
    
    try {
      final response = await _aicoreService.generateText(prompt);
      return _parseInvestmentResponse(response);
    } catch (e) {
      throw Exception('Offline AI investment reference information failed: $e');
    }
  }

  /// 온라인 AI로 투자 참고정보 생성  
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
      throw Exception('Online AI investment reference information failed: $e');
    }
  }

  /// AI 투자 참고정보를 위한 프롬프트 구성
  String _buildInvestmentAdvicePrompt(
    Map<String, dynamic> portfolioSnapshot, 
    {required bool isOffline}) {
    
    return '''
당신은 SmartLedger의 AI 투자 정보 분석 도우미입니다. 다음 포트폴리오를 분석하여 개인맞춤 참고정보를 제공하세요.

👤 **투자자 프로필:**
- 연령: ${portfolioSnapshot['age']}세
- 위험성향: ${portfolioSnapshot['riskLevel']} 
- 투자기간: ${portfolioSnapshot['timeHorizon']}
- 총 자산가치: ₩${portfolioSnapshot['totalValue']}

💼 **현재 포트폴리오:**
${portfolioSnapshot['allocationDetails']}

🎯 **요청사항:**
1. 현재 포트폴리오 평가 (강점/약점)
2. 현재 자산배분 현황 분석 (집중/분산 관점)
3. 투자 위험도 분석
4. 모니터링이 필요한 점검 항목
5. 데이터 해석 시 주의할 한계

📋 **응답 형식 (JSON):**
{
  "portfolio_evaluation": {
    "strengths": ["강점1", "강점2"],
    "weaknesses": ["약점1", "약점2"],
    "overall_score": 85
  },
  "allocation_snapshot": {
    "stocks": 40.0,
    "bonds": 30.0,
    "etf": 20.0,
    "cash": 10.0
  },
  "risk_analysis": {
    "current_risk_level": "medium",
    "monitoring_notes": ["점검사항1", "점검사항2"]
  },
  "analysis_points": {
    "monitoring_points": ["점검포인트1", "점검포인트2"],
    "data_limitations": ["한계1", "한계2"]
  },
  "confidence_level": 90,
  "ai_model": "${isOffline ? 'Gemini Nano (오프라인)' : 'Gemini 1.5 Flash (온라인)'}",
  "disclaimer": "본 내용은 투자 참고정보이며 투자 권유가 아닙니다. 최종 투자 판단과 책임은 사용자 본인에게 있습니다"
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
        'recommended_allocation':
          jsonResponse['recommended_allocation'] ??
          jsonResponse['allocation_snapshot'] ??
          {},
        'risk_analysis': jsonResponse['risk_analysis'] ?? {},
        'action_plan':
          jsonResponse['action_plan'] ??
          jsonResponse['analysis_points'] ??
          {},
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