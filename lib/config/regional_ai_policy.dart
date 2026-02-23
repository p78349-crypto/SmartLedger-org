import 'ai_compliance_engine.dart';
import 'ai_security_seal.dart';

/// 지역별 AI 정책 자동 적용 시스템 (18개국 대응)
/// 사용자 위치에 따라 해당 지역 규제를 자동으로 적용
class RegionalAiPolicy {
  static const String _policyVersion = '2026.02.21-GLOBAL-18COUNTRIES';
  static const bool _globalSafeMode = true; // 전역 안전 모드 활성화

  /// 현재 지역의 AI 사용 가능 여부 확인 (18개국 동시 검증)
  static bool isAiAllowedInRegion(String countryCode) {
    // 🔒 글로벌 안전 모드: 모든 18개국에서 AI 비활성화
    if (_globalSafeMode) return false;
    
    // 18개국 개별 정책 확인
    if (_strictRegulationCountries.contains(countryCode)) {
      return _checkStrictCompliance(countryCode);
    }
    
    return false; // 기본값: 안전을 위해 비허용
  }

  /// 18개국 엄격한 규제 준수 여부 확인
  static bool _checkStrictCompliance(String countryCode) {
    // 모든 18개국에서 금융 AI는 고위험으로 분류
    final riskLevel = AiComplianceEngine.assessRiskLevel(
      domain: 'financial',
      functionality: 'investment_advice',
    );
    
    // 개별 국가별 특수 요구사항
    switch (countryCode) {
      case 'CN': // 중국: 정부 승인 필수
        return false; // 정부 승인 없음
      case 'IN': // 인도: 정부 승인 필요
        return false; // 정부 승인 없음
      case 'AU': // 호주: 매우 높은 벌금 위험
        return false; // AU$50M 벌금 위험 회피
      default:
        // EU 및 기타 모든 국가: 고위험 AI 제한
        if (riskLevel == AiRiskLevel.high) {
          return false; // 고위험 AI 완전 차단
        }
        return false; // 안전 우선
    }
  }

  /// 현재 적용 중인 정책 정보
  static Map<String, dynamic> getCurrentPolicy(String countryCode) {
    return {
      'version': _policyVersion,
      'country': countryCode,
      'aiAllowed': isAiAllowedInRegion(countryCode),
      'regulation': AiComplianceEngine.getCurrentRegulation(countryCode),
      'safeMode': _globalSafeMode,
      'reason': _getPolicyReason(countryCode),
      'lastUpdated': '2026-02-21T12:50:00Z',
    };
  }

  /// 정책 적용 이유 (18개국 대응)
  static String _getPolicyReason(String countryCode) {
    if (_globalSafeMode) {
      return 'Global AI safety mode: 18-country regulatory compliance';
    }
    
    // 18개국 개별 정책 이유
    final Map<String, String> policyReasons = {
      // 유럽 (6개국)
      'EU': 'EU AI Act €35M fine risk - High-risk financial AI restricted',
      'DE': 'Germany AI Strategy + GDPR €20M penalty risk',
      'FR': 'France AI Ethics Framework + GDPR compliance required',
      'IT': 'Italy AI Guidelines + GDPR €20M fine risk',
      'ES': 'Spain National AI Strategy compliance mandatory',
      'NL': 'Netherlands AI Framework transparency requirements',
      
      // 아시아-태평양 (6개국)
      'CN': 'China government approval required - Service suspension risk',
      'JP': 'Japan AI Governance Guidelines - ¥100M penalty risk',
      'KR': 'Korea PIPA - ₩3B fine + 2 years imprisonment risk',
      'SG': 'Singapore Model AI Governance - S$1M + suspension risk',
      'AU': 'Australia Privacy Act - AU$50M or 30% revenue penalty',
      'IN': 'India DPDP - ₹500 crore fine + government approval needed',
      
      // 북미 (4개 지역)
      'US_CA': 'California CCPA + AI regulations - $7,500 per violation',
      'US_NY': 'New York Financial AI - $10M + license revocation risk',
      'CA': 'Canada AI and Data Act - C$25M or 5% revenue penalty',
      'MX': 'Mexico Data Protection - $320K USD + operations halt',
      
      // 기타 (2개국)
      'GB': 'UK AI White Paper - £17.5M or 4% revenue penalty',
      'CH': 'Switzerland Data Protection - CHF 250K + civil liability',
    };
    
    return policyReasons[countryCode] ?? 
           'Precautionary AI restriction for regulatory safety';
  }

  /// SmartLedger 대응 18개국 목록
  static const List<String> _strictRegulationCountries = [
    // 유럽연합 및 주요 유럽국가 (6개국)
    'EU', 'DE', 'FR', 'IT', 'ES', 'NL',
    
    // 아시아-태평양 (6개국)  
    'CN', 'JP', 'KR', 'SG', 'AU', 'IN',
    
    // 북미 (4개 지역)
    'US_CA', 'US_NY', 'CA', 'MX',
    
    // 기타 (2개국)
    'GB', 'CH',
  ];

  /// 긴급 모드 활성화 (모든 AI 기능 즉시 정지)
  static void enableEmergencyMode(String reason) {
    AiSecuritySeal.emergencyShutdown();
    print('🚨 긴급 모드 활성화: $reason');
  }
}