part of 'evacuation_route_utils.dart';

/// 안전 이동 경로 플래너
class EvacuationRoutePlanner {
  /// 대피 계획 생성 (지역 자동 감지)
  static EvacuationPlan generatePlan({
    required WeatherData weather,
    int familySize = 2,
  }) {
    final condition = weather.effectiveCondition;
    final adviceLevel = _determineAdvice(condition);
    final regionKey = _detectRegionKey(weather.location);
    final regionConfig = _regionConfigs[regionKey];
    final environment = _inferEnvironment(weather.location);

    final routes =
        regionConfig?.routesByCondition[condition] ??
        _customRoutesForEnvironment(condition, environment) ??
        _defaultRoutes(condition);

    final checkpoints = <String>[
      if (regionConfig != null) ...regionConfig.checkpoints,
      ..._genericCheckpoints(condition),
      ..._environmentCheckpoints(condition, environment),
    ];

    final actions = _recommendedActions(condition, familySize, environment);

    final safetyMessage = _buildSafetyMessage(
      condition: condition,
      location: weather.location,
      adviceLevel: adviceLevel,
      regionName: regionConfig?.regionName,
    );

    final environmentAdvisory = _environmentAdvisory(condition, environment);

    return EvacuationPlan(
      condition: condition,
      location: weather.location,
      adviceLevel: adviceLevel,
      routes: routes,
      checkpoints: checkpoints,
      recommendedActions: actions,
      safetyMessage: safetyMessage,
      familySize: familySize,
      generatedAt: DateTime.now(),
      environmentAdvisory: environmentAdvisory,
    );
  }

  /// 위치 문자열로 지역 키 감지
  static String? _detectRegionKey(String? location) {
    if (location == null || location.isEmpty) return null;
    final normalized = location.toLowerCase();

    if (normalized.contains('miami') || normalized.contains('south beach')) {
      return 'miami_fl';
    }
    if (normalized.contains('new orleans') || normalized.contains('nola')) {
      return 'new_orleans_la';
    }
    if (normalized.contains('houston') || normalized.contains('galveston')) {
      return 'houston_tx';
    }

    return null;
  }

