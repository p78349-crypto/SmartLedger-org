// Central route names and strongly-typed arguments.
//
// Keeping route names in one place prevents UI entrypoints from breaking
// when individual screens get moved/renamed.
import 'package:smart_ledger/models/category_hint.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/utils/top_level_stats_utils.dart';

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
  static const trash = '/trash';
  static const backup = '/backup';
  static const settings = '/settings';
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
  static const microSavings = '/nudges/micro-savings';
  static const incomeSplit = '/income/split';
  static const foodExpiry = '/food/expiry';
  static const foodInventoryCheck = '/food/inventory-check';
  static const foodCookingStart = '/food/cooking-start';
  static const calendar = '/calendar';

  static const shoppingCart = '/shopping/cart';
  static const shoppingPrep = '/shopping/prep';

  static const shoppingCartQuickTransaction =
      '/shopping/cart/quick-transaction';

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
}

class AccountArgs {
  const AccountArgs({required this.accountName, this.initialIncomeAmount});
  final String accountName;
  final double? initialIncomeAmount;
}

class AccountMainArgs {
  const AccountMainArgs({required this.accountName, this.initialIndex = 0});
  final String accountName;
  final int initialIndex;
}

class IconManagementArgs {
  const IconManagementArgs({required this.accountName});
  final String accountName;
}

class AccountSelectArgs {
  const AccountSelectArgs({required this.accounts});
  final List<String> accounts;
}

class TransactionAddArgs {
  const TransactionAddArgs({
    required this.accountName,
    this.initialTransaction,
    this.learnCategoryHintFromDescription = false,
    this.confirmBeforeSave = false,
    this.treatAsNew = false,
  });
  final String accountName;
  final Object? initialTransaction;
  final bool learnCategoryHintFromDescription;
  final bool confirmBeforeSave;
  final bool treatAsNew;
}

class TransactionDetailArgs {
  const TransactionDetailArgs({
    required this.accountName,
    required this.initialType,
  });
  final String accountName;
  final Object initialType;
}

class DailyTransactionsArgs {
  const DailyTransactionsArgs({
    required this.accountName,
    required this.initialDay,
    this.savedCount,
    this.showShoppingPointsInputCta = false,
  });
  final String accountName;
  final DateTime initialDay;

  /// Optional. When provided, Daily screen shows a one-time snackbar.
  final int? savedCount;

  /// When true, Daily screen shows a non-modal CTA to open Points input.
  final bool showShoppingPointsInputCta;
}

class QuickSimpleExpenseInputArgs {
  const QuickSimpleExpenseInputArgs({
    required this.accountName,
    required this.initialDate,
  });

  final String accountName;
  final DateTime initialDate;
}

class ShoppingCartArgs {
  const ShoppingCartArgs({
    required this.accountName,
    this.openPrepOnStart = false,
    this.initialItems,
  });
  final String accountName;
  final bool openPrepOnStart;
  final List<ShoppingCartItem>? initialItems;
}

class ShoppingCartQuickTransactionArgs {
  const ShoppingCartQuickTransactionArgs({
    required this.accountName,
    required this.title,
    required this.description,
    required this.total,
    this.quantity = 1,
    this.unitPrice,
    this.itemCount,
    this.previewLines,
    this.initialMainCategory,
    this.initialSubCategory,
    this.bulkRemainingItems,
    this.bulkIndex,
    this.bulkTotalCount,
    this.bulkCategoryHints,
    this.bulkGrandTotal,
    this.bulkPreviewLines,
    this.martStore,
    this.martPayment,
    this.martDate,
  });

  final String accountName;
  final String title;
  final String description;
  final double total;
  final int quantity;

  /// Optional. Used when showing single-item detail.
  final double? unitPrice;

  /// Optional. Used when showing bulk summary.
  final int? itemCount;

  /// Optional. Preformatted list of item lines shown in confirm dialog.
  final List<String>? previewLines;

  /// Optional. When not provided, the screen will auto-suggest.
  final String? initialMainCategory;
  final String? initialSubCategory;

  /// Optional. When provided, enables bulk UX ("나머지 모두 저장").
  /// This list should contain the *current* item first.
  final List<ShoppingCartItem>? bulkRemainingItems;

  /// Optional. 0-based index of the current item in the original selection.
  final int? bulkIndex;

  /// Optional. Total count of originally selected items.
  final int? bulkTotalCount;

  /// Optional. Category hints used for auto-suggestion in bulk mode.
  final Map<String, CategoryHint>? bulkCategoryHints;

  /// Optional. Total sum of ALL selected items in bulk mode.
  /// Used for receipt-total review and adjustment transaction.
  final double? bulkGrandTotal;

  /// Optional. Preformatted list of item lines for bulk review.
  final List<String>? bulkPreviewLines;

  /// Optional. Pre-filled store for mart shopping mode.
  final String? martStore;

  /// Optional. Pre-filled payment for mart shopping mode.
  final String? martPayment;

  /// Optional. Pre-filled date for mart shopping mode.
  final DateTime? martDate;
}

class ShoppingCartQuickTransactionSaveRestResult {
  const ShoppingCartQuickTransactionSaveRestResult({
    required this.savedItemIds,
  });

  final List<String> savedItemIds;
}

class TopLevelStatsDetailArgs {
  const TopLevelStatsDetailArgs({required this.dashboard});
  final RootDashboardContext dashboard;
}
