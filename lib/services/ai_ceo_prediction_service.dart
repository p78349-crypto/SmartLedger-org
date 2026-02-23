import 'dart:convert';
import '../services/gemini_ai_service.dart';
import '../services/aicore_gemini_service.dart';
import '../services/ai_model_preferences_service.dart';
import '../config/ai_security_seal.dart';
import '../models/transaction.dart';
import '../models/asset.dart';

/// AI 기반 CEO 예측 서비스 (실제 Gemini 모델 사용)
/// 🔒 현재 보안상 이유로 AI 기능 봉인됨 (2026-02-21)
/// 하이브리드 접근: 로컬 계산 + AI 인사이트 결합
/// 사용자 설정에 따라 AI 모델 선택 가능
class AiCeoPredictionService {
  static final AiCeoPredictionService _instance = AiCeoPredictionService._internal();
  factory AiCeoPredictionService() => _instance;
  AiCeoPredictionService._internal();

  final GeminiAiService _geminiService = GeminiAiService.instance;
  final AICoreGeminiService _aicoreService = AICoreGeminiService();

  /// 사용자 설정 기반 AI 인사이트 생성 (🔒 보안 봉인 적용)
  Future<Map<String, dynamic>> generateAiInsights({
    required List<Transaction> transactions,
    required List<Asset> assets,
    required double weeklyTrend,
  }) async {
    // 🔒 보안 봉인 체크
    if (AiSecuritySeal.isSealed && !AiSecuritySeal.isDeveloperModeEnabled) {
      print('🔒 AI 기능 보안 봉인: 전통적 알고리즘만 사용');
      return _getFallbackInsights(transactions, assets, weeklyTrend);
    }
    final prefs = AiModelPreferencesService.instance;
    final shouldUseAi = await prefs.shouldUseAiFor(AiFeature.ceoPrediction);
    
    if (!shouldUseAi) {
      return _getFallbackInsights(transactions, assets, weeklyTrend);
    }

    final dataSnapshot = _prepareDataSnapshot(transactions, assets, weeklyTrend);
    final modelPriority = await prefs.getModelPriority();
    
    for (final model in modelPriority) {
      try {
        switch (model) {
          case AiModelType.geminiNano:
            if (await _aicoreService.isAvailable()) {
              return await _getOfflineAiInsights(dataSnapshot);
            }
            continue;
          case AiModelType.geminiFlasch:
            return await _getOnlineAiInsights(dataSnapshot);
          case AiModelType.traditional:
            return _getFallbackInsights(transactions, assets, weeklyTrend);
        }
      } catch (e) {
        print('AI 모델 $model 실패, 다음 모델 시도: $e');
        continue;
      }
    }

    // 모든 AI 모델 실패 시 전통적 알고리즘 사용
    return _getFallbackInsights(transactions, assets, weeklyTrend);
  }

  /// 오프라인 AI (Gemini Nano)로 인사이트 생성
  Future<Map<String, dynamic>> _getOfflineAiInsights(Map<String, dynamic> dataSnapshot) async {
    final prompt = _buildCeoInsightPrompt(dataSnapshot, isOffline: true);
    
    try {
      // AiCore를 통한 온디바이스 AI 호출
      final response = await _aicoreService.generateText(prompt);
      return _parseAiResponse(response);
    } catch (e) {
      throw Exception('Offline AI insight generation failed: $e');
    }
  }

  /// 온라인 AI (Gemini 1.5 Flash)로 인사이트 생성
  Future<Map<String, dynamic>> _getOnlineAiInsights(Map<String, dynamic> dataSnapshot) async {
    final prompt = _buildCeoInsightPrompt(dataSnapshot, isOffline: false);
    
    try {
      final response = await _geminiService.analyzeBusiness(
        prompt: prompt,
        context: 'CEO_WEEKLY_INSIGHTS',
      );
      return _parseAiResponse(response);
    } catch (e) {
      throw Exception('Online AI insight generation failed: $e');
    }
  }

