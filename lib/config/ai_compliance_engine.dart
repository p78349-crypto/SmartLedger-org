/// 글로벌 AI 규제 컴플라이언스 엔진 (2026)
/// 전세계 18개국 AI 규제 동시 대응 시스템
class AiComplianceEngine {
  static const String _complianceVersion = '2026.02.21-GLOBAL18';
  static const Map<String, AiRegulation> _globalRegulations = {
    // 유럽연합 및 주요 유럽국가 (6개국)
    'EU': AiRegulation.euAiAct,
    'DE': AiRegulation.germanyStrict,
    'FR': AiRegulation.franceAi,
    'IT': AiRegulation.italyAi,
    'ES': AiRegulation.spainAi,
    'NL': AiRegulation.netherlandsAi,
    
    // 아시아-태평양 (6개국)
    'CN': AiRegulation.chinaStrict,
    'JP': AiRegulation.japanTrust,
    'KR': AiRegulation.koreaPrivacy,
    'SG': AiRegulation.singaporeAi,
    'AU': AiRegulation.australiaPrivacy,
    'IN': AiRegulation.indiaDigital,
    
    // 북미 (4개국/지역)
    'US_CA': AiRegulation.californiaStrict,
    'US_NY': AiRegulation.newYorkFinancial,
    'CA': AiRegulation.canadaAiDataAct,
    'MX': AiRegulation.mexicoData,
    
    // 기타 (2개국)
    'GB': AiRegulation.ukAiFramework,
    'CH': AiRegulation.switzerlandPrivacy,
  };

  /// 현재 지역의 AI 규제 요구사항 확인
  static AiRegulation getCurrentRegulation(String countryCode) {
    return _globalRegulations[countryCode] ?? AiRegulation.safestDefault;
  }

  /// AI 기능 위험도 평가 (EU AI Act 기준)
  static AiRiskLevel assessRiskLevel({
    required String domain,
    required String functionality,
  }) {
    // 금융 도메인은 EU AI Act 고위험 분류
    if (domain == 'financial' || domain == 'investment') {
      return AiRiskLevel.high;
    }
    
    // 개인정보 처리 관련
    if (functionality.contains('personal_data')) {
      return AiRiskLevel.high;
    }
    
    return AiRiskLevel.minimal;
  }

  /// 규제 준수 여부 실시간 검증
  static ComplianceResult validateCompliance({
    required String region,
    required AiFeatureType featureType,
    required bool userConsent,
  }) {
    final regulation = getCurrentRegulation(region);
    
    if (regulation.requiresGovernmentApproval && !_hasGovernmentApproval()) {
      return ComplianceResult.violation('Government approval required');
    }
    
    if (regulation.requiresExplicitConsent && !userConsent) {
      return ComplianceResult.violation('User consent required');
    }
    
    return ComplianceResult.compliant();
  }

  /// 정부 승인 여부 (중국 등)
  static bool _hasGovernmentApproval() => false; // SmartLedger: 승인 없음

  /// EU AI Act 투명성 요구사항 체크
  static bool requiresTransparency(AiRiskLevel riskLevel) {
    return riskLevel == AiRiskLevel.high;
  }
}

/// AI 규제 정보 모델
class AiRegulation {
  const AiRegulation({
    required this.name,
    required this.maxFine,
    required this.requiresGovernmentApproval,
    required this.requiresExplicitConsent,
    required this.requiresTransparency,
  });

  final String name;
  final String maxFine;
  final bool requiresGovernmentApproval;
  final bool requiresExplicitConsent;
  final bool requiresTransparency;

  static const euAiAct = AiRegulation(
    name: 'EU AI Act',
    maxFine: '€35M or 7% global revenue',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const chinaStrict = AiRegulation(
    name: 'China AI Regulation',
    maxFine: 'Service suspension',
    requiresGovernmentApproval: true,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const californiaStrict = AiRegulation(
    name: 'California CCPA + AI',
    maxFine: '$7,500 per violation',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  // 추가된 11개국 AI 규제 (18개국 완성)
  static const germanyStrict = AiRegulation(
    name: 'Germany AI Strategy + GDPR',
    maxFine: '€20M or 4% revenue',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const franceAi = AiRegulation(
    name: 'France AI Ethics + GDPR',
    maxFine: '€20M or 4% revenue',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const italyAi = AiRegulation(
    name: 'Italy AI Guidelines + GDPR',
    maxFine: '€20M or 4% revenue',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const spainAi = AiRegulation(
    name: 'Spain AI Strategy + GDPR',
    maxFine: '€20M or 4% revenue',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const netherlandsAi = AiRegulation(
    name: 'Netherlands AI Framework',
    maxFine: '€20M or 4% revenue',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const singaporeAi = AiRegulation(
    name: 'Singapore Model AI Governance',
    maxFine: 'S$1M + business suspension',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const australiaPrivacy = AiRegulation(
    name: 'Australia Privacy Act + AI',
    maxFine: 'AU$50M or 30% revenue',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const indiaDigital = AiRegulation(
    name: 'India Digital Personal Data Protection',
    maxFine: '₹500 crore + operations ban',
    requiresGovernmentApproval: true,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const newYorkFinancial = AiRegulation(
    name: 'New York Financial AI Regulations',
    maxFine: '$10M + license revocation',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const canadaAiDataAct = AiRegulation(
    name: 'Canada AI and Data Act',
    maxFine: 'C$25M or 5% revenue',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const mexicoData = AiRegulation(
    name: 'Mexico Data Protection + AI',
    maxFine: '$320K USD + operations halt',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const ukAiFramework = AiRegulation(
    name: 'UK AI White Paper Framework',
    maxFine: '£17.5M or 4% revenue',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const switzerlandPrivacy = AiRegulation(
    name: 'Switzerland Data Protection Act',
    maxFine: 'CHF 250K + civil liability',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const japanTrust = AiRegulation(
    name: 'Japan AI Governance Guidelines',
    maxFine: '¥100M + business suspension',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const koreaPrivacy = AiRegulation(
    name: 'Korea Personal Information Protection Act',
    maxFine: '₩3B + 2 years imprisonment',
    requiresGovernmentApproval: false,
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );

  static const safestDefault = AiRegulation(
    name: 'Safest Global Standard (18-Country Compliant)',
    maxFine: 'Maximum penalty of all 18 countries',
    requiresGovernmentApproval: true, // 가장 엄격한 기준 적용
    requiresExplicitConsent: true,
    requiresTransparency: true,
  );
}

enum AiRiskLevel { minimal, limited, high, unacceptable }
enum AiFeatureType { prediction, analysis, recommendation, automation }

class ComplianceResult {
  const ComplianceResult._(this.isCompliant, this.reason);
  
  factory ComplianceResult.compliant() => const ComplianceResult._(true, null);
  factory ComplianceResult.violation(String reason) => 
      ComplianceResult._(false, reason);
  
  final bool isCompliant;
  final String? reason;
}