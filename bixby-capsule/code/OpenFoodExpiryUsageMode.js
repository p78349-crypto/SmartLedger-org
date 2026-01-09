// OpenFoodExpiryUsageMode Action Handler
// "유통기한 사용 모드 열어" 같은 발화로
// 유통기한 화면을 사용(차감) 모드로 엽니다.
// (네비게이션 전용, 상태 변경 없음)

const endpoints = require('./endpoints.js');

module.exports.function = function openFoodExpiryUsageMode($vivContext) {
  return endpoints.OpenFoodExpiryUsageMode();
};
