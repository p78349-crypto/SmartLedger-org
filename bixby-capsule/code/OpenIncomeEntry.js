// OpenIncomeEntry Action Handler
// "월급 기록해" → 수입 입력 화면(Income)으로 유도

const endpoints = require('./endpoints.js');

module.exports.function = function openIncomeEntry($vivContext) {
  const result = endpoints.OpenFeature({ feature: 'transaction_add_income' });

  // message를 보강 (기존 endpoints 메시지를 덮어씀)
  return {
    success: true,
    deepLink: result.deepLink,
    message: '수입 입력 화면을 엽니다. 지금 \'앱 열기\'라고 말하면 계속할 수 있어요.'
  };
};
