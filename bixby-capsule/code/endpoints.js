// SmartLedger Bixby Capsule - JavaScript Endpoints
// 딥링크를 생성하여 앱을 실행합니다

module.exports = {
  /**
   * 거래 추가 액션
   * @param {object} params
   * @param {string} params.type - 'expense' | 'income' | 'savings'
   * @param {number} [params.amount] - 금액
   * @param {number} [params.quantity] - 수량
   * @param {string} [params.unit] - 단위
   * @param {number} [params.unitPrice] - 단가
   * @param {string} [params.description] - 상품명
   * @param {string} [params.category] - 카테고리
    * @param {string} [params.memo] - 메모 (예: #포인트모으기)
    * @param {string} [params.savingsAllocation] - 'assetIncrease' | 'expense'
   * @param {boolean} [params.autoSubmit] - 앱 진입 후 자동 저장 시도
   * @param {boolean} [params.confirmed] - 확인 완료 플래그
   */
  AddTransaction: function(params) {
    const type = params.type || 'expense';
    let url = `smartledger://transaction/add?type=${encodeURIComponent(type)}`;
    
    if (params.amount !== undefined && params.amount !== null) {
      url += `&amount=${params.amount}`;
    }
    if (params.quantity !== undefined && params.quantity !== null) {
      url += `&quantity=${params.quantity}`;
    }
    if (params.unit) {
      url += `&unit=${encodeURIComponent(params.unit)}`;
    }
    if (params.unitPrice !== undefined && params.unitPrice !== null) {
      url += `&unitPrice=${params.unitPrice}`;
    }
    if (params.description) {
      url += `&description=${encodeURIComponent(params.description)}`;
    }
    if (params.category) {
      url += `&category=${encodeURIComponent(params.category)}`;
    }

    if (params.paymentMethod) {
      url += `&paymentMethod=${encodeURIComponent(params.paymentMethod)}`;
    }

    if (params.store) {
      url += `&store=${encodeURIComponent(params.store)}`;
    }

    if (params.memo) {
      url += `&memo=${encodeURIComponent(params.memo)}`;
    }

    if (params.savingsAllocation) {
      url += `&savingsAllocation=${encodeURIComponent(params.savingsAllocation)}`;
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

  // Navigation-only: Open Food Expiry screen and scroll to recipe recommendation section
  OpenRecipeRecommendation: function() {
    // Keep this navigation-only.
    // DeepLinkHandler interprets intent=recipe_recommendation and scrolls to the section.
    const deepLink = `smartledger://nav/open?route=${encodeURIComponent('/food/expiry')}&intent=recipe_recommendation`;

    return {
      success: true,
      deepLink: deepLink,
      message: '오늘의 요리 추천 섹션을 엽니다'
    };
  },

  // Navigation-only: Open Food Expiry screen and open the cookable recipe picker
  OpenCookableRecipePicker: function() {
    const deepLink = `smartledger://nav/open?route=${encodeURIComponent('/food/expiry')}&intent=cookable_recipe_picker`;

    return {
      success: true,
      deepLink: deepLink,
      message: '보관 중인 식재료 요리 피커를 엽니다'
    };
  },

  // Navigation-only: Open Food Expiry screen in usage (decrement) mode
  OpenFoodExpiryUsageMode: function() {
    const deepLink = `smartledger://nav/open?route=${encodeURIComponent('/food/expiry')}&intent=usage_mode`;

    return {
      success: true,
      deepLink: deepLink,
      message: '유통기한 사용(차감) 모드를 엽니다'
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
      'shopping_points_input': '포인트 입력',
      'shopping_prep': '쇼핑준비',
      'assets': '자산',
      'recipe': '레시피',
      'transaction_add': '지출입력',
      'transaction_add_income': '수입입력',
      'transaction_add_detailed': '상세입력',
      'quick_simple_expense_input': '간편 지출',
      'daily_transactions': '일일내역',
      'income_detail': '수입 상세',
      'income_split': '수입배분',
      'refunds': '반품',
      'project_100m': '1억 프로젝트',
      'weather_manual_input': '날씨 입력',
      'stats_overview': '통계',
      'fixed_cost_stats': '고정비 통계',
      'period_stats_week': '주간 리포트',
      'period_stats_month': '월간 리포트',
      'period_stats_quarter': '분기 리포트',
      'period_stats_half_year': '반기 리포트',
      'period_stats_year': '연간 리포트',
      'period_stats_decade': '10년',
      'stats_search': '통계 검색',
      'shopping_cheapest_month': '최저가 달',
      'monthly_stats': '월간통계',
      'spending_analysis': '소비분석',
      'card_discount_stats': '카드할인통계',
      'points_motivation_stats': '포인트통계',
      'weather_price_prediction': '날씨 기반 가격 예측',
      'savings_plan': '저축플랜',
      'emergency_fund': '비상금',
      'quick_stock': '빠른 재고 차감'
      ,
      'consumables': '소모품',
      'consumable_inventory': '재고목록',
      'calendar': '캘린더',

      'asset_input': '자산 입력',
      'asset_allocation': '자산 배분',
      'asset_management': '자산 평가',
      'icon_management_asset': '자산 아이콘 관리',

      'root_transactions': '전체 거래',
      'root_search': '루트 검색',
      'root_account_manage': '계정 관리',
      'root_month_end': '월말 정산',
      'screen_saver_settings': '보호기 설정',
      'icon_management_root': '루트 아이콘 관리',

      'application_settings': '애플리케이션 설정',
      'theme_settings': '테마',
      'display_settings': '표시/폰트',
      'language_settings': '언어 설정',
      'currency_settings': '통화 설정',

      'nutrition_report': '레시피/식재료 검색',
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
      'shopping_points_input': '/shopping/points-input',
      'shopping_prep': '/shopping/prep',
      'assets': '/asset/dashboard',
      'recipe': '/food/cooking-start',
      'transaction_add': '/transaction/add',
      'transaction_add_income': '/transaction/add-income',
      'transaction_add_detailed': '/transaction/add-detailed',
      'quick_simple_expense_input': '/transaction/quick-simple-expense',
      'daily_transactions': '/transaction/daily',
      'income_detail': '/transaction/detail-income',
      'income_split': '/income/split',
      'refunds': '/transaction/refund',
      'project_100m': '/asset/project-100m',
      'weather_manual_input': '/weather/manual-input',
      'stats_overview': '/stats/monthly',
      'fixed_cost_stats': '/fixed-cost/stats',
      'period_stats_week': '/stats/period/week',
      'period_stats_month': '/stats/period/month',
      'period_stats_quarter': '/stats/period/quarter',
      'period_stats_half_year': '/stats/period/half-year',
      'period_stats_year': '/stats/period/year',
      'period_stats_decade': '/stats/period/decade',
      'stats_search': '/stats/search',
      'shopping_cheapest_month': '/stats/shopping/cheapest-month',
      'monthly_stats': '/stats/monthly-simple',
      'spending_analysis': '/stats/spending-analysis',
      'card_discount_stats': '/stats/card-discount',
      'points_motivation_stats': '/stats/points-motivation',
      'weather_price_prediction': '/stats/weather-price-prediction',
      'savings_plan': '/savings/plan/list',
      'emergency_fund': '/emergency-fund',
      'quick_stock': '/household/quick-stock-use',
      'consumables': '/household/consumables',
      'consumable_inventory': '/household/inventory',
      'calendar': '/calendar',

      'asset_input': '/asset/input/simple',
      'asset_allocation': '/asset/allocation',
      'asset_management': '/asset/management',
      'icon_management_asset': '/settings/icon-management-asset',

      'root_transactions': '/root/transactions',
      'root_search': '/root/search',
      'root_account_manage': '/root/accounts',
      'root_month_end': '/root/month-end',
      'screen_saver_settings': '/root/screen-saver-settings',
      'icon_management_root': '/settings/icon-management-root',

      'application_settings': '/settings/application',
      'theme_settings': '/settings/theme',
      'display_settings': '/display-settings',
      'language_settings': '/settings/language',
      'currency_settings': '/currency-settings',

      'nutrition_report': '/nutrition-report',
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
  * @param {string} [params.category]
  * @param {string} [params.supplier]
  * @param {string} [params.memo]
  * @param {string} [params.purchaseDate]
  * @param {string} [params.healthTags]
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
    if (params.category) {
      url += `&category=${encodeURIComponent(params.category)}`;
    }
    if (params.supplier) {
      url += `&supplier=${encodeURIComponent(params.supplier)}`;
    }
    if (params.memo) {
      url += `&memo=${encodeURIComponent(params.memo)}`;
    }
    if (params.purchaseDate) {
      url += `&purchaseDate=${encodeURIComponent(params.purchaseDate)}`;
    }
    if (params.healthTags) {
      url += `&healthTags=${encodeURIComponent(params.healthTags)}`;
    }
    if (params.price !== undefined && params.price !== null) {
      url += `&price=${params.price}`;
    }

    const hasExpiryDays = params.expiryDays !== undefined && params.expiryDays !== null;
    if (hasExpiryDays) {
      url += `&expiryDays=${params.expiryDays}`;
    }

    // Only attempt auto-submit when we have enough info to compute expiry date.
    const wantsAuto = params.autoSubmit === true;
    if (wantsAuto && name && hasExpiryDays) {
      url += `&autoSubmit=true`;
      if (params.confirmed === true) {
        url += `&confirmed=true`;
      }
    }

    return {
      success: true,
      deepLink: url,
      message: '식재료/생활용품 등록 화면을 엽니다'
    };
  },

  /**
   * 자산 입력(간편)
   * @param {object} params
   * @param {'cash'|'deposit'|'stock'|'other'|string} [params.category]
   * @param {string} params.name
   * @param {number} params.amount
   * @param {string} [params.location]
   * @param {string} [params.memo]
   * @param {boolean} [params.autoSubmit]
   * @param {boolean} [params.confirmed]
   */
  AddAssetSimple: function(params) {
    const name = (params.name || '').trim();
    const amount = params.amount;

    // Map category symbols to app UI labels
    const categoryRaw = (params.category || '').toString();
    const category = categoryRaw === 'deposit'
      ? '예금/적금'
      : categoryRaw === 'stock'
        ? '소액 투자'
        : categoryRaw === 'other'
          ? '기타 실물 자산'
          : categoryRaw === 'cash'
            ? '현금'
            : categoryRaw;

    let url = `smartledger://nav/open?route=${encodeURIComponent('/asset/input/simple')}&intent=asset_add`;

    if (category && category.trim().length > 0) {
      url += `&category=${encodeURIComponent(category)}`;
    }
    if (name) {
      url += `&name=${encodeURIComponent(name)}`;
    }
    if (amount !== undefined && amount !== null) {
      url += `&amount=${amount}`;
    }
    if (params.location) {
      url += `&location=${encodeURIComponent(params.location)}`;
    }
    if (params.memo) {
      url += `&memo=${encodeURIComponent(params.memo)}`;
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
      message: '자산 입력 화면을 엽니다'
    };
  },

  /**
   * 간편 지출(1줄)
   * @param {object} params
   * @param {number} params.amount
   * @param {string} [params.description]
   * @param {string} [params.payment]
   * @param {string} [params.store]
   * @param {boolean} [params.autoSubmit]
   * @param {boolean} [params.confirmed]
   */
  AddQuickSimpleExpense: function(params) {
    const amount = params.amount;
    const description = (params.description || '').trim();
    const payment = (params.payment || '').trim();
    const store = (params.store || '').trim();

    // Build a single raw line that the app parser can handle.
    const parts = [];
    if (description) parts.push(description);
    if (amount !== undefined && amount !== null) parts.push(`${amount}원`);
    if (payment) parts.push(payment);
    if (store) parts.push(store);
    const line = parts.join(' ').trim();

    let url = `smartledger://nav/open?route=${encodeURIComponent('/transaction/quick-simple-expense')}&intent=quick_expense_add`;
    if (line) {
      url += `&line=${encodeURIComponent(line)}`;
    }
    if (amount !== undefined && amount !== null) {
      url += `&amount=${amount}`;
    }
    if (description) {
      url += `&description=${encodeURIComponent(description)}`;
    }
    if (payment) {
      url += `&payment=${encodeURIComponent(payment)}`;
    }
    if (store) {
      url += `&store=${encodeURIComponent(store)}`;
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
      message: '간편 지출 입력 화면을 엽니다'
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
   * @param {boolean} [params.autoSubmit] - 앱 진입 후 자동 저장 시도 (기본 true)
   * @param {boolean} [params.confirmed] - 확인 완료 플래그
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
    const wantsAuto = params.autoSubmit !== false;
    if (wantsAuto) {
      url += `&autoSubmit=true`;
      if (params.confirmed === true) {
        url += `&confirmed=true`;
      }
    }
    
    return {
      success: true,
      deepLink: url,
      message: params.amount !== undefined && params.amount !== null
        ? `${productName} ${params.amount}${params.unit || ''} 차감 화면을 엽니다`
        : `${productName} 전량 차감 화면을 엽니다`
    };
  }
};
