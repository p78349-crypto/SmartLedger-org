// ConfirmUpsertFoodExpiryItem Action Handler
// 미리보기(확인) 이후 confirmed=true 딥링크를 반환합니다

const endpoints = require('./endpoints.js');

module.exports.function = function confirmUpsertFoodExpiryItem(name, quantity, unit, location, category, supplier, memo, purchaseDateText, healthTagsText, expiryDays, expiryText, price, $vivContext) {
  const n = (name || '').trim();
  const q = normalizeNumber(quantity);
  const u = (unit || '').trim();
  const loc = normalizeLocation(location);
  const cat = normalizeCategory(category);
  const sup = normalizeSupplier(supplier);
  const m = normalizeMemo(memo);
  const purchaseText = normalizePurchaseDateText(purchaseDateText);
  const tagsText = normalizeHealthTagsText(healthTagsText);
  const days = normalizeExpiryDays(expiryDays, expiryText);
  const p = normalizeNumber(price);

  const result = endpoints.UpsertFoodExpiryItem({
    name: n,
    quantity: q,
    unit: u || null,
    location: loc || null,
    category: cat || null,
    supplier: sup || null,
    memo: m || null,
    purchaseDate: purchaseText || null,
    healthTags: tagsText || null,
    expiryDays: days,
    price: p,
    autoSubmit: true,
    confirmed: true
  });

  const parts = [];
  if (n) parts.push(n);
  if (q !== null && !Number.isNaN(q)) parts.push(u ? `${q}${u}` : `${q}`);
  if (loc) parts.push(loc);
  if (cat) parts.push(cat);
  if (sup) parts.push(`구매처 ${sup}`);
  if (purchaseText) parts.push(`구매일 ${purchaseText}`);
  if (tagsText) parts.push(`태그 ${tagsText}`);
  if (days !== null && !Number.isNaN(days)) parts.push(`${days}일 후`);

  return {
    success: true,
    deepLink: result.deepLink,
    message: `${parts.length ? parts.join(' ') : '식재료'} 등록을 진행합니다. 지금 "앱 열기"라고 말하면 완료됩니다.`
  };
};

function normalizeHealthTagsText(v) {
  const raw = (v || '').toString().trim();
  if (!raw) return '';

  const known = ['탄수화물', '당류', '주류'];
  const found = [];
  for (const t of known) {
    if (raw.includes(t)) found.push(t);
  }

  const normalized = raw.replace(/\|/g, ',');
  const parts = normalized
    .split(',')
    .flatMap(p => p.split(/\s+/g))
    .map(s => s.trim())
    .filter(Boolean);

  for (const p of parts) {
    if (known.includes(p) && !found.includes(p)) found.push(p);
  }

  return found.join(' ');
}

function normalizeSupplier(v) {
  const raw = (v || '').toString().trim();
  if (!raw) return '';

  let out = raw;
  out = out.replace(/[\s\-–—]+$/g, '').trim();

  const suffixes = [
    '에서 산 거',
    '에서 산것',
    '에서 산',
    '에서 구매한',
    '에서 구매',
    '에서 구입한',
    '에서 구입',
    '에서',
  ];

  for (const s of suffixes) {
    if (out.endsWith(s)) {
      out = out.slice(0, -s.length).trim();
      break;
    }
  }

  return out;
}

function normalizeMemo(v) {
  const raw = (v || '').toString().trim();
  if (!raw) return '';

  let out = raw
    .replace(/^메모\s*/g, '')
    .replace(/^노트\s*/g, '')
    .replace(/^설명\s*/g, '')
    .trim();

  out = out.replace(/^"(.+)"$/g, '$1').replace(/^'(.+)'$/g, '$1').trim();

  out = out.replace(/[.!?~]+$/g, '').trim();

  const suffixes = [
    '이라서요',
    '라서요',
    '여서요',
    '해서요',
    '이라서',
    '라서',
    '여서',
    '해서',
    '라',
    '야'
  ];
  for (const s of suffixes) {
    if (out.endsWith(s) && out.length > s.length) {
      const trimmed = out.slice(0, -s.length).trim();
      if (trimmed) {
        out = trimmed;
      }
      break;
    }
  }

  return out;
}

