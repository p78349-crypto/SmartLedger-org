// 안전 이동 경로 유틸리티
//
// 허리케인(태풍), 폭우, 폭설 등 극한 날씨 시나리오에서
// 사용자가 안전한 대피 경로를 빠르게 파악할 수 있도록 돕습니다.

import 'weather_price_sensitivity.dart';
import 'weather_utils.dart';

/// 환경 유형 (도심/해안/기타)
enum EvacuationEnvironment {
  urban,
  coastal,
  inland,
  unknown,
}

/// 대피 권고 수준
enum EvacuationAdviceLevel {
  monitor,   // 상황 모니터링
  prepare,   // 대비 단계 (짐 꾸리기, 차량 점검)
  evacuate,  // 즉시 대피 권고
}

/// 경로 안전 등급
enum EvacuationSafetyLevel {
  primary,    // 1순위 안전 경로 (정부 지정)
  alternate,  // 우회 경로 (교통 혼잡 시)
  lastResort, // 최후 수단 (위험 허용)
}

/// 단일 대피 경로 정보
class EvacuationRoute {
  final String name;
  final double distanceKm;
  final int estimatedMinutes;
  final EvacuationSafetyLevel safetyLevel;
  final List<String> steps; // 이동 단계
  final String shelterName;
  final String shelterAddress;
  final List<String> amenities; // 비상 식량, 발전기 등
  final String routeType; // 도보/차량/대중교통 등
  final double shelterLat;
  final double shelterLon;

  const EvacuationRoute({
    required this.name,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.safetyLevel,
    required this.steps,
    required this.shelterName,
    required this.shelterAddress,
    required this.amenities,
    required this.routeType,
    required this.shelterLat,
    required this.shelterLon,
  });
}

/// 대피 계획 결과
class EvacuationPlan {
  final WeatherCondition condition;
  final String location;
  final EvacuationAdviceLevel adviceLevel;
  final List<EvacuationRoute> routes;
  final List<String> checkpoints;          // 중간 점검 사항
  final List<String> recommendedActions;   // 행동 지침
  final String safetyMessage;              // 핵심 경보 문구
  final int familySize;
  final DateTime generatedAt;
  final String? environmentAdvisory;       // 도심/해안 특화 안내

  const EvacuationPlan({
    required this.condition,
    required this.location,
    required this.adviceLevel,
    required this.routes,
    required this.checkpoints,
    required this.recommendedActions,
    required this.safetyMessage,
    required this.familySize,
    required this.generatedAt,
    this.environmentAdvisory,
  });
}

/// 지역별 경로 데이터 구성
class _RegionEvacuationConfig {
  final String regionName;
  final Map<WeatherCondition, List<EvacuationRoute>> routesByCondition;
  final List<String> checkpoints;

  const _RegionEvacuationConfig({
    required this.regionName,
    required this.routesByCondition,
    required this.checkpoints,
  });
}

