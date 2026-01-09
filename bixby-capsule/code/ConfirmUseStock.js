// ConfirmUseStock Action Handler
// 미리보기(확인) 이후 confirmed=true 딥링크를 반환합니다

const endpoints = require('./endpoints.js');

module.exports.function = function confirmUseStock(productName, amount, unit, $vivContext) {
  const normalizedName = normalizeProductName(productName);
  const a = normalizeNumber(amount);
  const u = (unit || '').trim();

  const result = endpoints.UseStock({
    productName: normalizedName,
    amount: a,
    unit: u || null,
    autoSubmit: true,
    confirmed: true
  });

  const hasAmount = a !== null && !Number.isNaN(a);
  const summary = hasAmount
    ? `${normalizedName} ${u ? `${a}${u}` : a}`
    : `${normalizedName} 전량`;

  return {
    success: true,
    deepLink: result.deepLink,
    message: `${summary} 차감을 진행합니다. 지금 "앱 열기"라고 말하면 완료됩니다.`
  };
};

function normalizeProductName(name) {
  if (!name) return '';
  const synonymMap = {
    '팽이': '팽이버섯',
    '팽이버섯': '팽이버섯',
    '새송이': '새송이버섯',
    '표고': '표고버섯',
    '양파': '양파',
    '당근': '당근',
    '감자': '감자',
    '대파': '대파',
    '파': '대파',
    '마늘': '마늘',
    '달걀': '달걀',
    '계란': '달걀',
    '에그': '달걀',
    '소고기': '소고기',
    '쇠고기': '소고기',
    '돼지고기': '돼지고기',
    '삼겹살': '삼겹살',
    '닭고기': '닭고기',
    '닭': '닭고기',
    '새우': '새우',
    '오징어': '오징어',
    '우유': '우유',
    '치즈': '치즈',
    '두부': '두부',
    '라면': '라면',
    '사태살': '사태살',
    '사태': '사태살',
    '아욱': '아욱',
    '아우': '아욱'
  };
  const clean = name.trim();
  return synonymMap[clean] || clean;
}

function normalizeNumber(v) {
  if (v === undefined || v === null) return null;
  if (typeof v === 'number') return v;
  if (typeof v === 'object' && v.value !== undefined) {
    const n = Number(v.value);
    return Number.isNaN(n) ? null : n;
  }
  const n = Number(v);
  return Number.isNaN(n) ? null : n;
}
