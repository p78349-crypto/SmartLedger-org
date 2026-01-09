// ConfirmAddShoppingPoints Action Handler
// 미리보기(확인) 이후 confirmed=true 딥링크를 반환합니다

const endpoints = require('./endpoints.js');

module.exports.function = function confirmAddShoppingPoints(amount, description, $vivContext) {
  const normalizedAmount = normalizeAmount(amount);
  const descRaw = (description || '').trim();
  const normalizedDescription = descRaw.length > 0 ? descRaw : '쇼핑 포인트';

  const memo = '#포인트모으기';

  const result = endpoints.AddTransaction({
    type: 'savings',
    amount: normalizedAmount,
    description: normalizedDescription,
    category: null,
    memo: memo,
    savingsAllocation: 'assetIncrease',
    autoSubmit: true,
    confirmed: true
  });

  const summaryParts = [];
  if (normalizedDescription.length > 0) summaryParts.push(normalizedDescription);
  if (normalizedAmount !== null && !Number.isNaN(normalizedAmount)) summaryParts.push(`${normalizedAmount}원`);
  summaryParts.push('포인트');

  return {
    success: true,
    deepLink: result.deepLink,
    message: `${summaryParts.join(' ')} 입력을 진행합니다. 지금 "앱 열기"라고 말하면 완료됩니다.`
  };
};

function normalizeAmount(amount) {
  if (amount === undefined || amount === null) return null;
  if (typeof amount === 'number') return amount;
  if (typeof amount === 'object' && amount.value !== undefined) {
    const v = Number(amount.value);
    return Number.isNaN(v) ? null : v;
  }
  const v = Number(amount);
  return Number.isNaN(v) ? null : v;
}