/// 기본 경로(전 지역 공통)
List<EvacuationRoute> _defaultRoutes(WeatherCondition condition) {
  if (condition == WeatherCondition.typhoon || condition == WeatherCondition.heavyRain) {
    return const [
      EvacuationRoute(
        name: '주요 도로 → 고지대 시민센터',
        distanceKm: 6.2,
        estimatedMinutes: 18,
        safetyLevel: EvacuationSafetyLevel.primary,
        steps: [
          '1) 메인대로로 진입해 남쪽 방면으로 2km 이동',
          '2) 교차로에서 국도 47호선으로 우회전',
          '3) 고지대 시민센터(대피소) 표지판을 따라 진입',
        ],
        shelterName: '고지대 시민센터',
        shelterAddress: '서울시 중랑구 안전로 12',
        amenities: ['비상 발전기', '온수 샤워', '모바일 급속 충전'],
        routeType: '차량',
        shelterLat: 37.6059,
        shelterLon: 127.0986,
      ),
      EvacuationRoute(
        name: '지하철 7호선 → 체육관 대피소',
        distanceKm: 4.5,
        estimatedMinutes: 25,
        safetyLevel: EvacuationSafetyLevel.alternate,
        steps: [
          '1) 인근 지하철역(7호선) 탑승',
          '2) 체육관역에서 하차 후 300m 도보 이동',
          '3) 시립 체육관 서문으로 입장',
        ],
        shelterName: '시립 체육관 대피소',
        shelterAddress: '서울시 성동구 체육관로 55',
        amenities: ['대형 발전기', '의료 지원', '유아 공간'],
        routeType: '대중교통',
        shelterLat: 37.547,
        shelterLon: 127.0403,
      ),
    ];
  }

  if (condition == WeatherCondition.snowy || condition == WeatherCondition.coldWave) {
    return const [
      EvacuationRoute(
        name: '내부순환로 → 강남 안전센터',
        distanceKm: 8.0,
        estimatedMinutes: 30,
        safetyLevel: EvacuationSafetyLevel.primary,
        steps: [
          '1) 내부순환로 진입 전 체인 장착 여부 확인',
          '2) 강남 IC까지 서행 (시속 40km 이하)',
          '3) 탄천로 따라 안전센터 북문 진입',
        ],
        shelterName: '강남 구민안전센터',
        shelterAddress: '서울시 강남구 봉은사로 420',
        amenities: ['온열 시스템', '의약품 비축', '담요'],
        routeType: '차량',
        shelterLat: 37.5147,
        shelterLon: 127.0605,
      ),
    ];
  }

  return const [
    EvacuationRoute(
      name: '도보 → 동네 주민센터 임시 대피소',
      distanceKm: 1.5,
      estimatedMinutes: 20,
      safetyLevel: EvacuationSafetyLevel.primary,
      steps: [
        '1) 횡단보도 이용하며 메인도로 회피',
        '2) 골목길 따라 주민센터 방향으로 직진',
        '3) 안내 요원 지시에 따라 입장',
      ],
      shelterName: '동네 주민센터',
      shelterAddress: '가까운 행정복지센터',
      amenities: ['담요', '간편식', '휴대전화 충전'],
      routeType: '도보',
      shelterLat: 37.5665,
      shelterLon: 126.978,
    ),
  ];
}

List<EvacuationRoute> _urbanTyphoonRoutes() {
  return const [
    EvacuationRoute(
      name: '인근 지하철역 시민대피구역',
      distanceKm: 0.8,
      estimatedMinutes: 15,
      safetyLevel: EvacuationSafetyLevel.primary,
      steps: [
        '1) 가장 가까운 지하철역 지상 출입구로 이동',
        '2) 역사 내 시민대피구역·안전지대 안내 표지판을 따른다',
        '3) 스크린도어 안쪽 비상 구역에 대기하며 공지 청취',
      ],
      shelterName: '지하철 역사 시민대피소',
      shelterAddress: '도심 지하철역 지하 2층',
      amenities: ['비상 발전기', '무선 통신', '구급 키트'],
      routeType: '대중교통/지하',
      shelterLat: 37.5610,
      shelterLon: 126.9860,
    ),
    EvacuationRoute(
      name: '지하 연결통로 → 지하주차장 안전구역',
      distanceKm: 0.4,
      estimatedMinutes: 10,
      safetyLevel: EvacuationSafetyLevel.alternate,
      steps: [
        '1) 건물 지하 연결통로로 이동 (유리 파편 위험 회피)',
        '2) 지하 3층 안전구역 표시 구간에 대기',
        '3) 비상 라디오로 태풍 통과 상황 확인',
      ],
      shelterName: '지하 공용 대피구역',
      shelterAddress: '도심 복합건물 지하 3층',
      amenities: ['물/간편식', '무선 충전', '공조 시스템'],
      routeType: '도보',
      shelterLat: 37.565,
      shelterLon: 126.978,
    ),
  ];
}

