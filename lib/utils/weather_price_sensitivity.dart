/// 날씨 기반 물가 예측: 품목별 날씨 민감도 데이터베이스
///
/// 민감도 지수: -1.0(큰 폭 하락) ~ 0.0(영향 없음) ~ +1.0(큰 폭 상승)
///
/// 한국의 계절적 특수성 반영:
/// - 장마철(6~7월): 채소류 가격 폭등
/// - 태풍(8~9월): 과일/채소 공급 차질
/// - 한파(12~2월): 난방비, 채소 가격 상승
/// - 폭염(7~8월): 축산물, 채소 가격 변동
library weather_price_sensitivity;

export 'weather_price_sensitivity_models.dart';
export 'weather_price_sensitivity_database.dart';
export 'weather_price_sensitivity_impl.dart';
