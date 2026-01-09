// AddTransaction Action Handler
// 거래 추가 요청을 처리하여 딥링크를 반환합니다

const endpoints = require('./endpoints.js');

module.exports.function = function addTransaction(type, amount, quantity, unit, unitPrice, description, category, memo, paymentMethod, store, $vivContext) {
  const normalizedType = normalizeTransactionType(type);
  const normalizedAmount = normalizeAmount(amount);
  const normalizedQuantity = normalizeNumber(quantity);
  const normalizedUnit = (unit || '').trim();
  const normalizedUnitPrice = normalizeNumber(unitPrice);
  const normalizedDescription = (description || '').trim();
  const normalizedCategory = (category || '').trim();
  const normalizedMemo = (memo || '').trim();
  const normalizedPaymentMethod = (paymentMethod || '').trim();
  const normalizedStore = (store || '').trim();

  const typeKo = normalizedType === 'income'
    ? '수입'
    : normalizedType === 'savings'
      ? '저축'
      : normalizedType === 'refund'
        ? '반품'
      : '지출';

  const hasDesc = normalizedDescription.length > 0;
  const hasAmount = normalizedAmount !== null && !Number.isNaN(normalizedAmount);
  const hasQuantity = normalizedQuantity !== null && !Number.isNaN(normalizedQuantity) && normalizedQuantity > 0;
  const hasUnit = normalizedUnit.length > 0;
  const hasUnitPrice = normalizedUnitPrice !== null && !Number.isNaN(normalizedUnitPrice) && normalizedUnitPrice > 0;

  const effectiveAmount = hasAmount
    ? normalizedAmount
    : (hasQuantity && hasUnitPrice ? (normalizedQuantity * normalizedUnitPrice) : null);
  const hasEffectiveAmount = effectiveAmount !== null && !Number.isNaN(effectiveAmount);

  const extras = [];
  if (hasQuantity || hasUnit) extras.push(`수량:${hasQuantity ? normalizedQuantity : ''}${hasUnit ? normalizedUnit : ''}`);
  if (hasUnitPrice) extras.push(`단가:${normalizedUnitPrice}원`);
  if (normalizedCategory.length > 0) extras.push(`카테고리:${normalizedCategory}`);
  if (normalizedMemo.length > 0) extras.push(`메모:${normalizedMemo}`);
  if (normalizedPaymentMethod.length > 0) extras.push(`결제:${normalizedPaymentMethod}`);
  if (normalizedStore.length > 0) extras.push(`매장:${normalizedStore}`);

  let message = `${typeKo}을(를) 기록할까요?`;
  if (hasDesc && hasEffectiveAmount) {
    message = `${normalizedDescription} ${effectiveAmount}원 ${typeKo} 맞나요?${extras.length > 0 ? ' ' + extras.join(' ') : ''} 저장할까요?`;
  } else if (hasEffectiveAmount) {
    message = `${effectiveAmount}원 ${typeKo} 맞나요?${extras.length > 0 ? ' ' + extras.join(' ') : ''} 저장할까요?`;
  } else if (hasDesc) {
    message = `${normalizedDescription} ${typeKo} 맞나요?${extras.length > 0 ? ' ' + extras.join(' ') : ''} 저장할까요?`;
  }

  return {
    type: normalizedType,
    amount: hasAmount ? normalizedAmount : (hasEffectiveAmount ? effectiveAmount : null),
    quantity: hasQuantity ? normalizedQuantity : null,
    unit: hasUnit ? normalizedUnit : null,
    unitPrice: hasUnitPrice ? normalizedUnitPrice : null,
    description: hasDesc ? normalizedDescription : null,
    category: normalizedCategory.length > 0 ? normalizedCategory : null,
    memo: normalizedMemo.length > 0 ? normalizedMemo : null,
    paymentMethod: normalizedPaymentMethod.length > 0 ? normalizedPaymentMethod : null,
    store: normalizedStore.length > 0 ? normalizedStore : null,
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
    '저금': 'savings',
    '반품': 'refund',
    '환불': 'refund'
  };

  if (koMap[raw]) return koMap[raw];
  if (clean === 'expense' || clean === 'income' || clean === 'savings' || clean === 'refund') return clean;
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

function normalizeNumber(value) {
  if (value === undefined || value === null) return null;
  if (typeof value === 'number') return value;
  if (typeof value === 'object' && value.value !== undefined) {
    const v = Number(value.value);
    return Number.isNaN(v) ? null : v;
  }
  const v = Number(value);
  return Number.isNaN(v) ? null : v;
}
