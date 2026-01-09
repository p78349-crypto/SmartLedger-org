// ConfirmAddTransaction Action Handler
// 미리보기(확인) 이후 confirmed=true 딥링크를 반환합니다

const endpoints = require('./endpoints.js');

module.exports.function = function confirmAddTransaction(type, amount, quantity, unit, unitPrice, description, category, memo, paymentMethod, store, $vivContext) {
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

  const hasAmount = normalizedAmount !== null && !Number.isNaN(normalizedAmount);
  const hasQuantity = normalizedQuantity !== null && !Number.isNaN(normalizedQuantity) && normalizedQuantity > 0;
  const hasUnitPrice = normalizedUnitPrice !== null && !Number.isNaN(normalizedUnitPrice) && normalizedUnitPrice > 0;

  const effectiveAmount = hasAmount
    ? normalizedAmount
    : (hasQuantity && hasUnitPrice ? (normalizedQuantity * normalizedUnitPrice) : null);

  const result = endpoints.AddTransaction({
    type: normalizedType,
    amount: effectiveAmount,
    quantity: normalizedQuantity,
    unit: normalizedUnit.length > 0 ? normalizedUnit : null,
    unitPrice: normalizedUnitPrice,
    description: normalizedDescription.length > 0 ? normalizedDescription : null,
    category: normalizedCategory.length > 0 ? normalizedCategory : null,
    memo: normalizedMemo.length > 0 ? normalizedMemo : null,
    paymentMethod: normalizedPaymentMethod.length > 0 ? normalizedPaymentMethod : null,
    store: normalizedStore.length > 0 ? normalizedStore : null,
    autoSubmit: true,
    confirmed: true
  });

  // 메시지 조금 더 명확하게
  const typeKo = normalizedType === 'income'
    ? '수입'
    : normalizedType === 'savings'
      ? '저축'
      : normalizedType === 'refund'
        ? '반품'
      : '지출';

  const summaryParts = [];
  if (normalizedDescription.length > 0) summaryParts.push(normalizedDescription);
  if (effectiveAmount !== null && !Number.isNaN(effectiveAmount)) summaryParts.push(`${effectiveAmount}원`);
  if (normalizedQuantity !== null && !Number.isNaN(normalizedQuantity) && normalizedQuantity > 0) {
    const unitText = normalizedUnit.length > 0 ? normalizedUnit : '';
    summaryParts.push(`${normalizedQuantity}${unitText}`);
  }
  if (normalizedUnitPrice !== null && !Number.isNaN(normalizedUnitPrice) && normalizedUnitPrice > 0) {
    summaryParts.push(`단가:${normalizedUnitPrice}원`);
  }
  summaryParts.push(typeKo);
  if (normalizedMemo.length > 0) summaryParts.push(`메모:${normalizedMemo}`);
  if (normalizedPaymentMethod.length > 0) summaryParts.push(`결제:${normalizedPaymentMethod}`);
  if (normalizedStore.length > 0) summaryParts.push(`매장:${normalizedStore}`);

  return {
    success: true,
    deepLink: result.deepLink,
    message: `${summaryParts.join(' ')} 저장을 진행합니다. 지금 "앱 열기"라고 말하면 완료됩니다.`
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
