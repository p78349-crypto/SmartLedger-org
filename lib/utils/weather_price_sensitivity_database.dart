import 'weather_price_sensitivity_models.dart';

/// 날씨 민감도 데이터베이스
/// 한국 시장 특성을 반영한 실제 가격 변동 패턴 기반
final List<WeatherPriceSensitivity> weatherPriceSensitivityDatabase = [
  // ========== 채소류 ==========
  const WeatherPriceSensitivity(
    category: PriceCategory.vegetable,
    itemName: '배추',
    sensitivity: {
      WeatherCondition.sunny: 0.0,
      WeatherCondition.rainy: 0.3,
      WeatherCondition.heavyRain: 0.9, // 장마철 큰 폭 상승
      WeatherCondition.typhoon: 1.0, // 태풍으로 공급 차질
      WeatherCondition.coldWave: 0.6, // 한파로 생육 저해
      WeatherCondition.heatWave: 0.4,
    },
    reason: '장마철/태풍: 밭 침수로 공급 감소, 한파: 생육 지연',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.vegetable,
    itemName: '양배추',
    sensitivity: {
      WeatherCondition.sunny: 0.0,
      WeatherCondition.rainy: 0.3,
      WeatherCondition.heavyRain: 0.9,
      WeatherCondition.typhoon: 1.0,
      WeatherCondition.coldWave: 0.5,
      WeatherCondition.heatWave: 0.3,
    },
    reason: '장마철 밭 침수로 수급 불안정',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.vegetable,
    itemName: '상추',
    sensitivity: {
      WeatherCondition.sunny: -0.2, // 햇볕 많으면 생육 좋음
      WeatherCondition.rainy: 0.4,
      WeatherCondition.heavyRain: 0.8,
      WeatherCondition.typhoon: 1.0,
      WeatherCondition.coldWave: 0.7,
      WeatherCondition.heatWave: 0.5,
    },
    reason: '햇볕: 생육 양호, 장마철: 병해충 증가로 수확 감소',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.vegetable,
    itemName: '시금치',
    sensitivity: {
      WeatherCondition.sunny: -0.1,
      WeatherCondition.rainy: 0.3,
      WeatherCondition.heavyRain: 0.8,
      WeatherCondition.typhoon: 0.9,
      WeatherCondition.coldWave: 0.6,
      WeatherCondition.heatWave: 0.4,
    },
    reason: '장마철 병해충, 한파로 생육 저하',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.vegetable,
    itemName: '오이',
    sensitivity: {
      WeatherCondition.sunny: -0.2,
      WeatherCondition.rainy: 0.4,
      WeatherCondition.heavyRain: 0.9,
      WeatherCondition.typhoon: 1.0,
      WeatherCondition.coldWave: 0.7,
      WeatherCondition.heatWave: 0.3,
    },
    reason: '장마철 습해, 한파에 약함',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.vegetable,
    itemName: '토마토',
    sensitivity: {
      WeatherCondition.sunny: -0.3, // 햇볕 필요 작물
      WeatherCondition.rainy: 0.3,
      WeatherCondition.heavyRain: 0.8,
      WeatherCondition.typhoon: 0.9,
      WeatherCondition.coldWave: 0.5,
      WeatherCondition.heatWave: 0.4,
    },
    reason: '햇볕 충분하면 풍작, 장마철 병해 증가',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.vegetable,
    itemName: '무',
    sensitivity: {
      WeatherCondition.sunny: 0.0,
      WeatherCondition.rainy: 0.3,
      WeatherCondition.heavyRain: 0.8,
      WeatherCondition.typhoon: 1.0,
      WeatherCondition.coldWave: 0.6,
      WeatherCondition.heatWave: 0.3,
    },
    reason: '장마철 밭 침수, 태풍 피해',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.vegetable,
    itemName: '당근',
    sensitivity: {
      WeatherCondition.sunny: -0.1,
      WeatherCondition.rainy: 0.3,
      WeatherCondition.heavyRain: 0.7,
      WeatherCondition.typhoon: 0.9,
      WeatherCondition.coldWave: 0.4,
      WeatherCondition.heatWave: 0.3,
    },
    reason: '장마철 토양 과습으로 생육 불량',
  ),
  // ========== 과일류 ==========
  const WeatherPriceSensitivity(
    category: PriceCategory.fruit,
    itemName: '사과',
    sensitivity: {
      WeatherCondition.sunny: -0.3, // 햇볕 많으면 당도 증가
      WeatherCondition.rainy: 0.2,
      WeatherCondition.heavyRain: 0.6,
      WeatherCondition.typhoon: 1.0, // 낙과로 큰 피해
      WeatherCondition.coldWave: 0.4,
      WeatherCondition.heatWave: 0.5,
    },
    reason: '햇볕: 당도 상승, 태풍: 낙과로 수확량 감소',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.fruit,
    itemName: '배',
    sensitivity: {
      WeatherCondition.sunny: -0.3,
      WeatherCondition.rainy: 0.2,
      WeatherCondition.heavyRain: 0.6,
      WeatherCondition.typhoon: 1.0,
      WeatherCondition.coldWave: 0.5,
      WeatherCondition.heatWave: 0.4,
    },
    reason: '태풍 낙과, 폭염으로 생리장해',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.fruit,
    itemName: '포도',
    sensitivity: {
      WeatherCondition.sunny: -0.4, // 햇볕 매우 중요
      WeatherCondition.rainy: 0.4,
      WeatherCondition.heavyRain: 0.7,
      WeatherCondition.typhoon: 0.9,
      WeatherCondition.heatWave: 0.3,
    },
    reason: '햇볕: 당도 증가, 장마철: 병해 증가',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.fruit,
    itemName: '딸기',
    sensitivity: {
      WeatherCondition.sunny: -0.2,
      WeatherCondition.rainy: 0.3,
      WeatherCondition.heavyRain: 0.6,
      WeatherCondition.coldWave: 0.7, // 한파에 약함
      WeatherCondition.heatWave: 0.5,
    },
    reason: '한파: 생육 정지, 폭염: 수확량 감소',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.fruit,
    itemName: '수박',
    sensitivity: {
      WeatherCondition.sunny: -0.3,
      WeatherCondition.rainy: 0.4,
      WeatherCondition.heavyRain: 0.7,
      WeatherCondition.typhoon: 0.8,
      WeatherCondition.heatWave: -0.1, // 폭염에는 오히려 재배 적합
    },
    reason: '햇볕/폭염: 당도 증가, 장마철: 병해',
  ),

  // ========== 축산물 ==========
  const WeatherPriceSensitivity(
    category: PriceCategory.meat,
    itemName: '돼지고기',
    sensitivity: {
      WeatherCondition.sunny: 0.0,
      WeatherCondition.rainy: 0.1,
      WeatherCondition.heavyRain: 0.3,
      WeatherCondition.coldWave: 0.5, // 난방비 증가
      WeatherCondition.heatWave: 0.6, // 폭염 스트레스
    },
    reason: '폭염: 가축 스트레스로 사육비 증가, 한파: 난방비',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.meat,
    itemName: '소고기',
    sensitivity: {
      WeatherCondition.sunny: 0.0,
      WeatherCondition.rainy: 0.1,
      WeatherCondition.heavyRain: 0.2,
      WeatherCondition.coldWave: 0.4,
      WeatherCondition.heatWave: 0.5,
    },
    reason: '폭염/한파: 사육 환경 악화로 생산 비용 증가',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.meat,
    itemName: '닭고기',
    sensitivity: {
      WeatherCondition.sunny: 0.0,
      WeatherCondition.rainy: 0.1,
      WeatherCondition.heavyRain: 0.3,
      WeatherCondition.coldWave: 0.6, // 난방비, 조류독감 위험
      WeatherCondition.heatWave: 0.7, // 폭염 폐사 위험
    },
    reason: '폭염: 폐사율 증가, 한파: 조류독감 발생 가능성',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.meat,
    itemName: '계란',
    sensitivity: {
      WeatherCondition.sunny: 0.0,
      WeatherCondition.rainy: 0.1,
      WeatherCondition.heavyRain: 0.2,
      WeatherCondition.coldWave: 0.6, // 조류독감 위험
      WeatherCondition.heatWave: 0.5, // 산란율 저하
    },
    reason: '한파: 조류독감, 폭염: 산란율 저하',
  ),

  // ========== 수산물 ==========
  const WeatherPriceSensitivity(
    category: PriceCategory.seafood,
    itemName: '고등어',
    sensitivity: {
      WeatherCondition.sunny: -0.2, // 출항 가능
      WeatherCondition.rainy: 0.3,
      WeatherCondition.heavyRain: 0.7, // 출항 불가
      WeatherCondition.typhoon: 1.0, // 조업 중단
      WeatherCondition.coldWave: 0.4,
    },
    reason: '태풍/폭우: 조업 중단으로 공급 감소',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.seafood,
    itemName: '오징어',
    sensitivity: {
      WeatherCondition.sunny: -0.2,
      WeatherCondition.rainy: 0.3,
      WeatherCondition.heavyRain: 0.8,
      WeatherCondition.typhoon: 1.0,
      WeatherCondition.coldWave: 0.5,
    },
    reason: '태풍/폭우: 출항 불가로 수급 차질',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.seafood,
    itemName: '명태',
    sensitivity: {
      WeatherCondition.sunny: 0.0,
      WeatherCondition.rainy: 0.3,
      WeatherCondition.heavyRain: 0.7,
      WeatherCondition.typhoon: 0.9,
      WeatherCondition.coldWave: -0.3, // 한류성 어종, 한파 시 어획 증가
    },
    reason: '한파: 한류성 어종으로 어획량 증가, 태풍: 조업 중단',
  ),

  // ========== 곡물 ==========
  const WeatherPriceSensitivity(
    category: PriceCategory.grain,
    itemName: '쌀',
    sensitivity: {
      WeatherCondition.sunny: -0.2, // 수확기 맑으면 좋음
      WeatherCondition.rainy: 0.2,
      WeatherCondition.heavyRain: 0.6, // 수확기 장마
      WeatherCondition.typhoon: 0.9, // 도복 피해
      WeatherCondition.coldWave: 0.4,
      WeatherCondition.heatWave: 0.3,
    },
    reason: '수확기 장마: 수확 지연, 태풍: 도복 피해',
  ),

  // ========== 에너지 ==========
  const WeatherPriceSensitivity(
    category: PriceCategory.energy,
    itemName: '난방비',
    sensitivity: {
      WeatherCondition.sunny: -0.2,
      WeatherCondition.rainy: 0.1,
      WeatherCondition.coldWave: 1.0, // 한파로 난방비 급증
      WeatherCondition.snowy: 0.6,
    },
    reason: '한파: 난방 수요 급증으로 비용 상승',
  ),
  const WeatherPriceSensitivity(
    category: PriceCategory.energy,
    itemName: '전기요금',
    sensitivity: {
      WeatherCondition.sunny: 0.0,
      WeatherCondition.coldWave: 0.7, // 전기 난방
      WeatherCondition.heatWave: 0.8, // 에어컨 사용 증가
    },
    reason: '한파/폭염: 냉난방 수요 증가',
  ),
];
