// 간편 지출(1줄) 미리보기를 생성합니다
const endpoints = require('./endpoints');

module.exports.function = function AddQuickSimpleExpense(amount, description, payment, store) {
  const a = amount;
  const d = (description || '').trim();
  const p = (payment || '').trim();
  const s = (store || '').trim();

  const parts = [];
  if (d) parts.push(d);
  if (a !== undefined && a !== null) parts.push(`${a}원`);
  if (p) parts.push(`결제:${p}`);
  if (s) parts.push(`매장:${s}`);

  const summary = parts.join(' · ');

  return {
    amount: a,
    description: d || undefined,
    payment: p || undefined,
    store: s || undefined,
    rawLine: summary,
    message: `${summary || '간편 지출'}로 저장할까요?`
  };
};
