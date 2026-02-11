part of 'main_feature_icon_catalog.dart';

/// Page 3 – Stats page items.
const kStatsPageItems = <MainFeatureIcon>[
  MainFeatureIcon(
    id: 'accountStats',
    label: '통계',
    labelEn: 'Stats',
    icon: IconCatalog.barChart,
    routeName: AppRoutes.accountStats,
  ),
  MainFeatureIcon(
    id: 'fixed_cost_stats',
    label: '고정비 통계',
    labelEn: 'Fixed Costs',
    icon: IconCatalog.payments,
    routeName: AppRoutes.fixedCostStats,
  ),
  MainFeatureIcon(
    id: 'period_stats_7d',
    label: '주간 리포트',
    labelEn: 'Weekly Report',
    icon: IconCatalog.calendarToday,
    routeName: AppRoutes.periodStatsWeek,
  ),
  MainFeatureIcon(
    id: 'period_stats_1m',
    label: '월간 리포트',
    labelEn: 'Monthly Report',
    icon: IconCatalog.calendarViewMonth,
    routeName: AppRoutes.periodStatsMonth,
  ),
  MainFeatureIcon(
    id: 'period_stats_3m',
    label: '분기 리포트',
    labelEn: 'Quarterly Report',
    icon: IconCatalog.timeline,
    routeName: AppRoutes.periodStatsQuarter,
  ),
  MainFeatureIcon(
    id: 'period_stats_6m',
    label: '반기 리포트',
    labelEn: 'Half-year Report',
    icon: IconCatalog.calendarViewMonth,
    routeName: AppRoutes.periodStatsHalfYear,
  ),
  MainFeatureIcon(
    id: 'period_stats_1y',
    label: '연간 리포트',
    labelEn: 'Annual Report',
    icon: IconCatalog.dateRange,
    routeName: AppRoutes.periodStatsYear,
  ),
  MainFeatureIcon(
    id: 'period_stats_10y',
    label: '10년',
    labelEn: '10 Years',
    icon: IconCatalog.autoGraph,
    routeName: AppRoutes.periodStatsDecade,
  ),
  MainFeatureIcon(
    id: 'accountStatsSearch',
    label: '검색',
    labelEn: 'Search',
    icon: IconCatalog.search,
    routeName: AppRoutes.accountStatsSearch,
  ),
  MainFeatureIcon(
    id: 'shopping_cheapest_month',
    label: '최저가 달',
    labelEn: 'Cheapest Month',
    icon: IconCatalog.insightsOutlined,
    routeName: AppRoutes.shoppingCheapestMonth,
  ),
  MainFeatureIcon(
    id: 'card_discount_stats',
    label: '카드 할인',
    labelEn: 'Card Discounts',
    icon: IconCatalog.creditCard,
    routeName: AppRoutes.cardDiscountStats,
  ),
  MainFeatureIcon(
    id: 'points_motivation_stats',
    label: '포인트',
    labelEn: 'Points',
    icon: IconCatalog.localOffer,
    routeName: AppRoutes.pointsMotivationStats,
  ),
  MainFeatureIcon(
    id: 'spending_analysis',
    label: '지출 분석 & 절약 팁',
    labelEn: 'Spending Analysis',
    icon: Icons.analytics,
    routeName: AppRoutes.spendingAnalysis,
  ),
  MainFeatureIcon(
    id: 'weather_price_prediction',
    label: '날씨 기반 가격 예측',
    labelEn: 'Weather Price Prediction',
    icon: Icons.wb_cloudy,
    routeName: AppRoutes.weatherPricePrediction,
  ),
];

/// Page 4 – Asset page items.
const kAssetPageItems = <MainFeatureIcon>[
  MainFeatureIcon(
    id: 'asset_dashboard',
    label: '자산 대시보드',
    labelEn: 'Asset Dashboard',
    icon: IconCatalog.dashboard,
    routeName: AppRoutes.assetDashboard,
  ),
  MainFeatureIcon(
    id: 'asset_input',
    label: '자산 입력',
    labelEn: 'Add Asset',
    icon: IconCatalog.addBusiness,
    routeName: AppRoutes.assetSimpleInput,
  ),
  MainFeatureIcon(
    id: 'asset_input_detailed',
    label: '자산 입력(상세)',
    labelEn: 'Add Asset(Detailed)',
    icon: IconCatalog.postAdd,
    routeName: AppRoutes.assetDetailInput,
  ),
  MainFeatureIcon(
    id: 'asset_trending_up',
    label: '상승 자산',
    labelEn: 'Allocation',
    icon: IconCatalog.trendingUp,
    routeName: AppRoutes.assetAllocation,
  ),
  MainFeatureIcon(
    id: 'asset_assessment',
    label: '자산 평가',
    labelEn: 'Assessment',
    icon: IconCatalog.assessment,
    routeName: AppRoutes.assetManagement,
  ),
  MainFeatureIcon(
    id: 'asset_tab_entry',
    label: '자산 관리(가계부)',
    labelEn: 'Asset Ledger',
    icon: IconCatalog.accountBalanceWallet,
    routeName: AppRoutes.assetTab,
  ),
  MainFeatureIcon(
    id: 'icon_management_asset_entry',
    label: '아이콘 관리',
    labelEn: 'Icon Manager',
    icon: IconCatalog.gridView,
    routeName: AppRoutes.iconManagementAsset,
  ),
];

/// Page 5 – Root page items.
const kRootPageItems = <MainFeatureIcon>[
  MainFeatureIcon(
    id: 'root_transactions',
    label: '전체 거래',
    labelEn: 'All Transactions',
    icon: IconCatalog.list,
    routeName: AppRoutes.rootTransactions,
  ),
  MainFeatureIcon(
    id: 'root_search',
    label: '검색',
    labelEn: 'Search',
    icon: IconCatalog.search,
    routeName: AppRoutes.rootSearch,
  ),
  MainFeatureIcon(
    id: 'root_account_manage',
    label: '계정 관리',
    labelEn: 'Account Manager',
    icon: IconCatalog.accountBalanceWallet,
    routeName: AppRoutes.rootAccountManage,
  ),
  MainFeatureIcon(
    id: 'root_month_end',
    label: '월말 정산',
    labelEn: 'Month-end Close',
    icon: IconCatalog.eventAvailable,
    routeName: AppRoutes.rootMonthEnd,
  ),
  MainFeatureIcon(
    id: 'root_ceo_assistant',
    label: 'CEO 비서 대시보드',
    labelEn: 'CEO Assistant',
    icon: IconCatalog.insightsOutlined,
    routeName: AppRoutes.ceoAssistant,
  ),
  MainFeatureIcon(
    id: 'root_screen_saver_settings',
    label: '보호기 설정',
    labelEn: 'Screen Protection',
    icon: IconCatalog.shieldOutlined,
    routeName: AppRoutes.rootScreenSaverSettings,
  ),
  MainFeatureIcon(
    id: 'icon_management_root_entry',
    label: '아이콘 관리',
    labelEn: 'Icon Manager',
    icon: IconCatalog.gridView,
    routeName: AppRoutes.iconManagementRoot,
  ),
];
