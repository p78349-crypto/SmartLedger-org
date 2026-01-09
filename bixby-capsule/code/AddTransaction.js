// AddTransaction Action Handler
// 거래 추가 요청을 처리하여 딥링크를 반환합니다

const endpoints = require('./endpoints.js');

module.exports.function = function addTransaction(type, amount, description, category, $vivContext) {
  const normalizedType = normalizeTransactionType(type);
  const normalizedAmount = normalizeAmount(amount);
  const normalizedDescription = (description || '').trim();
  const normalizedCategory = (category || '').trim();

  const typeKo = normalizedType === 'income'
    ? '수입'
    : normalizedType === 'savings'
      ? '저축'
      : '지출';

  const hasDesc = normalizedDescription.length > 0;
  const hasAmount = normalizedAmount !== null && !Number.isNaN(normalizedAmount);

  let message = `${typeKo}을(를) 기록할까요?`;
  if (hasDesc && hasAmount) {
    message = `${normalizedDescription} ${normalizedAmount}원 ${typeKo} 맞나요? 저장할까요?`;
  } else if (hasAmount) {
    message = `${normalizedAmount}원 ${typeKo} 맞나요? 저장할까요?`;
  } else if (hasDesc) {
    message = `${normalizedDescription} ${typeKo} 맞나요? 저장할까요?`;
  }

  return {
    type: normalizedType,
    amount: hasAmount ? normalizedAmount : null,
    description: hasDesc ? normalizedDescription : null,
    category: normalizedCategory.length > 0 ? normalizedCategory : null,
    message: message
  };
};

function normalizeTransactionType(type) {
  // Bixby enum symbol or Korean text 모두 대응
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
