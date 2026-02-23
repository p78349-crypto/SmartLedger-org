import '../navigation/app_routes.dart';
import 'icon_catalog.dart';
import 'main_feature_icon_models.dart';

/// Page 1 – Purchase & expense related icons.
const List<MainFeatureIcon> kPurchasePageItems = [
  MainFeatureIcon(
    id: 'transactionAdd',
    label: '거래 입력',
    labelEn: 'Add Transaction',
    icon: IconCatalog.payments,
    routeName: AppRoutes.transactionAdd,
  ),
  MainFeatureIcon(
    id: 'quick_simple_expense_input',
    label: '간편 지출(1줄)',
    labelEn: 'Quick Expense (1-line)',
    icon: IconCatalog.quickreplyOutlined,
    routeName: AppRoutes.quickSimpleExpenseInput,
  ),
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
    id: 'nutrition_report',
    label: '요리 레시피/식재료 검색',
    labelEn: 'Recipe/Ingredient Search',
    icon: IconCatalog.articleOutlined,
    routeName: AppRoutes.nutritionReport,
  ),
  MainFeatureIcon(
    id: 'weather_price_prediction',
    label: '날씨 기반 가격 예측',
    labelEn: 'Weather Price Prediction',
    icon: IconCatalog.weatherPricePrediction,
    routeName: AppRoutes.weatherPricePrediction,
  ),
  MainFeatureIcon(
    id: 'shopping_cart',
    label: '장바구니',
    labelEn: 'Cart',
    icon: IconCatalog.shoppingCart,
    routeName: AppRoutes.shoppingCart,
  ),
  MainFeatureIcon(
    id: 'shopping_points_input',
    label: '포인트 입력',
    labelEn: 'Points Input',
    icon: IconCatalog.localOffer,
    routeName: AppRoutes.shoppingPointsInput,
  ),
  MainFeatureIcon(
    id: 'daily_transactions',
    label: '오늘의 지출',
    labelEn: 'Today',
    icon: IconCatalog.calendarToday,
    routeName: AppRoutes.dailyTransactions,
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
    id: 'consumable_inventory',
    label: 'WMS 재고관리',
    labelEn: 'WMS Inventory',
    icon: IconCatalog.inventory,
    routeName: AppRoutes.consumableInventory,
  ),
  MainFeatureIcon(
    id: 'wms_io',
    label: 'WMS 입출고',
    labelEn: 'WMS In/Out',
    icon: IconCatalog.swapVert,
    routeName: AppRoutes.wmsIo,
  ),
  MainFeatureIcon(
    id: 'quick_stock_use',
    label: '사용량 기록',
    labelEn: 'Usage Log',
    icon: IconCatalog.bolt,
    routeName: AppRoutes.quickStockUse,
  ),
  MainFeatureIcon(
    id: 'wms_guide',
    label: 'WMS 도움말',
    labelEn: 'WMS Guide',
    icon: IconCatalog.helpOutline,
    routeName: AppRoutes.wmsGuide,
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
const List<MainFeatureIcon> kIncomePageItems = [
  MainFeatureIcon(
    id: 'income_add',
    label: '수입 입력',
    labelEn: 'Add Income',
    icon: IconCatalog.addCircle,
    routeName: AppRoutes.transactionAddIncome,
  ),
  MainFeatureIcon(
    id: 'income_detail',
    label: '수입 상세',
    labelEn: 'Income Detail',
    icon: IconCatalog.receiptLongOutlined,
    routeName: AppRoutes.transactionDetailIncome,
  ),
  MainFeatureIcon(
    id: 'income_split',
    label: '수입배분',
    labelEn: 'Income Split',
    icon: IconCatalog.compareArrows,
    routeName: AppRoutes.incomeSplit,
  ),
  MainFeatureIcon(
    id: 'refund_menu',
    label: '반품',
    labelEn: 'Refunds',
    icon: IconCatalog.refund,
    routeName: AppRoutes.refundTransactions,
  ),
  MainFeatureIcon(
    id: 'asset_project_100m',
    label: '1억 프로젝트',
    labelEn: '100M Project',
    icon: IconCatalog.emojiEvents,
    routeName: AppRoutes.assetProject100m,
  ),
];
