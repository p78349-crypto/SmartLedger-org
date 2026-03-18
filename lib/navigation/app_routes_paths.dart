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
  static const subscriptionManage = '/settings/subscription-manage';
  static const serverSyncSettings = '/settings/server-sync';
  static const applicationSettings = '/settings/application';
  static const databaseEncryption = '/settings/internal/database-encryption';
  static const securitySettings = '/settings/security';
  static const iconManagement = '/settings/icon-management';
  static const iconManagement2 = '/settings/icon-management-2';
  static const iconManagementAsset = '/settings/icon-management-asset';
  static const iconManagementRoot = '/settings/icon-management-root';
  static const iconManagementSettings = '/settings/icon-management-settings';
  static const pageIconManagement = '/page/icon-management';
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
  static const rewardSystemStats = '/stats/reward-system';
  static const spendingAnalysis = '/stats/spending-analysis';
  static const weatherPricePrediction = '/stats/weather-price-prediction';
  static const weatherManualInput = '/weather/manual-input';
  static const microSavings = '/nudges/micro-savings';
  static const incomeSplit = '/income/split';
  static const incomeSplitStatus = '/income/split-status';
  static const foodExpiry = '/food/expiry';
  static const foodCookingStart = '/food/cooking-start';
  static const healthAnalyzer = '/food/health-analyzer';
  static const calendar = '/calendar';

  static const shoppingCart = '/shopping/cart';
  static const shoppingGuide = '/shopping/guide';

  static const householdConsumables = '/household/consumables';
  static const householdQuickPick = '/household/quick-pick';
  static const householdItems = '/household/items';
  static const consumableInventory = '/household/inventory';
  static const quickStockUse = '/household/quick-stock-use';
  static const wmsIo = '/household/wms-io';
  static const wmsGuide = '/household/wms-guide';

  static const shoppingPointsInput = '/shopping/points-input';

  // 레시피 관리
  static const recipeManagement = '/recipe/management';
  static const recipeEdit = '/recipe/edit';
  static const recipeToCart = '/recipe/to-cart';

  static const shoppingCheapestMonth = '/stats/shopping/cheapest-month';

  static const storeMerge = '/stats/input/store-merge';

  static const assetTab = '/asset/tab';
  static const assetDashboard = '/asset/dashboard';
  static const assetAllocation = '/asset/allocation';
  static const assetPortfolioAnalysis = '/asset/portfolio-analysis';
  static const assetInvestmentRoadmap = '/asset/investment-roadmap';
  static const assetManagement = '/asset/management';
  static const assetList = '/asset/list';
  static const assetExport = '/asset/export';
  static const dataFlexibleExport = '/data/flexible-export';
  static const assetSimpleInput = '/asset/input/simple';
  static const assetDetailInput = '/asset/input/detail';
  static const assetProject100m = '/asset/project-100m';
  static const assetSecuritySettings = '/asset/security-settings';

  static const fixedCostTab = '/fixed-cost/tab';
  static const fixedCostStats = '/fixed-cost/stats';

  static const savingsPlanList = '/savings/plan/list';

  static const rootSummary = '/root/summary';
  static const rootAccountSummary = '/root/account-summary';
  static const rootExpenseAnalysis = '/root/expense-analysis';
  static const rootTransactions = '/root/transactions';
  static const rootSearch = '/root/search';
  static const rootAccountManage = '/root/accounts';
  static const rootMonthEnd = '/root/month-end';
  static const rootSecuritySetup = '/root/security-setup';

  // CEO assistant routes
  static const ceoAssistant = '/root/ceo/assistant';
  static const ceoExceptionDetails = '/root/ceo/exception-details';
  static const ceoRecoveryPlan = '/root/ceo/recovery-plan';
  static const ceoRoiDetail = '/root/ceo/roi-detail';
  static const ceoMonthlyDefenseReport = '/root/ceo/monthly-defense-report';

  // Gemma API test
  static const gemmaApiTest = '/dev/gemma-api-test';

  // Gemini Nano voice input
  static const geminiVoiceInput = '/transaction/gemini-voice-input';

  // Smart voice command (앱 통합 제어)
  static const smartVoiceCommand = '/smart/voice-command';

  // 새로 구현된 고급 기능들
  static const incrementalBackup = '/backup/incremental';
  static const ceoPredictionDashboard = '/ceo/prediction-dashboard';
  static const aiInvestmentAdvisor = '/investment/ai-advisor';
  static const cloudBackupSettings = '/backup/cloud-settings';
  static const advancedFinancialAnalytics = '/analytics/advanced-financial';
  static const aiModelSelector = '/ai/model-selector';
  static const customGemma2Test = '/dev/custom-gemma2-test'; // 🔬 커스텀 모델 테스트

  // Help center routes
  static const helpCenter = '/help/center';
  static const helpQuickStart = '/help/quick-start';
  static const helpUserManual = '/help/user-manual';
  static const helpTransactions = '/help/transactions';
  static const helpStatistics = '/help/statistics';
  static const helpAssets = '/help/assets';
  static const helpShopping = '/help/shopping';
  static const helpInventory = '/help/inventory';
  static const helpBackup = '/help/backup';
  static const helpFaq = '/help/faq';
  static const helpTips = '/help/tips';
  static const helpChangelog = '/help/changelog';
  // ⭐ 핵심 워크플로우
  static const helpRecipeWorkflow = '/help/recipe-workflow';
}
