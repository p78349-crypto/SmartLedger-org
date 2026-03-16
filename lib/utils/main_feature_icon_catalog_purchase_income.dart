import '../navigation/app_routes.dart';
import 'icon_catalog.dart';
import 'main_feature_icon_models.dart';

/// Page 1 – Purchase & expense related icons.
/// 순서: 사진 기준 기본 배치 (2026-02-24)
const List<MainFeatureIcon> kPurchasePageItems = [
  // 기본 배치 (사진 순서)
  MainFeatureIcon(
    id: 'quick_simple_expense_input',
    label: '간편 지출(1줄)',
    labelEn: 'Quick Expense (1-line)',
    icon: IconCatalog.quickreplyOutlined,
    routeName: AppRoutes.quickSimpleExpenseInput,
  ),
  MainFeatureIcon(
    id: 'nutrition_report',
    label: '요리 레시피/식재료 검색',
    labelEn: 'Recipe/Ingredient Search',
    icon: IconCatalog.articleOutlined,
    routeName: AppRoutes.nutritionReport,
  ),
  MainFeatureIcon(
    id: 'shopping_cart',
    label: '장바구니',
    labelEn: 'Cart',
    icon: IconCatalog.shoppingCart,
    routeName: AppRoutes.shoppingCart,
  ),
  MainFeatureIcon(
    id: 'transactionAdd',
    label: '거래 입력',
    labelEn: 'Add Transaction',
    icon: IconCatalog.payments,
    routeName: AppRoutes.transactionAdd,
  ),
  MainFeatureIcon(
    id: 'daily_transactions',
    label: '오늘의 지출',
    labelEn: 'Today',
    icon: IconCatalog.calendarToday,
    routeName: AppRoutes.dailyTransactions,
  ),
  MainFeatureIcon(
    id: 'wms_io',
    label: 'WMS 입출고',
    labelEn: 'WMS In/Out',
    icon: IconCatalog.swapVert,
    routeName: AppRoutes.wmsIo,
  ),
  MainFeatureIcon(
    id: 'consumable_inventory',
    label: 'WMS 재고관리',
    labelEn: 'WMS Inventory',
    icon: IconCatalog.inventory,
    routeName: AppRoutes.consumableInventory,
  ),
  MainFeatureIcon(
    id: 'wms_guide',
    label: 'WMS 도움말',
    labelEn: 'WMS Guide',
    icon: IconCatalog.helpOutline,
    routeName: AppRoutes.wmsGuide,
  ),
  // 추가 아이콘 (전체아이콘 탭용)
  MainFeatureIcon(
    id: 'health_analyzer',
    label: '재료 건강도 분석',
    labelEn: 'Health Analyzer',
    icon: IconCatalog.favorite,
    routeName: AppRoutes.healthAnalyzer,
  ),
  MainFeatureIcon(
    id: 'micro_savings',
    label: '자산 가속(푼돈 모으기)',
    labelEn: 'Micro Savings',
    icon: IconCatalog.microSavings,
    routeName: AppRoutes.microSavings,
  ),
  MainFeatureIcon(
    id: 'weather_price_prediction',
    label: '날씨 기반 가격 예측',
    labelEn: 'Weather Price Prediction',
    icon: IconCatalog.weatherPricePrediction,
    routeName: AppRoutes.weatherPricePrediction,
  ),
  MainFeatureIcon(
    id: 'shopping_points_input',
    label: '포인트 입력',
    labelEn: 'Points Input',
    icon: IconCatalog.localOffer,
    routeName: AppRoutes.shoppingPointsInput,
  ),
  MainFeatureIcon(
    id: 'household_consumables',
    label: '소모품 입력',
    labelEn: 'Consumables',
    icon: IconCatalog.cleaningServices,
    routeName: AppRoutes.householdConsumables,
  ),
  MainFeatureIcon(
    id: 'household_quick_pick',
    label: '식료품/생활용품 퀵픽',
    labelEn: 'Quick Pick',
    icon: IconCatalog.playlistAddCheckCircle,
    routeName: AppRoutes.householdQuickPick,
  ),
  MainFeatureIcon(
    id: 'quick_stock_use',
    label: '사용량 기록',
    labelEn: 'Usage Log',
    icon: IconCatalog.bolt,
    routeName: AppRoutes.quickStockUse,
  ),
  MainFeatureIcon(
    id: 'transaction_add_detailed',
    label: '지출입력(상세)',
    labelEn: 'Add Detailed',
    icon: IconCatalog.postAdd,
    routeName: AppRoutes.transactionAddDetailed,
  ),
];

/// Page 2 – Income related icons.
const Set<String> kIncomePageIconIdsLegacy = {
  'income_add',
  'income_detail',
  'income_split',
  'refund_menu',
  'asset_project_100m',
};

const List<MainFeatureIcon> kIncomePageItems = [
  MainFeatureIcon(
    id: 'income_add',
    label: '수입 입력',
    labelEn: 'Add Income',
    icon: IconCatalog.trendingUp,
    routeName: AppRoutes.transactionAddIncome,
  ),
  MainFeatureIcon(
    id: 'income_detail',
    label: '수입 내역',
    labelEn: 'Income List',
    icon: IconCatalog.list,
    routeName: AppRoutes.transactionDetailIncome,
  ),
  MainFeatureIcon(
    id: 'refund_menu',
    label: '환불/반품',
    labelEn: 'Refunds',
    icon: IconCatalog.refund,
    routeName: AppRoutes.refundTransactions,
  ),
  MainFeatureIcon(
    id: 'income_split',
    label: '수입 분배',
    labelEn: 'Income Split',
    icon: IconCatalog.compareArrows,
    routeName: AppRoutes.incomeSplit,
  ),
  MainFeatureIcon(
    id: 'income_split_status',
    label: '분배 현황',
    labelEn: 'Split Status',
    icon: IconCatalog.assessment,
    routeName: AppRoutes.incomeSplitStatus,
  ),
];