  /// CEO를 위한 AI 프롬프트 구성
  String _buildCeoInsightPrompt(Map<String, dynamic> dataSnapshot, {required bool isOffline}) {
    final basePrompt = '''
당신은 SmartLedger의 CEO 전용 AI 비서입니다. 다음 재무 데이터를 분석하여 경영진 수준의 인사이트를 제공하세요.

📊 **현재 데이터 스냅샷:**
- 주간 거래 건수: ${dataSnapshot['transactionCount']}건
- 주간 현금흐름: ₩${dataSnapshot['weeklyFlow']}
- 총 자산가치: ₩${dataSnapshot['totalAssets']}
- 트렌드: ${dataSnapshot['trend']}

🎯 **요청사항:**
1. 핵심 비즈니스 인사이트 3가지
2. 잠재적 위험 요소 분석
3. 다음 주 실행 권장사항
4. 투자 기회 평가

📋 **응답 형식 (JSON):**
{
  "insights": ["인사이트1", "인사이트2", "인사이트3"],
  "risks": ["위험요소1", "위험요소2"],
  "recommendations": ["권장사항1", "권장사항2", "권장사항3"],
  "investment_opportunities": ["투자기회1", "투자기회2"],
  "confidence_level": 85,
  "ai_model": "${isOffline ? 'Gemini Nano (오프라인)' : 'Gemini 1.5 Flash (온라인)'}"
}''';

    return basePrompt;
  }

  Map<String, dynamic> _prepareDataSnapshot(
    List<Transaction> transactions, 
    List<Asset> assets, 
    double weeklyTrend,
  ) {
    final totalAssets = assets.fold(0.0, (sum, asset) => sum + asset.currentValue);
    final weeklyFlow = transactions.fold(0.0, (sum, tx) => sum + tx.amount);
    
    return {
      'transactionCount': transactions.length,
      'weeklyFlow': weeklyFlow.toStringAsFixed(0),
      'totalAssets': totalAssets.toStringAsFixed(0),
      'trend': weeklyTrend > 0 ? '상승 (+${weeklyTrend.toStringAsFixed(1)})' : '하락 (${weeklyTrend.toStringAsFixed(1)})',
    };
  }

  Map<String, dynamic> _parseAiResponse(String response) {
    try {
      // JSON 응답 파싱 시도
      final jsonResponse = jsonDecode(response);
      return {
        'success': true,
        'ai_generated': true,
        'insights': jsonResponse['insights'] ?? [],
        'risks': jsonResponse['risks'] ?? [],
        'recommendations': jsonResponse['recommendations'] ?? [],
        'investment_opportunities': jsonResponse['investment_opportunities'] ?? [],
        'confidence_level': jsonResponse['confidence_level'] ?? 75,
        'ai_model': jsonResponse['ai_model'] ?? 'Unknown',
      };
    } catch (e) {
      // JSON 파싱 실패 시 텍스트 기반 파싱
      return {
        'success': true,
        'ai_generated': true,
        'insights': [response.substring(0, 200) + '...'],
        'risks': ['AI 응답 파싱 중 일부 정보 손실'],
        'recommendations': ['상세 분석을 위해 다시 시도해주세요'],
        'confidence_level': 50,
      };
    }
  }

  Map<String, dynamic> _getFallbackInsights(
    List<Transaction> transactions, 
    List<Asset> assets, 
    double weeklyTrend,
  ) {
    return {
      'success': true,
      'ai_generated': false,
      'insights': [
        '전통적 알고리즘 기반 분석 결과',
        '${transactions.length}건의 거래 데이터 처리 완료',
        '${assets.length}개 자산 포트폴리오 분석 완료'
      ],
      'risks': ['AI 서비스 일시 사용불가'],
      'recommendations': ['AI 모델 상태를 확인하고 다시 시도하세요'],
      'confidence_level': 60,
      'ai_model': 'Fallback Algorithm',
    };
  }
}