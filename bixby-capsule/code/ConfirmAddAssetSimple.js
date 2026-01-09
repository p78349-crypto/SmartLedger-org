// ConfirmAddAssetSimple Action Handler
// 자산 입력(간편) 확인 이후 confirmed=true 딥링크를 반환합니다

const endpoints = require('./endpoints.js');

module.exports.function = function confirmAddAssetSimple(amount, name, category, location, memo, $vivContext) {
  const normalizedAmount = normalizeAmount(amount);
  const normalizedName = (name || '').trim();
  const normalizedLocation = (location || '').trim();
  const normalizedMemo = (memo || '').trim();
  const normalizedCategory = normalizeAssetCategory(category);

  const result = endpoints.AddAssetSimple({
    category: normalizedCategory,
    name: normalizedName,
    amount: normalizedAmount,
    location: normalizedLocation.length > 0 ? normalizedLocation : null,
    memo: normalizedMemo.length > 0 ? normalizedMemo : null,
    autoSubmit: true,
    confirmed: true
  });

  const parts = [];
  if (normalizedName) parts.push(normalizedName);
  if (normalizedAmount !== null && !Number.isNaN(normalizedAmount)) parts.push(`${normalizedAmount}원`);

  return {
    success: true,
    deepLink: result.deepLink,
    message: `${parts.join(' ')} 자산 저장을 진행합니다. 지금 "앱 열기"라고 말하면 완료됩니다.`
  };
};

function normalizeAssetCategory(category) {
  const raw = (category && (category.toString ? category.toString() : String(category))) || '';
  const clean = raw.trim().toLowerCase();

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
