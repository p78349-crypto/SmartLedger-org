// 간편 지출(1줄) 확인 이후 confirmed=true 딥링크를 반환합니다
const endpoints = require('./endpoints');

module.exports.function = function ConfirmAddQuickSimpleExpense(amount, description, payment, store) {
  return endpoints.AddQuickSimpleExpense({
    amount: amount,
    description: description,
    payment: payment,
    store: store,
    autoSubmit: true,
    confirmed: true
  });
};
