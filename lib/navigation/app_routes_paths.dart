// Central route names.
//
// Keeping route names in one place prevents UI entrypoints from breaking
// when individual screens get moved/renamed.

class AppRoutes {
  const AppRoutes._();

  static const topLevelMain = '/';
  static const topLevelStatsDetail = '/top-level/stats-detail';

  static const accountMain = '/account/main';
  static const accountCreate = '/account/create';
  static const accountSelect = '/account/select';

  static const transactionAdd = '/transaction/add';
  static const transactionAddIncome = '/transaction/add-income';
  static const transactionDetail = '/transaction/detail';
  static const transactionDetailIncome = '/transaction/detail-income';
  static const dailyTransactions = '/transaction/daily';

  static const refundTransactions = '/transaction/refund';

  static const quickSimpleExpenseInput = '/transaction/quick-simple-expense';
  static const transactionAddDetailed = '/transaction/add-detailed';

  static const monthEndCarryover = '/month-end/carryover';

  static const emergencyFund = '/emergency-fund';
  static const emergencyServices = '/emergency-services';
  static const trash = '/trash';
  static const backup = '/backup';
  static const settings = '/settings';
  static const applicationSettings = '/settings/application';
  static const iconManagement = '/settings/icon-management';
  static const iconManagement2 = '/settings/icon-management-2';
  static const iconManagementAsset = '/settings/icon-management-asset';
  static const iconManagementRoot = '/settings/icon-management-root';
  static const featureIconsCatalog = '/settings/feature-icons-catalog';
  static const themeSettings = '/settings/theme';
  static const languageSettings = '/settings/language';
  static const backgroundSettings = '/settings/background';
  static const displaySettings = '/display-settings';
  static const currencySettings = '/currency-settings';
  static const voiceShortcuts = '/settings/voice-shortcuts';
  static const voiceDashboard = '/voice/dashboard';
  static const voiceAssistantSettings = '/settings/voice-assistant';
  static const page1BottomIconSettings = '/page1/bottom-icons';
  static const privacyPolicy = '/privacy-policy';
  static const fileViewer = '/file-viewer';
  static const nutritionReport = '/nutrition-report';
  static const ingredientSearch = '/ingredient-search';

  static const accountStats = '/stats/monthly';
  static const accountStatsDecade = '/stats/decade';
  static const accountStatsSearch = '/stats/search';

  // Clean period stats (list-based) entrypoints.
  static const periodStatsWeek = '/stats/period/week';
  static const periodStatsMonth = '/stats/period/month';
  static const periodStatsQuarter = '/stats/period/quarter';
  static const periodStatsHalfYear = '/stats/period/half-year';
  static const periodStatsYear = '/stats/period/year';
  static const periodStatsDecade = '/stats/period/decade';
  static const monthlyStats = '/stats/monthly-simple';
  static const categoryStats = '/stats/category';
  static const cardDiscountStats = '/stats/card-discount';
  static const pointsMotivationStats = '/stats/points-motivation';
  static const spendingAnalysis = '/stats/spending-analysis';
  static const weatherPricePrediction = '/stats/weather-price-prediction';
  static const weatherManualInput = '/weather/manual-input';
  static const microSavings = '/nudges/micro-savings';
  static const incomeSplit = '/income/split';
  static const foodExpiry = '/food/expiry';
  static const foodCookingStart = '/food/cooking-start';
  static const healthAnalyzer = '/food/health-analyzer';
  static const calendar = '/calendar';

  static const shoppingCart = '/shopping/cart';
  static const shoppingPrep = '/shopping/prep';
  static const shoppingGuide = '/shopping/guide';

  static const householdConsumables = '/household/consumables';
  static const consumableInventory = '/household/inventory';
  static const quickStockUse = '/household/quick-stock-use';

  static const shoppingPointsInput = '/shopping/points-input';

  static const shoppingCheapestMonth = '/stats/shopping/cheapest-month';

  static const storeMerge = '/stats/input/store-merge';

  static const assetTab = '/asset/tab';
  static const assetDashboard = '/asset/dashboard';
  static const assetAllocation = '/asset/allocation';
  static const assetManagement = '/asset/management';
  static const assetSimpleInput = '/asset/input/simple';
  static const assetDetailInput = '/asset/input/detail';
  static const assetProject100m = '/asset/project-100m';

  static const fixedCostTab = '/fixed-cost/tab';
  static const fixedCostStats = '/fixed-cost/stats';

  static const savingsPlanList = '/savings/plan/list';

  static const rootTransactions = '/root/transactions';
  static const rootSearch = '/root/search';
  static const rootAccountManage = '/root/accounts';
  static const rootMonthEnd = '/root/month-end';

  static const rootScreenSaverSettings = '/root/screen-saver-settings';
  static const rootScreenSaverExposureSettings =
      '/root/screen-saver-exposure-settings';

  // CEO assistant routes
  static const ceoAssistant = '/root/ceo/assistant';
  static const ceoExceptionDetails = '/root/ceo/exception-details';
  static const ceoRecoveryPlan = '/root/ceo/recovery-plan';
  static const ceoRoiDetail = '/root/ceo/roi-detail';
  static const ceoMonthlyDefenseReport = '/root/ceo/monthly-defense-report';
}
