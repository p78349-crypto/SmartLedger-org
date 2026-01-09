// SmartLedger Bixby Capsule - JavaScript Endpoints
// 딥링크를 생성하여 앱을 실행합니다

module.exports = {
  /**
   * 거래 추가 액션
   * @param {object} params
   * @param {string} params.type - 'expense' | 'income' | 'savings'
   * @param {number} [params.amount] - 금액
   * @param {string} [params.description] - 상품명
   * @param {string} [params.category] - 카테고리
   * @param {boolean} [params.autoSubmit] - 앱 진입 후 자동 저장 시도
   * @param {boolean} [params.confirmed] - 확인 완료 플래그
   */
  AddTransaction: function(params) {
    const type = params.type || 'expense';
    let url = `smartledger://transaction/add?type=${encodeURIComponent(type)}`;
    
    if (params.amount !== undefined && params.amount !== null) {
      url += `&amount=${params.amount}`;
    }
    if (params.description) {
      url += `&description=${encodeURIComponent(params.description)}`;
    }
    if (params.category) {
      url += `&category=${encodeURIComponent(params.category)}`;
    }

    if (params.autoSubmit === true) {
      url += `&autoSubmit=true`;
      if (params.confirmed === true) {
        url += `&confirmed=true`;
      }
    }
    
    return {
      success: true,
      deepLink: url,
      message: `${type === 'expense' ? '지출' : type === 'income' ? '수입' : '저축'} 입력 화면을 엽니다`
    };
  },
  
  /**
   * 대시보드 열기
   */
  OpenDashboard: function() {
    return {
      success: true,
      deepLink: 'smartledger://dashboard',
      message: '대시보드를 엽니다'
    };
  },
  
  /**
   * 특정 기능 열기
   * @param {object} params
   * @param {string} params.feature - 기능 ID
   */
  OpenFeature: function(params) {
    const feature = params.feature || 'dashboard';
    const featureNames = {
      'dashboard': '대시보드',
      'food_expiry': '유통기한',
      'food_expiry_upsert': '식재료/생활용품 등록',
      'shopping_cart': '장바구니',
      'shopping_prep': '쇼핑준비',
      'assets': '자산',
      'recipe': '레시피',
      'transaction_add': '지출입력',
      'transaction_add_income': '수입입력',
      'transaction_add_detailed': '상세입력',
      'daily_transactions': '일일내역',
      'monthly_stats': '월간통계',
      'spending_analysis': '소비분석',
      'card_discount_stats': '카드할인통계',
      'points_motivation_stats': '포인트통계',
      'savings_plan': '저축플랜',
      'emergency_fund': '비상금',
      'quick_stock': '빠른 재고 차감'
      ,
      'consumables': '소모품',
      'consumable_inventory': '재고목록',
      'calendar': '캘린더',
      'settings': '설정',
      'backup': '백업',
      'trash': '휴지통',
      'voice_shortcuts': '음성단축키',
      'voice_dashboard': '음성대시보드'
    };

    const featureRoutes = {
      'dashboard': '/',
      'food_expiry': '/food/expiry',
      'food_expiry_upsert': '/food/expiry',
      'shopping_cart': '/shopping/cart',
      'shopping_prep': '/shopping/prep',
      'assets': '/asset/dashboard',
      'recipe': '/food/cooking-start',
      'transaction_add': '/transaction/add',
      'transaction_add_income': '/transaction/add-income',
      'transaction_add_detailed': '/transaction/add-detailed',
      'daily_transactions': '/transaction/daily',
      'monthly_stats': '/stats/monthly-simple',
      'spending_analysis': '/stats/spending-analysis',
      'card_discount_stats': '/stats/card-discount',
      'points_motivation_stats': '/stats/points-motivation',
      'savings_plan': '/savings/plan/list',
      'emergency_fund': '/emergency-fund',
      'quick_stock': '/household/quick-stock-use',
      'consumables': '/household/consumables',
      'consumable_inventory': '/household/inventory',
      'calendar': '/calendar',
      'settings': '/settings',
      'backup': '/backup',
      'trash': '/trash',
      'voice_shortcuts': '/settings/voice-shortcuts',
      'voice_dashboard': '/voice/dashboard'
    };

    const route = featureRoutes[feature] || '/';

    const extraParams = [];
    if (feature === 'food_expiry_upsert') {
      extraParams.push('intent=upsert');
    }

    const base = `smartledger://nav/open?route=${encodeURIComponent(route)}`;
    const deepLink = extraParams.length > 0 ? `${base}&${extraParams.join('&')}` : base;

    return {
      success: true,
      deepLink: deepLink,
      message: `${featureNames[feature] || feature}을(를) 엽니다`
    };
  },

  /**
   * 식재료/생활용품 등록 (유통기한)
   * @param {object} params
   * @param {string} params.name
   * @param {number} [params.quantity]
   * @param {string} [params.unit]
   * @param {string} [params.location]
   * @param {number} [params.expiryDays]
   * @param {number} [params.price]
   */
  UpsertFoodExpiryItem: function(params) {
    const name = (params.name || '').trim();
    let url = `smartledger://nav/open?route=${encodeURIComponent('/food/expiry')}&intent=upsert`;

    if (name) {
      url += `&name=${encodeURIComponent(name)}`;
    }
    if (params.quantity !== undefined && params.quantity !== null) {
      url += `&quantity=${params.quantity}`;
    }
    if (params.unit) {
      url += `&unit=${encodeURIComponent(params.unit)}`;
    }
    if (params.location) {
      url += `&location=${encodeURIComponent(params.location)}`;
    }
    if (params.price !== undefined && params.price !== null) {
      url += `&price=${params.price}`;
    }

    const hasExpiryDays = params.expiryDays !== undefined && params.expiryDays !== null;
    if (hasExpiryDays) {
      url += `&expiryDays=${params.expiryDays}`;
    }

    // Only attempt auto-submit when we have enough info to compute expiry date.
    if (name && hasExpiryDays) {
      url += `&autoSubmit=true`;
      // confirmed=false on purpose: the app shows a final confirmation dialog.
    }

    return {
      success: true,
      deepLink: url,
      message: '식재료/생활용품 등록 화면을 엽니다'
    };
  },
  
  /**
   * 재고 조회
   * @param {object} params
   * @param {string} params.productName - 상품명
   */
  CheckStock: function(params) {
    const productName = params.productName || '';
    const url = `smartledger://stock/check?product=${encodeURIComponent(productName)}`;
    
    // 실제 재고 정보는 앱에서 조회해야 함
    // 빅스비에서는 딥링크만 생성하고, 앱이 재고 정보를 표시
    return {
      productName: productName,
      currentStock: 0,  // 앱에서 실제 값으로 대체됨
      unit: '개',       // 앱에서 실제 값으로 대체됨
      expiryDays: null, // 앱에서 실제 값으로 대체됨
      lastPrice: null,  // 앱에서 실제 값으로 대체됨
      location: null,   // 앱에서 실제 값으로 대체됨
      deepLink: url
    };
  },
  
  /**
   * 재고 차감 (사용)
   * @param {object} params
   * @param {string} params.productName - 상품명
   * @param {number} [params.amount] - 차감 수량
   * @param {string} [params.unit] - 단위
   */
  UseStock: function(params) {
    const productName = params.productName || '';

    let url = `smartledger://stock/use?product=${encodeURIComponent(productName)}`;
    if (params.amount !== undefined && params.amount !== null) {
      url += `&amount=${params.amount}`;
    }
    if (params.unit) {
      url += `&unit=${encodeURIComponent(params.unit)}`;
    }
    url += `&autoSubmit=true`;  // 음성 명령으로 "응"이라고 하면 자동 제출
    
    return {
      success: true,
      deepLink: url,
      message: params.amount !== undefined && params.amount !== null
        ? `${productName} ${params.amount}${params.unit || ''} 차감 화면을 엽니다`
        : `${productName} 전량 차감 화면을 엽니다`
    };
  }
};