List<EvacuationRoute> _urbanFloodHighGroundRoutes() {
  return const [
    EvacuationRoute(
      name: '옥상 헬리포트/고지대 공원',
      distanceKm: 1.2,
      estimatedMinutes: 18,
      safetyLevel: EvacuationSafetyLevel.primary,
      steps: [
        '1) 침수 구역을 피하며 스카이워크/보행데크 이용',
        '2) 고지대 공원 또는 옥상 헬리포트 지점으로 이동',
        '3) 구조 헬기/구조선 도착 시까지 대기',
      ],
      shelterName: '고지대 공원 대피소',
      shelterAddress: '도심 고지대 공원 (예: 남산공원)',
      amenities: ['빗물 배수 시스템', '응급의료 키트', '비상 조명'],
      routeType: '도보',
      shelterLat: 37.5512,
      shelterLon: 126.9882,
    ),
    EvacuationRoute(
      name: '공중보행교 → 시청 옥상 피난구',
      distanceKm: 0.9,
      estimatedMinutes: 16,
      safetyLevel: EvacuationSafetyLevel.alternate,
      steps: [
        '1) 지상 도로 대신 공중보행교 이용',
        '2) 시청 또는 구청 옥상 피난구로 안내에 따라 이동',
        '3) 고지대 집결지에서 구호 물자 지급',
      ],
      shelterName: '시청 옥상 피난 플랫폼',
      shelterAddress: '도심 시청사 옥상',
      amenities: ['위성 통신', '비상 발전기', '물/식량'],
      routeType: '도보',
      shelterLat: 37.5663,
      shelterLon: 126.9779,
    ),
  ];
}

/// 미국 주요 도시(허리케인) 데이터
const Map<String, _RegionEvacuationConfig> _regionConfigs = {
  'miami_fl': _RegionEvacuationConfig(
    regionName: 'Miami, FL',
    routesByCondition: {
      WeatherCondition.typhoon: [
        EvacuationRoute(
          name: 'Miami Beach → Marlins Park Shelter',
          distanceKm: 11.4,
          estimatedMinutes: 35,
          safetyLevel: EvacuationSafetyLevel.primary,
          steps: [
            '1) Julia Tuttle Cswy(195E) 서행, 속도 40mph 이하',
            '2) I-95 South로 합류해 Downtown 출구로 진입',
            '3) NW 7th St 따라 Marlins Park 북문 도착',
          ],
          shelterName: 'Marlins Park Hurricane Shelter',
          shelterAddress: '501 Marlins Way, Miami, FL',
          amenities: ['FEMA 의료팀', '디젤 발전기', 'Wi-Fi', '애완동물 구역'],
          routeType: '차량',
          shelterLat: 25.7781,
          shelterLon: -80.2197,
        ),
        EvacuationRoute(
          name: 'Miami Beach → North Miami High School',
          distanceKm: 18.2,
          estimatedMinutes: 42,
          safetyLevel: EvacuationSafetyLevel.alternate,
          steps: [
            '1) Collins Ave 북쪽으로 5km 이동',
            '2) NE 123rd St(브로드 코즈웨이) 이용',
            '3) Biscayne Blvd에서 좌회전 후 121st St 진입',
          ],
          shelterName: 'North Miami High School Shelter',
          shelterAddress: '13110 NE 8th Ave, North Miami, FL',
          amenities: ['급속 충전', '영아 돌봄', '이동 통신 중계차'],
          routeType: '차량',
          shelterLat: 25.9026,
          shelterLon: -80.1851,
        ),
      ],
    },
    checkpoints: [
      '연방재난관리청(FEMA) 허리케인 Zone C → 의무 대피',
      '연료 70% 이상 확보, 현금 \$200 이상 준비',
      'Interstate 진입 전 교량 폐쇄 여부 확인',
    ],
  ),
  'new_orleans_la': _RegionEvacuationConfig(
    regionName: 'New Orleans, LA',
    routesByCondition: {
      WeatherCondition.typhoon: [
        EvacuationRoute(
          name: 'French Quarter → Smoothie King Center',
          distanceKm: 2.8,
          estimatedMinutes: 12,
          safetyLevel: EvacuationSafetyLevel.primary,
          steps: [
            '1) Canal St를 따라 서쪽으로 직진',
            '2) Loyola Ave 진입 후 0.5km 이동',
            '3) Poydras St에서 Smoothie King Center 남문 진입',
          ],
          shelterName: 'Smoothie King Center Mega Shelter',
          shelterAddress: '1501 Dave Dixon Dr, New Orleans, LA',
          amenities: ['의료팀', '위성 통신', '유아 공간'],
          routeType: '차량/도보',
          shelterLat: 29.9489,
          shelterLon: -90.0814,
        ),
        EvacuationRoute(
          name: 'Lakeview → Baton Rouge State Shelter',
          distanceKm: 130.0,
          estimatedMinutes: 110,
          safetyLevel: EvacuationSafetyLevel.alternate,
          steps: [
            '1) I-10 West 진입 전 Pontchartrain Causeway 통제 여부 확인',
            '2) I-12 West로 우회해 Baton Rouge 방향 이동',
            '3) Exit 1A에서 Government St로 진입',
          ],
          shelterName: 'River Center Shelter (Baton Rouge)',
          shelterAddress: '275 S River Rd, Baton Rouge, LA',
          amenities: ['장기 수용', '디젤 발전기', '전기차 충전'],
          routeType: '차량',
          shelterLat: 30.4465,
          shelterLon: -91.1871,
        ),
      ],
    },
    checkpoints: [
      'Category 3 이상 허리케인은 미시시피 강 범람 위험 → 고지대로 이동',
      'Levee(제방) 인근 도로 폐쇄 여부 라디오 수신',
      'US-90선 우회 계획 준비',
    ],
  ),
  'houston_tx': _RegionEvacuationConfig(
    regionName: 'Houston / Galveston, TX',
    routesByCondition: {
      WeatherCondition.typhoon: [
        EvacuationRoute(
          name: 'Galveston Island → NRG Center',
          distanceKm: 83.0,
          estimatedMinutes: 75,
          safetyLevel: EvacuationSafetyLevel.primary,
          steps: [
            '1) I-45 North 진입 전 Contraflow(일방통행) 스케줄 확인',
            '2) League City 구간에서 속도 45mph 유지',
            '3) 610 Loop West 진입 후 Kirby Dr 출구 이용',
          ],
          shelterName: 'NRG Center Shelter',
          shelterAddress: '1 NRG Pkwy, Houston, TX',
          amenities: ['2500병상 의료시설', '모바일 통신 기지국', 'EV 충전'],
          routeType: '차량',
          shelterLat: 29.6847,
          shelterLon: -95.4107,
        ),
        EvacuationRoute(
          name: 'Clear Lake → Austin Shelter Hub',
          distanceKm: 265.0,
          estimatedMinutes: 180,
          safetyLevel: EvacuationSafetyLevel.lastResort,
          steps: [
            '1) I-45 North → TX-71 W 연결',
            '2) Columbus, TX에서 연료 보충 (마지막 대형 주유소)',
            '3) Austin Convention Center 북문 진입',
          ],
          shelterName: 'Austin Convention Center Shelter',
          shelterAddress: '500 E Cesar Chavez St, Austin, TX',
          amenities: ['장기 체류 존', '원격 의료', '무료 와이파이'],
          routeType: '차량',
          shelterLat: 30.2638,
          shelterLon: -97.7392,
        ),
      ],
    },
    checkpoints: [
      'Houston Evacuation Zone A/B 주민 → 36시간 전 출발 권장',
      'I-45 Contraflow 적용 시 역주행 차선 사용',
      'Pet-friendly Shelter 여부 확인',
    ],
  ),
};