  /// 권고 수준 판단
  static EvacuationAdviceLevel _determineAdvice(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.typhoon:
        return EvacuationAdviceLevel.evacuate;
      case WeatherCondition.heavyRain:
      case WeatherCondition.snowy:
        return EvacuationAdviceLevel.prepare;
      case WeatherCondition.coldWave:
      case WeatherCondition.heatWave:
        return EvacuationAdviceLevel.monitor;
      default:
        return EvacuationAdviceLevel.monitor;
    }
  }

  /// 일반 체크포인트
  static List<String> _genericCheckpoints(WeatherCondition condition) {
    switch (condition) {
      case WeatherCondition.typhoon:
        return [
          '허리케인 경보 단계(Watch/Warning) 라디오로 확인',
          '이동 중 교량/해안도로 폐쇄 여부 체크',
          '차량 연료 3/4 이상 유지, 비상 식수 3일분 적재',
        ];
      case WeatherCondition.heavyRain:
        return ['저지대 침수 여부 확인 → 우회 경로 확보', '하천 교량 접근 금지, 통제선 준수'];
      case WeatherCondition.snowy:
        return ['겨울용 타이어 또는 체인 장착 여부 확인', '국도/고속도로 통제 공지 체크'];
      default:
        return ['지역 재난 문자 수신 설정 확인'];
    }
  }

  /// 권장 행동 목록
  static List<String> _recommendedActions(
    WeatherCondition condition,
    int familySize,
    EvacuationEnvironment environment,
  ) {
    final base = <String>['가족 인원 $familySize명 확인, 연락망 공유'];

    switch (condition) {
      case WeatherCondition.typhoon:
        final extra = <String>[
          '모바일 충전기 2개 이상, 현금 \$100 이상 확보',
          '필수 서류(여권, 보험) 방수팩에 보관',
          '허리케인 전용 대피소(Zone 별) 확인',
        ];
        if (environment == EvacuationEnvironment.urban) {
          extra.add('도심: 인근 지하철 역사/지하 대피소 위치 공유, 지상 이동 최소화');
        }
        return [...base, ...extra];
      case WeatherCondition.heavyRain:
        final extra = <String>[
          '침수 예상 지역 지도 저장, 차량 이동 시 높이 30cm 이상 물길 진입 금지',
        ];
        if (environment == EvacuationEnvironment.urban) {
          extra.add('지상 도로 침수 시 건물 옥상/고지대 천공로(스카이워크)로 이동');
        }
        return [...base, ...extra];
      case WeatherCondition.snowy:
        return [...base, '방한 의류와 담요, 핫팩을 이동 가방에 패킹'];
      default:
        return base;
    }
  }

  static List<String> _environmentCheckpoints(
    WeatherCondition condition,
    EvacuationEnvironment environment,
  ) {
    if (environment == EvacuationEnvironment.urban) {
      if (condition == WeatherCondition.typhoon) {
        return [
          '지하철 역사/지하 대피소 전광판으로 공식 안내 확인',
          '지상 광고판, 유리창 인근 대기 금지',
        ];
      }
      if (condition == WeatherCondition.heavyRain) {
        return [
          '지하차도·지하주차장 출입 통제 확인 후 이용 금지',
          '옥상 출입문/비상계단 접근 가능 여부 사전 확인',
        ];
      }
    }

    if (environment == EvacuationEnvironment.coastal &&
        condition == WeatherCondition.heavyRain) {
      return ['해안 제방 붕괴 가능성 → 내륙 방향 고지대 이동'];
    }

    return const [];
  }

  static String? _environmentAdvisory(
    WeatherCondition condition,
    EvacuationEnvironment environment,
  ) {
    if (environment == EvacuationEnvironment.urban) {
      if (condition == WeatherCondition.typhoon) {
        return '도심 지역: 강화유리 파손을 피하고 지하철 역사 시민대피구역으로 이동하세요.';
      }
      if (condition == WeatherCondition.heavyRain) {
        return '도심 홍수: 지하차도·지하주차장을 즉시 벗어나 고지대(옥상/공원)로 이동하세요.';
      }
    }
    if (environment == EvacuationEnvironment.coastal &&
        condition == WeatherCondition.typhoon) {
      return '해안 지역: 방파제/부두 접근 금지, 내륙 방향 대피를 우선하세요.';
    }
    return null;
  }

  static EvacuationEnvironment _inferEnvironment(String location) {
    final normalized = location.toLowerCase();
    const urbanKeywords = [
      'seoul',
      '서울',
      'busan',
      '부산',
      'incheon',
      '인천',
      'daejeon',
      '대전',
      'daegu',
      '대구',
      'new york',
      'los angeles',
      'tokyo',
      'osaka',
      'singapore',
      'hong kong',
      'bangkok',
      'miami',
    ];
    for (final keyword in urbanKeywords) {
      if (normalized.contains(keyword)) {
        return EvacuationEnvironment.urban;
      }
    }

    const coastalKeywords = [
      'beach',
      'bay',
      'island',
      'galveston',
      'jeju',
      '부두',
      '포구',
    ];
    for (final keyword in coastalKeywords) {
      if (normalized.contains(keyword)) {
        return EvacuationEnvironment.coastal;
      }
    }

    if (normalized.isEmpty) return EvacuationEnvironment.unknown;
    return EvacuationEnvironment.inland;
  }

  /// 안전 메시지 생성
  static String _buildSafetyMessage({
    required WeatherCondition condition,
    required String location,
    required EvacuationAdviceLevel adviceLevel,
    String? regionName,
  }) {
    final locationText = regionName ?? location;
    final conditionName = weatherConditionNames[condition] ?? '극한 날씨';

    switch (adviceLevel) {
      case EvacuationAdviceLevel.evacuate:
        return '⚠️ $locationText: $conditionName 대피 권고 발령. 즉시 안전 경로로 이동하세요.';
      case EvacuationAdviceLevel.prepare:
        return '주의: $locationText $conditionName 예보. 오늘 중 대피 경로를 확인하세요.';
      case EvacuationAdviceLevel.monitor:
        return '$locationText $conditionName 예상. 상황을 주시하세요.';
    }
  }
}
