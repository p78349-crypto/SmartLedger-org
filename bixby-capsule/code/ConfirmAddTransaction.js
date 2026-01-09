// ConfirmAddTransaction Action Handler
// 미리보기(확인) 이후 confirmed=true 딥링크를 반환합니다

const endpoints = require('./endpoints.js');

module.exports.function = function confirmAddTransaction(type, amount, description, category, $vivContext) {
  const normalizedType = normalizeTransactionType(type);
  const normalizedAmount = normalizeAmount(amount);
  const normalizedDescription = (description || '').trim();
  const normalizedCategory = (category || '').trim();

  const result = endpoints.AddTransaction({
    type: normalizedType,
    amount: normalizedAmount,
    description: normalizedDescription.length > 0 ? normalizedDescription : null,
    category: normalizedCategory.length > 0 ? normalizedCategory : null,
    autoSubmit: true,
    confirmed: true
  });

  // 메시지 조금 더 명확하게
  const typeKo = normalizedType === 'income'
    ? '수입'
    : normalizedType === 'savings'
      ? '저축'
      : '지출';

  const summaryParts = [];
  if (normalizedDescription.length > 0) summaryParts.push(normalizedDescription);
  if (normalizedAmount !== null && !Number.isNaN(normalizedAmount)) summaryParts.push(`${normalizedAmount}원`);
  summaryParts.push(typeKo);

  return {
    success: true,
    deepLink: result.deepLink,
    message: `${summaryParts.join(' ')} 저장을 진행합니다`
  };
};

function normalizeTransactionType(type) {
  const raw = (type && (type.toString ? type.toString() : String(type))) || '';
  const clean = raw.trim().toLowerCase();

  const koMap = {
    '지출': 'expense',
    '소비': 'expense',
    '쓴돈': 'expense',
    '수입': 'income',
    '월급': 'income',
    '급여': 'income',
    '벌이': 'income',
    '저축': 'savings',
    '적금': 'savings',
    '저금': 'savings'
  };

  if (koMap[raw]) return koMap[raw];
  if (clean === 'expense' || clean === 'income' || clean === 'savings') return clean;
  return 'expense';
}

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
