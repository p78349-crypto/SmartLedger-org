part of 'evacuation_route_utils.dart';

/// 미국 주요 도시(허리케인) 대피 경로 데이터
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
