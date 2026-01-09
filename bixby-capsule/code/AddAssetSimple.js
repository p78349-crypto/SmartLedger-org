// AddAssetSimple Action Handler
// 자산 입력(간편) 미리보기를 생성합니다

const endpoints = require('./endpoints.js');

module.exports.function = function addAssetSimple(amount, name, category, location, memo, $vivContext) {
  const normalizedAmount = normalizeAmount(amount);
  const normalizedName = (name || '').trim();
  const normalizedLocation = (location || '').trim();
  const normalizedMemo = (memo || '').trim();
  const normalizedCategory = normalizeAssetCategory(category);

  const categoryKo = categoryKoLabel(normalizedCategory);

  let message = '자산을 저장할까요?';
  if (normalizedName && normalizedAmount !== null && !Number.isNaN(normalizedAmount)) {
    message = `${categoryKo} | ${normalizedName} ${normalizedAmount}원 맞나요? 자산 저장할까요?`;
  }

  return {
    category: normalizedCategory,
    name: normalizedName,
    amount: normalizedAmount,
    location: normalizedLocation.length > 0 ? normalizedLocation : null,
    memo: normalizedMemo.length > 0 ? normalizedMemo : null,
    message
  };
};

function normalizeAssetCategory(category) {
  const raw = (category && (category.toString ? category.toString() : String(category))) || '';
  const clean = raw.trim().toLowerCase();

  // Bixby enum symbol or Korean text 대응
  const koMap = {
    '현금': 'cash',
    '예금/적금': 'deposit',
    '예금': 'deposit',
    '적금': 'deposit',
    '소액 투자': 'stock',
    '투자': 'stock',
    '기타 실물 자산': 'other',
    '기타': 'other'
  };

  if (koMap[raw]) return koMap[raw];
  if (clean === 'cash' || clean === 'deposit' || clean === 'stock' || clean === 'other') return clean;
  return 'cash';
}

function categoryKoLabel(category) {
  switch (category) {
    case 'deposit':
      return '예금/적금';
    case 'stock':
      return '소액 투자';
    case 'other':
      return '기타 실물 자산';
    case 'cash':
    default:
      return '현금';
  }
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
