// AddShoppingPoints Action Handler
// 쇼핑 포인트(저축/자산증가 + #포인트모으기) 미리보기

const endpoints = require('./endpoints.js');

module.exports.function = function addShoppingPoints(amount, description, $vivContext) {
  const normalizedAmount = normalizeAmount(amount);
  const descRaw = (description || '').trim();
  const normalizedDescription = descRaw.length > 0 ? descRaw : '쇼핑 포인트';

  const hasAmount = normalizedAmount !== null && !Number.isNaN(normalizedAmount);

  const message = hasAmount
    ? `${normalizedDescription} ${normalizedAmount}원 포인트 기록 맞나요? 저장할까요?`
    : '쇼핑 포인트를 기록할까요?';

  return {
    type: 'savings',
    amount: hasAmount ? normalizedAmount : null,
    description: normalizedDescription,
    category: null,
    message: message
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
