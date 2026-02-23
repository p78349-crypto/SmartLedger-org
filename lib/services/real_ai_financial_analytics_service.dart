import 'dart:convert';
import '../services/gemini_ai_service.dart';
import '../services/aicore_gemini_service.dart';
import '../services/ai_model_preferences_service.dart';
import '../config/ai_security_seal.dart';
import '../models/financial_analytics_models.dart';
import '../models/transaction.dart';
import '../models/asset.dart';

/// 실제 AI 기반 고급 재무분석 서비스 (Gemini 모델 활용)
/// 🔒 현재 보안상 이유로 AI 기능 봉인됨 (2026-02-21)
/// 하이브리드 접근: 통계 계산 + AI 해석 + 예측 결합
/// 사용자 설정에 따라 AI 모델 선택 가능
class RealAiFinancialAnalyticsService {
  static final RealAiFinancialAnalyticsService _instance = RealAiFinancialAnalyticsService._internal();
  factory RealAiFinancialAnalyticsService() => _instance;
  RealAiFinancialAnalyticsService._internal();

  final GeminiAiService _geminiService = GeminiAiService.instance;
  final AICoreGeminiService _aicoreService = AICoreGeminiService();

  /// 사용자 설정 기반 AI 재무분석 인사이트 생성 (🔒 보안 봉인 적용)
  Future<Map<String, dynamic>> generateAiCashFlowInsights({
    required List<Transaction> transactions,
    required List<Asset> assets,
    required int forecastDays,
  }) async {
    // 🔒 보안 봉인 체크
    if (AiSecuritySeal.isSealed && !AiSecuritySeal.isDeveloperModeEnabled) {
      print('🔒 AI 기능 보안 봉인: 전통적 알고리즘만 사용');
      return _getFallbackFinancialInsights(transactions, assets);
    }
    final prefs = AiModelPreferencesService.instance;
    final shouldUseAi = await prefs.shouldUseAiFor(AiFeature.analytics);
    
    if (!shouldUseAi) {
      return _getFallbackFinancialInsights(transactions, assets);
    }

    final financialSnapshot = _prepareFinancialSnapshot(
      transactions, assets, forecastDays);
    final modelPriority = await prefs.getModelPriority();
    
    for (final model in modelPriority) {
      try {
        switch (model) {
          case AiModelType.geminiNano:
            if (await _aicoreService.isAvailable()) {
              return await _getOfflineFinancialInsights(financialSnapshot);
            }
            continue;
          case AiModelType.geminiFlasch:
            return await _getOnlineFinancialInsights(financialSnapshot);
          case AiModelType.traditional:
            return _getFallbackFinancialInsights(transactions, assets);
        }
      } catch (e) {
        print('AI 모델 $model 실패, 다음 모델 시도: $e');
        continue;
      }
    }

    // 모든 AI 모델 실패 시 전통적 알고리즘 사용
    return _getFallbackFinancialInsights(transactions, assets);
    }
  }

  /// 오프라인 AI로 재무 인사이트 생성
  Future<Map<String, dynamic>> _getOfflineFinancialInsights(
    Map<String, dynamic> financialSnapshot) async {
    
    final prompt = _buildFinancialAnalysisPrompt(financialSnapshot, isOffline: true);
    
    try {
      final response = await _aicoreService.generateText(prompt);
      return _parseFinancialResponse(response);
    } catch (e) {
      throw Exception('Offline AI financial analysis failed: $e');
    }
  }

  /// 온라인 AI로 재무 인사이트 생성
  Future<Map<String, dynamic>> _getOnlineFinancialInsights(
    Map<String, dynamic> financialSnapshot) async {
    
    final prompt = _buildFinancialAnalysisPrompt(financialSnapshot, isOffline: false);
    
    try {
      final response = await _geminiService.analyzeFinancialData(
        transactions: financialSnapshot['transactionSummary'],
        assets: financialSnapshot['assetSummary'],
        timeframe: financialSnapshot['timeframe'],
      );
      return _parseFinancialResponse(response);
    } catch (e) {
      throw Exception('Online AI financial analysis failed: $e');
    }
  }

  /// AI 재무분석을 위한 프롬프트 구성
  String _buildFinancialAnalysisPrompt(
    Map<String, dynamic> financialSnapshot, 
    {required bool isOffline}) {
    
    return '''
당신은 SmartLedger의 고급 AI 재무 분석관입니다. 다음 재무 데이터를 종합 분석하여 전문가 수준의 인사이트를 제공하세요.

📊 **재무 데이터 요약:**
${financialSnapshot['transactionSummary']}

💰 **자산 포트폴리오:**
${financialSnapshot['assetSummary']}

📈 **분석 기간:** ${financialSnapshot['timeframe']}

🎯 **고급 분석 요청사항:**
1. 현금흐름 패턴 분석 (계절성, 트렌드, 주기성)
2. 재무 건전성 평가 (유동성, 안정성, 성장성)
3. 미래 현금흐름 예측 (${financialSnapshot['forecastDays']}일간)
4. 잠재적 재무 위험 요소 식별
5. 최적화 기회 및 개선 방안
6. 시나리오별 대응 전략 (긍정/중립/부정)

📋 **응답 형식 (JSON):**
{
  "cashflow_patterns": {
    "seasonality": "계절성 패턴 분석",
    "trends": ["트렌드1", "트렌드2"],
    "cycles": "주기적 패턴",
    "anomalies": ["이상징후1", "이상징후2"]
  },
  "financial_health": {
    "liquidity_score": 85,
    "stability_score": 78,
    "growth_potential": 92,
    "overall_grade": "A-",
    "key_strengths": ["강점1", "강점2"],
    "areas_for_improvement": ["개선점1", "개선점2"]
  },
  "forecast": {
    "next_30_days": {
      "expected_inflow": 2500000,
      "expected_outflow": 2200000,
      "net_cashflow": 300000,
      "confidence_level": 85
    },
    "risk_scenarios": {
      "best_case": "최적 시나리오",
      "worst_case": "최악 시나리오",
      "most_likely": "가능성 높은 시나리오"
    }
  },
  "risk_factors": [
    {
      "risk": "위험요소명",
      "impact": "high/medium/low",
      "probability": "확률",
      "mitigation": "대응방안"
    }
  ],
  "optimization_opportunities": [
    {
      "area": "최적화 영역",
      "potential_benefit": "예상 효과",
      "implementation": "실행 방법"
    }
  ],
  "strategic_recommendations": {
    "immediate_actions": ["즉시 실행 사항1", "즉시 실행 사항2"],
    "short_term_goals": ["단기 목표1", "단기 목표2"],
    "long_term_vision": ["장기 비전1", "장기 비전2"]
  },
  "confidence_metrics": {
    "data_quality": 90,
    "prediction_accuracy": 85,
    "analysis_depth": 95
  },
  "ai_model": "${isOffline ? 'Gemini Nano (오프라인)' : 'Gemini 1.5 Flash (온라인)'}",
  "analysis_timestamp": "${DateTime.now().toIso8601String()}",
  "disclaimer": "본 분석은 AI 기반 예측이며, 실제 결과는 다를 수 있습니다"
}''';
  }

  Map<String, dynamic> _prepareFinancialSnapshot(
    List<Transaction> transactions,
    List<Asset> assets,
    int forecastDays,
  ) {
    // 거래 데이터 요약
    final totalIncome = transactions.where((t) => t.amount > 0)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalExpense = transactions.where((t) => t.amount < 0)
        .fold(0.0, (sum, t) => sum + t.amount.abs());
    final netFlow = totalIncome - totalExpense;
    
    // 자산 요약
    final totalAssetValue = assets.fold(0.0, (sum, asset) => sum + asset.currentValue);
    final assetTypeDistribution = <String, int>{};
    for (final asset in assets) {
      assetTypeDistribution[asset.assetType] = 
          (assetTypeDistribution[asset.assetType] ?? 0) + 1;
    }
    
    final transactionSummary = '''
• 총 거래 건수: ${transactions.length}건
• 총 수입: ₩${totalIncome.toStringAsFixed(0)}
• 총 지출: ₩${totalExpense.toStringAsFixed(0)}  
• 순 현금흐름: ₩${netFlow.toStringAsFixed(0)}
• 평균 거래액: ₩${(transactions.isNotEmpty ? (totalIncome + totalExpense) / transactions.length : 0).toStringAsFixed(0)}''';
    
    final assetSummary = '''
• 총 자산가치: ₩${totalAssetValue.toStringAsFixed(0)}
• 자산 종류: ${assetTypeDistribution.keys.join(', ')}
• 보유 자산 수: ${assets.length}개
• 자산 분포: ${assetTypeDistribution.entries.map((e) => '${e.key} ${e.value}개').join(', ')}''';
    
    return {
      'transactionSummary': transactionSummary,
      'assetSummary': assetSummary,
      'timeframe': '${transactions.isNotEmpty ? transactions.first.dateTime.toString().split(' ')[0] : 'N/A'} ~ ${transactions.isNotEmpty ? transactions.last.dateTime.toString().split(' ')[0] : 'N/A'}',
      'forecastDays': forecastDays,
    };
  }

  Map<String, dynamic> _parseFinancialResponse(String response) {
    try {
      final jsonResponse = jsonDecode(response);
      return {
        'success': true,
        'ai_generated': true,
        'patterns': jsonResponse['cashflow_patterns'] ?? {},
        'health': jsonResponse['financial_health'] ?? {},
        'forecast': jsonResponse['forecast'] ?? {},
        'risks': jsonResponse['risk_factors'] ?? [],
        'opportunities': jsonResponse['optimization_opportunities'] ?? [],
        'recommendations': jsonResponse['strategic_recommendations'] ?? {},
        'confidence': jsonResponse['confidence_metrics'] ?? {},
        'ai_model': jsonResponse['ai_model'] ?? 'Unknown',
        'timestamp': jsonResponse['analysis_timestamp'] ?? DateTime.now().toIso8601String(),
        'disclaimer': jsonResponse['disclaimer'] ?? '',
      };
    } catch (e) {
      return {
        'success': false,
        'ai_generated': false,
        'error': 'AI 응답 파싱 실패: $e',
        'confidence': {'analysis_depth': 0},
      };
    }
  }

  Map<String, dynamic> _getFallbackFinancialInsights(
    List<Transaction> transactions,
    List<Asset> assets,
  ) {
    return {
      'success': true,
      'ai_generated': false,
      'patterns': {
        'seasonality': '기본 통계 분석 결과',
        'trends': ['전통적 알고리즘 기반 트렌드'],
      },
      'health': {
        'overall_grade': 'B',
        'key_strengths': ['기본 재무 데이터 보유'],
        'areas_for_improvement': ['AI 분석 서비스 활성화 필요'],
      },
      'confidence': {'analysis_depth': 50},
      'ai_model': 'Fallback Statistical Analysis',
    };
  }
}