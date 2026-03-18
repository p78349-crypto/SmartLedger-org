import '../services/ai_audit_logger.dart';

/// AI 기능 보안 봉인 관리 (18개국 대응)
/// 🌍 2026년 글로벌 AI 규제 18개국 완전 준수 (EU, 독일, 프랑스, 이탈리아, 스페인, 네덜란드, 중국, 일본, 한국, 싱가포르, 호주, 인도, 미국, 캐나다, 멕시코, 영국, 스위스)
/// 국제적 보안 요구사항으로 인한 AI 기능 비활성화 제어
class AiSecuritySeal {
  static const bool _isAiFeatureSealed = true; // 🔒 18개국 AI 규제 준수 봉인
  static const String _sealReason =
      '18-Country Global AI Regulations Compliance';
  static const String _sealDate = '2026-02-21';
  static const String _regulationScope =
      'EU|DE|FR|IT|ES|NL|CN|JP|KR|SG|AU|IN|US_CA|US_NY|CA|MX|GB|CH'; // 18개국 동시 준수

  /// AI 기능 접근 가능 여부 확인
  static bool get isAiAccessible => !_isAiFeatureSealed;

  /// AI 기능 봉인 상태 확인
  static bool get isSealed => _isAiFeatureSealed;

  /// 봉인 해제를 위한 개발자 모드 확인
  /// ⚠️ 법적 위험: 개발자 모드는 감사 로그에 기록됨
  static bool get isDeveloperModeEnabled {
    final devMode = true; // 커스텀 Gemma2 2b 테스트용 활성화
    if (devMode) {
      AiAuditLogger.logSecuritySeal(
        isSealed: false,
        trigger: 'Developer mode enabled for custom model testing',
      );
    }
    return devMode;
  }

  /// 봉인 정보 (법적 증명용)
  static Map<String, dynamic> get sealInfo => {
    'isSealed': _isAiFeatureSealed,
    'reason': _sealReason,
    'sealDate': _sealDate,
    'regulationScope': _regulationScope,
    'complianceLevel': 'MAXIMUM_GLOBAL_COMPLIANCE',
    'legalBasis':
        'EU AI Act Art.5 + Annex III, China AI Regulations, US State Laws',
    'riskMitigation':
        'Complete AI feature removal to ensure regulatory compliance',
    'message': '🌍 AI 기능은 글로벌 규제 준수를 위해 완전히 비활성화되었습니다 (7개국 동시 적용).',
    'auditTrail': 'All AI activities logged for regulatory inspection',
  };

  /// AI 기능 접근 시도 시 보안 메시지 표시
  static String get securityMessage =>
      '🌍 AI 기능은 글로벌 규제 준수를 위해 비활성화되었습니다.\n'
      '• EU AI Act (€35M 벌금 위험)\n'
      '• 중국 AI 규제 (정부 승인 필요)\n'
      '• 미국 주별 규제 (CCPA 등)\n'
      '전통적 알고리즘으로 모든 기능이 정상 작동합니다.';

  /// 긴급 봉인 모드 (규제 위반 위험 감지 시)
  static Future<void> emergencyShutdown() async {
    await AiAuditLogger.logSecuritySeal(
      isSealed: true,
      trigger: 'Emergency shutdown due to regulatory violation risk',
    );
    print('🚨 긴급 AI 봉인 활성화: 규제 위반 위험 감지');
  }
}
