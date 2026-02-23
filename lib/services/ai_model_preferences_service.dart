import 'package:shared_preferences/shared_preferences.dart';
import '../config/ai_security_seal.dart';
import 'ai_audit_logger.dart';

/// AI 모델 사용 설정을 관리하는 서비스
/// 🔒 현재 보안상 이유로 AI 기능 봉인됨 (2026-02-21)
/// 사용자가 각 기능별로 AI 사용 여부와 모델 우선순위를 설정할 수 있음
class AiModelPreferencesService {
  static const String _keyUseAiForCeo = 'use_ai_for_ceo_prediction';
  static const String _keyUseAiForInvestment = 'use_ai_for_investment';
  static const String _keyUseAiForAnalytics = 'use_ai_for_analytics';
  static const String _keyPreferOfflineAi = 'prefer_offline_ai';
  static const String _keyAiEnabled = 'ai_features_enabled';

  static AiModelPreferencesService? _instance;
  static AiModelPreferencesService get instance {
    _instance ??= AiModelPreferencesService._();
    return _instance!;
  }
  
  AiModelPreferencesService._();

  SharedPreferences? _prefs;

  /// 설정 서비스 초기화
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// CEO 예측 분석에 AI 사용 여부 (🔒 보안 봉인 적용)
  Future<bool> get useAiForCeoPrediction async {
    if (AiSecuritySeal.isSealed && !AiSecuritySeal.isDeveloperModeEnabled) {
      return false; // 보안 봉인으로 인한 강제 비활성화
    }
    await initialize();
    return _prefs?.getBool(_keyUseAiForCeo) ?? true;
  }

  /// CEO 예측 분석 AI 사용 설정
  Future<void> setUseAiForCeoPrediction(bool value) async {
    await initialize();
    await _prefs?.setBool(_keyUseAiForCeo, value);
  }

  /// 투자 자문에 AI 사용 여부 (🔒 보안 봉인 적용)
  Future<bool> get useAiForInvestment async {
    if (AiSecuritySeal.isSealed && !AiSecuritySeal.isDeveloperModeEnabled) {
      return false; // 보안 봉인으로 인한 강제 비활성화
    }
    await initialize();
    return _prefs?.getBool(_keyUseAiForInvestment) ?? true;
  }

  /// 투자 자문 AI 사용 설정
  Future<void> setUseAiForInvestment(bool value) async {
    await initialize();
    await _prefs?.setBool(_keyUseAiForInvestment, value);
  }

  /// 재무 분석에 AI 사용 여부 (🔒 보안 봉인 적용)
  Future<bool> get useAiForAnalytics async {
    if (AiSecuritySeal.isSealed && !AiSecuritySeal.isDeveloperModeEnabled) {
      return false; // 보안 봉인으로 인한 강제 비활성화
    }
    await initialize();
    return _prefs?.getBool(_keyUseAiForAnalytics) ?? true;
  }

  /// 재무 분석 AI 사용 설정
  Future<void> setUseAiForAnalytics(bool value) async {
    await initialize();
    await _prefs?.setBool(_keyUseAiForAnalytics, value);
  }

  /// 오프라인 AI 우선 사용 여부 (Gemini Nano)
  Future<bool> get preferOfflineAi async {
    await initialize();
    return _prefs?.getBool(_keyPreferOfflineAi) ?? true;
  }

  /// 오프라인 AI 우선순위 설정
  Future<void> setPreferOfflineAi(bool value) async {
    await initialize();
    await _prefs?.setBool(_keyPreferOfflineAi, value);
  }

  /// 전체 AI 기능 활성화 여부 (🔒 보안 봉인 적용)
  Future<bool> get aiEnabled async {
    if (AiSecuritySeal.isSealed && !AiSecuritySeal.isDeveloperModeEnabled) {
      return false; // 보안 봉인으로 인한 강제 비활성화
    }
    await initialize();
    return _prefs?.getBool(_keyAiEnabled) ?? true;
  }

  /// 전체 AI 기능 활성화 설정
  Future<void> setAiEnabled(bool value) async {
    await initialize();
    await _prefs?.setBool(_keyAiEnabled, value);
  }

  /// 특정 기능에 대한 AI 사용 여부 확인 (규제 준수 체크 포함)
  Future<bool> shouldUseAiFor(AiFeature feature) async {
    // 🌍 글로벌 규제 준수 체크
    await AiAuditLogger.logComplianceCheck(
      region: 'GLOBAL',
      regulation: 'EU_AI_Act + Global_Regulations',
      isCompliant: false, // AI 기능 비활성화로 인한 준수 상태
      details: 'AI feature disabled for regulatory compliance',
    );
    
    final aiEnabled = await this.aiEnabled;
    if (!aiEnabled) return false;

    switch (feature) {
      case AiFeature.ceoPrediction:
        return await useAiForCeoPrediction;
      case AiFeature.investment:
        return await useAiForInvestment;
      case AiFeature.analytics:
        return await useAiForAnalytics;
    }
  }

  /// AI 모델 우선순위 결정
  /// 오프라인 우선이면 Gemini Nano -> Gemini Flash 순서
  /// 온라인 우선이면 Gemini Flash -> Gemini Nano 순서
  Future<List<AiModelType>> getModelPriority() async {
    final preferOffline = await preferOfflineAi;
    
    if (preferOffline) {
      return [AiModelType.geminiNano, AiModelType.geminiFlasch, AiModelType.traditional];
    } else {
      return [AiModelType.geminiFlasch, AiModelType.geminiNano, AiModelType.traditional];
    }
  }

  /// 모든 설정을 기본값으로 리셋
  Future<void> resetToDefaults() async {
    await initialize();
    await _prefs?.remove(_keyUseAiForCeo);
    await _prefs?.remove(_keyUseAiForInvestment);
    await _prefs?.remove(_keyUseAiForAnalytics);
    await _prefs?.remove(_keyPreferOfflineAi);
    await _prefs?.remove(_keyAiEnabled);
  }

  /// 설정 요약 정보
  Future<Map<String, dynamic>> getSettingsSummary() async {
    return {
      'aiEnabled': await aiEnabled,
      'useAiForCeoPrediction': await useAiForCeoPrediction,
      'useAiForInvestment': await useAiForInvestment,
      'useAiForAnalytics': await useAiForAnalytics,
      'preferOfflineAi': await preferOfflineAi,
      'modelPriority': (await getModelPriority()).map((m) => m.name).toList(),
    };
  }
}

/// AI 기능 유형
enum AiFeature {
  ceoPrediction,
  investment,
  analytics,
}

/// AI 모델 유형
enum AiModelType {
  geminiNano('Gemini Nano'),
  geminiFlasch('Gemini 1.5 Flash'),
  traditional('Traditional Algorithm');

  const AiModelType(this.displayName);
  final String displayName;
}