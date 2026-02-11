// 안전 이동 경로 유틸리티
//
// 허리케인(태풍), 폭우, 폭설 등 극한 날씨 시나리오에서
// 사용자가 안전한 대피 경로를 빠르게 파악할 수 있도록 돕습니다.

import 'weather_price_sensitivity.dart';
import 'weather_utils.dart';

part 'evacuation_route_utils_regions.dart';
part 'evacuation_route_utils_planner.dart';

/// 환경 유형 (도심/해안/기타)
enum EvacuationEnvironment { urban, coastal, inland, unknown }

/// 대피 권고 수준
enum EvacuationAdviceLevel {
  monitor, // 상황 모니터링
  prepare, // 대비 단계 (짐 꾸리기, 차량 점검)
  evacuate, // 즉시 대피 권고
}

/// 경로 안전 등급
enum EvacuationSafetyLevel {
  primary, // 1순위 안전 경로 (정부 지정)
  alternate, // 우회 경로 (교통 혼잡 시)
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
  final List<String> checkpoints; // 중간 점검 사항
  final List<String> recommendedActions; // 행동 지침
  final String safetyMessage; // 핵심 경보 문구
  final int familySize;
  final DateTime generatedAt;
  final String? environmentAdvisory; // 도심/해안 특화 안내

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
  if (condition == WeatherCondition.typhoon ||
      condition == WeatherCondition.heavyRain) {
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

  if (condition == WeatherCondition.snowy ||
      condition == WeatherCondition.coldWave) {
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
