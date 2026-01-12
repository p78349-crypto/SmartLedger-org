/// 날씨 기반 물가 예측: 타입/표시명 정의
///
/// 민감도 지수: -1.0(큰 폭 하락) ~ 0.0(영향 없음) ~ +1.0(큰 폭 상승)
library weather_price_sensitivity_models;

/// 날씨 상태 열거형
enum WeatherCondition {
  sunny, // 맑음
  cloudy, // 흐림
  rainy, // 비
  heavyRain, // 폭우/장마
  snowy, // 눈
  typhoon, // 태풍
  coldWave, // 한파 (-10도 이하)
  heatWave, // 폭염 (33도 이상)
}

/// 품목 카테고리
enum PriceCategory {
  vegetable, // 채소류
  fruit, // 과일류
  meat, // 축산물
  seafood, // 수산물
  grain, // 곡물
  dairy, // 유제품
  energy, // 에너지(난방비 등)
}

/// 날씨 민감도 데이터
class WeatherPriceSensitivity {
  final PriceCategory category;
  final String itemName;
  final Map<WeatherCondition, double> sensitivity;
  final String reason; // 한국어 설명

  const WeatherPriceSensitivity({
    required this.category,
    required this.itemName,
    required this.sensitivity,
    required this.reason,
  });
}

/// 날씨 상태의 한국어 이름
const Map<WeatherCondition, String> weatherConditionNames = {
  WeatherCondition.sunny: '맑음',
  WeatherCondition.cloudy: '흐림',
  WeatherCondition.rainy: '비',
  WeatherCondition.heavyRain: '폭우/장마',
  WeatherCondition.snowy: '눈',
  WeatherCondition.typhoon: '태풍',
  WeatherCondition.coldWave: '한파',
  WeatherCondition.heatWave: '폭염',
};

/// 품목 카테고리의 한국어 이름
const Map<PriceCategory, String> priceCategoryNames = {
  PriceCategory.vegetable: '채소류',
  PriceCategory.fruit: '과일류',
  PriceCategory.meat: '축산물',
  PriceCategory.seafood: '수산물',
  PriceCategory.grain: '곡물',
  PriceCategory.dairy: '유제품',
  PriceCategory.energy: '에너지',
};
