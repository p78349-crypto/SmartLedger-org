// OpenFeature Action Handler
// 특정 기능 열기 요청을 처리합니다

const endpoints = require('./endpoints.js');

module.exports.function = function openFeature(featureType, $vivContext) {
  // featureType 매핑 (한국어 → ID)
  const featureMap = {
    // 대시보드 관련
    '대시보드': 'dashboard',
    '홈': 'dashboard',
    '메인': 'dashboard',
    '요약': 'dashboard',
    
    // 유통기한 관련
    '유통기한': 'food_expiry',
    '식재료': 'food_expiry',
    '냉장고': 'food_expiry',
    '재료관리': 'food_expiry',

    // 식재료/생활용품 등록 바로 열기
    '식재료 등록': 'food_expiry_upsert',
    '생활용품 등록': 'food_expiry_upsert',
    '재료 등록': 'food_expiry_upsert',
    '우리집 식재료 등록': 'food_expiry_upsert',
    '우리집 생활용품 등록': 'food_expiry_upsert',
    
    // 장바구니 관련
    '장바구니': 'shopping_cart',
    '쇼핑리스트': 'shopping_cart',
    '쇼핑목록': 'shopping_cart',
    '구매목록': 'shopping_cart',

    // 쇼핑 준비
    '쇼핑준비': 'shopping_prep',
    '쇼핑준비하기': 'shopping_prep',
    '장보기준비': 'shopping_prep',
    
    // 자산 관련
    '자산': 'assets',
    '자산현황': 'assets',
    '재산': 'assets',
    '통장': 'assets',
    
    // 레시피 관련
    '레시피': 'recipe',
    '요리': 'recipe',
    '음식': 'recipe',
    '메뉴': 'recipe',
    
    // 지출입력 관련
    '지출입력': 'transaction_add',
    '수입입력': 'transaction_add',
    '입력': 'transaction_add'
    ,

    // 수입 입력
    '수입 추가': 'transaction_add_income',
    '월급 입력': 'transaction_add_income',
    '급여 입력': 'transaction_add_income',

    // 상세 입력
    '상세입력': 'transaction_add_detailed',
    '상세 지출입력': 'transaction_add_detailed',

    // 일일내역
    '일일내역': 'daily_transactions',
    '오늘 내역': 'daily_transactions',

    // 통계/분석
    '월간통계': 'monthly_stats',
    '월 통계': 'monthly_stats',
    '소비분석': 'spending_analysis',
    '지출 분석': 'spending_analysis',
    '카드할인통계': 'card_discount_stats',
    '포인트통계': 'points_motivation_stats',

    // 저축/비상금
    '저축플랜': 'savings_plan',
    '저축 계획': 'savings_plan',
    '비상금': 'emergency_fund',
    '긴급자금': 'emergency_fund',

    // 소모품/재고
    '소모품': 'consumables',
    '재고목록': 'consumable_inventory',
    '재고': 'consumable_inventory',

    // 캘린더
    '캘린더': 'calendar',
    '달력': 'calendar',

    // 설정
    '설정': 'settings',
    '환경설정': 'settings',
    '옵션': 'settings',
    '세팅': 'settings',

    // 백업/휴지통
    '백업': 'backup',
    '백업하기': 'backup',
    '휴지통': 'trash',
    '삭제함': 'trash',

    // 음성
    '음성단축키': 'voice_shortcuts',
    '음성대시보드': 'voice_dashboard'
  };
  
  const feature = featureMap[featureType] || featureType || 'dashboard';
  
  return endpoints.OpenFeature({ feature: feature });
};
