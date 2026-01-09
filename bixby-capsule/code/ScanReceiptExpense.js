// ScanReceiptExpense Action Handler
// "영수증 스캔해서 지출 기록해" → 지출 입력 화면(영수증 아이콘)으로 유도

const endpoints = require('./endpoints.js');

module.exports.function = function scanReceiptExpense($vivContext) {
  // 지출 입력 화면을 열고(앱 내 영수증 아이콘) 스캔을 진행하도록 안내
  const result = endpoints.OpenFeature({ feature: 'transaction_add' });

  return {
    success: true,
    deepLink: result.deepLink,
    message: '영수증 스캔 화면을 열게요. 앱이 열리면 영수증 아이콘을 눌러 촬영해 주세요. 지금 "앱 열기"라고 말하면 계속 진행됩니다.'
  };
};