List<EvacuationRoute>? _customRoutesForEnvironment(
  WeatherCondition condition,
  EvacuationEnvironment environment,
) {
  if (environment == EvacuationEnvironment.urban) {
    if (condition == WeatherCondition.typhoon) {
      return _urbanTyphoonRoutes();
    }
    if (condition == WeatherCondition.heavyRain) {
      return _urbanFloodHighGroundRoutes();
    }
  }
  return null;
}

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

    final routes = regionConfig?.routesByCondition[condition] ??
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
        return EvacuationAdviceLevel.evacuate; // 허리케인/태풍 → 즉시 대피
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
        return [
          '저지대 침수 여부 확인 → 우회 경로 확보',
          '하천 교량 접근 금지, 통제선 준수',
        ];
      case WeatherCondition.snowy:
        return [
          '겨울용 타이어 또는 체인 장착 여부 확인',
          '국도/고속도로 통제 공지 체크',
        ];
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
        return [
          ...base,
          '방한 의류와 담요, 핫팩을 이동 가방에 패킹',
        ];
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
      'seoul', '서울', 'busan', '부산', 'incheon', '인천', 'daejeon', '대전', 'daegu', '대구',
      'new york', 'los angeles', 'tokyo', 'osaka', 'singapore', 'hong kong', 'bangkok', 'miami',
    ];
    for (final keyword in urbanKeywords) {
      if (normalized.contains(keyword)) {
        return EvacuationEnvironment.urban;
      }
    }

    const coastalKeywords = ['beach', 'bay', 'island', 'galveston', 'jeju', '부두', '포구'];
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
