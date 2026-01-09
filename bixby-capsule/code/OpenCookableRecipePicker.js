// OpenCookableRecipePicker Action Handler
// "보관 중인 식재료로 만들 수 있는 요리 보여줘" 같은 발화로
// 유통기한 화면을 열고 "보관 중인 식재료 요리" 피커를 자동으로 엽니다.
// (네비게이션 전용, 상태 변경 없음)

const endpoints = require('./endpoints.js');

module.exports.function = function openCookableRecipePicker($vivContext) {
  return endpoints.OpenCookableRecipePicker();
};