function normalizePurchaseDateText(v) {
  const raw = (v || '').toString().trim();
  if (!raw) return '';

  const compact = raw.replace(/\s+/g, '');

  if (compact.includes('어제')) return '어제';
  if (compact.includes('오늘')) return '오늘';
  if (compact.includes('방금') || compact.includes('막')) return '오늘';

  let out = raw;
  out = out.replace(/[.!?~]+$/g, '').trim();
  const suffixes = [
    '에샀어',
    '에샀어요',
    '에산거',
    '에산것',
    '에산',
    '샀어',
    '샀어요',
    '산거',
    '산것',
    '산',
    '구매했어',
    '구매했어요',
    '구매한거',
    '구매한',
    '구입했어',
    '구입했어요',
    '구입한',
  ];

  const outCompact = out.replace(/\s+/g, '');
  for (const s of suffixes) {
    if (outCompact.endsWith(s)) {
      out = out.slice(0, Math.max(0, out.length - s.length)).trim();
      break;
    }
  }

  return out;
}

function normalizeLocation(v) {
  const raw = (v || '').toString().trim();
  if (!raw) return '';

  const compact = raw.replace(/\s+/g, '');

  if (compact === '냉장고') return '냉장';
  if (compact === '냉동실') return '냉동';
  if (compact === '상온') return '실온';
  if (compact === '김치냉장고' || compact === '김치냉장') return '김치냉장고';

  return raw;
}

function normalizeCategory(v) {
  const raw = (v || '').toString().trim();
  if (!raw) return '';

  const compact = raw.replace(/\s+/g, '');

  if (compact === '야채') return '채소';
  if (compact === '고기') return '육류';
  if (compact === '생선' || compact === '해산물') return '수산물';
  if (compact === '우유' || compact === '치즈' || compact === '요구르트') return '유제품';
  if (compact === '냉동') return '냉동식품';
  if (compact === '음료수') return '음료';
  if (compact === '양념' || compact === '소스') return '양념/소스';

  return raw;
}

function normalizeNumber(v) {
  if (v === undefined || v === null) return null;
  if (typeof v === 'number') return v;
  if (typeof v === 'object' && v.value !== undefined) {
    const n = Number(v.value);
    return Number.isNaN(n) ? null : n;
  }
  if (typeof v === 'string') {
    const cleaned = v.replace(/[^0-9.\-]/g, '').trim();
    if (!cleaned) return null;
    const n = Number(cleaned);
    return Number.isNaN(n) ? null : n;
  }

  const n = Number(v);
  return Number.isNaN(n) ? null : n;
}

function normalizeExpiryDays(expiryDays, expiryText) {
  const direct = normalizeNumber(expiryDays);
  if (direct !== null && !Number.isNaN(direct)) return direct;

  const raw = (expiryText || '').toString().trim();
  if (!raw) return null;

  // "~까지" phrases (deadline style)
  const compact = raw.replace(/\s+/g, '');
  if (compact === '오늘까지') return 0;
  if (compact === '내일까지') return 1;
  if (compact === '모레까지') return 2;

  // Weekend / weekday deadlines
  if (compact === '주말까지' || compact === '이번주주말까지') {
    return daysUntilWeekday(6);
  }
  if (compact === '토요일까지' || compact === '이번주토요일까지' || compact === '토까지') {
    return daysUntilWeekday(6);
  }
  if (compact === '일요일까지' || compact === '이번주일요일까지' || compact === '일까지') {
    return daysUntilWeekday(0);
  }

  // "이번주까지" -> days until end of this week (Sunday)
  if (compact === '이번주까지' || compact === '금주까지') {
    return daysUntilWeekday(0);
  }

  if (raw === '오늘') return 0;
  if (raw === '내일') return 1;
  if (raw === '모레') return 2;

  const mDays = raw.match(/(\d{1,3})\s*일\s*(후|뒤)/);
  if (mDays) {
    const n = Number(mDays[1]);
    return Number.isNaN(n) ? null : n;
  }

  const mDate = raw.match(/(\d{1,2})\s*월\s*(\d{1,2})\s*일/);
  if (mDate) {
    const month = Number(mDate[1]);
    const day = Number(mDate[2]);
    if (Number.isNaN(month) || Number.isNaN(day)) return null;

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    let target = new Date(now.getFullYear(), month - 1, day);
    if (target < today) {
      target = new Date(now.getFullYear() + 1, month - 1, day);
    }
    const diffMs = target.getTime() - today.getTime();
    const diffDays = Math.round(diffMs / (24 * 60 * 60 * 1000));
    return diffDays >= 0 ? diffDays : null;
  }

  return null;
}

function daysUntilWeekday(targetDay) {
  const now = new Date();
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const day = today.getDay();
  return (targetDay - day + 7) % 7;
}
