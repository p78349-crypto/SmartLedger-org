import 'package:flutter/foundation.dart';

import '../models/transaction.dart';
import '../services/account_service.dart';
import 'app_routes.dart';

@immutable
class AssistantRouteSpec {
  final String routeName;

  /// If true, route requires an accountName-derived args.
  final bool requiresAccount;

  /// Build RouteSettings.arguments for this route.
  ///
  /// Return null only when the route truly requires no args.
  final Object? Function(String? accountName) buildArgs;

  const AssistantRouteSpec({
    required this.routeName,
    required this.requiresAccount,
    required this.buildArgs,
  });
}

class AssistantRouteCatalog {
  AssistantRouteCatalog._();

  static String? resolveDefaultAccountName() {
    final accounts = AccountService().accounts;
    if (accounts.isEmpty) return null;
    return accounts.first.name;
  }

  /// Whitelist of routes that can be opened via assistant deep links.
  ///
  /// Keep this list explicit to avoid opening unintended internal screens.
  static final Map<String, AssistantRouteSpec> specs = {
    // Top-level / general
    AppRoutes.topLevelMain: AssistantRouteSpec(
      routeName: AppRoutes.topLevelMain,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.settings: AssistantRouteSpec(
      routeName: AppRoutes.settings,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.applicationSettings: AssistantRouteSpec(
      routeName: AppRoutes.applicationSettings,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.themeSettings: AssistantRouteSpec(
      routeName: AppRoutes.themeSettings,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.displaySettings: AssistantRouteSpec(
      routeName: AppRoutes.displaySettings,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.languageSettings: AssistantRouteSpec(
      routeName: AppRoutes.languageSettings,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.privacyPolicy: AssistantRouteSpec(
      routeName: AppRoutes.privacyPolicy,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.trash: AssistantRouteSpec(
      routeName: AppRoutes.trash,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.voiceShortcuts: AssistantRouteSpec(
      routeName: AppRoutes.voiceShortcuts,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.voiceDashboard: AssistantRouteSpec(
      routeName: AppRoutes.voiceDashboard,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),

    // Quick input / detail
    AppRoutes.quickSimpleExpenseInput: AssistantRouteSpec(
      routeName: AppRoutes.quickSimpleExpenseInput,
      requiresAccount: true,
      buildArgs: (accountName) => QuickSimpleExpenseInputArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
        initialDate: DateTime.now(),
      ),
    ),
    AppRoutes.transactionDetail: AssistantRouteSpec(
      routeName: AppRoutes.transactionDetail,
      requiresAccount: true,
      buildArgs: (accountName) => TransactionDetailArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
        initialType: TransactionType.expense,
      ),
    ),
    AppRoutes.transactionDetailIncome: AssistantRouteSpec(
      routeName: AppRoutes.transactionDetailIncome,
      requiresAccount: true,
      buildArgs: (accountName) => TransactionDetailArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
        initialType: TransactionType.income,
      ),
    ),

    // Account / ledger
    AppRoutes.accountMain: AssistantRouteSpec(
      routeName: AppRoutes.accountMain,
      requiresAccount: true,
      buildArgs: (accountName) => AccountMainArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.transactionAdd: AssistantRouteSpec(
      routeName: AppRoutes.transactionAdd,
      requiresAccount: true,
      buildArgs: (accountName) => TransactionAddArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
        treatAsNew: true,
        closeAfterSave: true,
      ),
    ),
    AppRoutes.transactionAddIncome: AssistantRouteSpec(
      routeName: AppRoutes.transactionAddIncome,
      requiresAccount: true,
      buildArgs: (accountName) => TransactionAddArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
        treatAsNew: true,
        closeAfterSave: true,
      ),
    ),
    AppRoutes.transactionAddDetailed: AssistantRouteSpec(
      routeName: AppRoutes.transactionAddDetailed,
      requiresAccount: true,
      buildArgs: (accountName) => TransactionAddArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
        treatAsNew: true,
        closeAfterSave: true,
      ),
    ),
    AppRoutes.dailyTransactions: AssistantRouteSpec(
      routeName: AppRoutes.dailyTransactions,
      requiresAccount: true,
      buildArgs: (accountName) => DailyTransactionsArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
        initialDay: DateTime.now(),
      ),
    ),
    AppRoutes.refundTransactions: AssistantRouteSpec(
      routeName: AppRoutes.refundTransactions,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.backup: AssistantRouteSpec(
      routeName: AppRoutes.backup,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.monthEndCarryover: AssistantRouteSpec(
      routeName: AppRoutes.monthEndCarryover,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),

    AppRoutes.incomeSplit: AssistantRouteSpec(
      routeName: AppRoutes.incomeSplit,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),

    AppRoutes.emergencyFund: AssistantRouteSpec(
      routeName: AppRoutes.emergencyFund,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),

    // Stats
    AppRoutes.accountStats: AssistantRouteSpec(
      routeName: AppRoutes.accountStats,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.accountStatsDecade: AssistantRouteSpec(
      routeName: AppRoutes.accountStatsDecade,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.accountStatsSearch: AssistantRouteSpec(
      routeName: AppRoutes.accountStatsSearch,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.categoryStats: AssistantRouteSpec(
      routeName: AppRoutes.categoryStats,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),

    AppRoutes.periodStatsWeek: AssistantRouteSpec(
      routeName: AppRoutes.periodStatsWeek,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.periodStatsMonth: AssistantRouteSpec(
      routeName: AppRoutes.periodStatsMonth,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.periodStatsQuarter: AssistantRouteSpec(
      routeName: AppRoutes.periodStatsQuarter,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.periodStatsHalfYear: AssistantRouteSpec(
      routeName: AppRoutes.periodStatsHalfYear,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.periodStatsYear: AssistantRouteSpec(
      routeName: AppRoutes.periodStatsYear,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.periodStatsDecade: AssistantRouteSpec(
      routeName: AppRoutes.periodStatsDecade,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),

    AppRoutes.shoppingCheapestMonth: AssistantRouteSpec(
      routeName: AppRoutes.shoppingCheapestMonth,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.weatherPricePrediction: AssistantRouteSpec(
      routeName: AppRoutes.weatherPricePrediction,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.monthlyStats: AssistantRouteSpec(
      routeName: AppRoutes.monthlyStats,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.spendingAnalysis: AssistantRouteSpec(
      routeName: AppRoutes.spendingAnalysis,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.cardDiscountStats: AssistantRouteSpec(
      routeName: AppRoutes.cardDiscountStats,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.pointsMotivationStats: AssistantRouteSpec(
      routeName: AppRoutes.pointsMotivationStats,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),

    AppRoutes.fixedCostStats: AssistantRouteSpec(
      routeName: AppRoutes.fixedCostStats,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),

    // Food / shopping / household
    AppRoutes.foodExpiry: AssistantRouteSpec(
      routeName: AppRoutes.foodExpiry,
      requiresAccount: true,
      buildArgs: (accountName) => const FoodExpiryArgs(),
    ),
    AppRoutes.foodCookingStart: AssistantRouteSpec(
      routeName: AppRoutes.foodCookingStart,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.nutritionReport: AssistantRouteSpec(
      routeName: AppRoutes.nutritionReport,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.weatherManualInput: AssistantRouteSpec(
      routeName: AppRoutes.weatherManualInput,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.ingredientSearch: AssistantRouteSpec(
      routeName: AppRoutes.ingredientSearch,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.microSavings: AssistantRouteSpec(
      routeName: AppRoutes.microSavings,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.savingsPlanList: AssistantRouteSpec(
      routeName: AppRoutes.savingsPlanList,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.shoppingCart: AssistantRouteSpec(
      routeName: AppRoutes.shoppingCart,
      requiresAccount: true,
      buildArgs: (accountName) => ShoppingCartArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.shoppingPrep: AssistantRouteSpec(
      routeName: AppRoutes.shoppingPrep,
      requiresAccount: true,
      buildArgs: (accountName) => ShoppingCartArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
        openPrepOnStart: true,
      ),
    ),
    AppRoutes.shoppingPointsInput: AssistantRouteSpec(
      routeName: AppRoutes.shoppingPointsInput,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.householdConsumables: AssistantRouteSpec(
      routeName: AppRoutes.householdConsumables,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.consumableInventory: AssistantRouteSpec(
      routeName: AppRoutes.consumableInventory,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.quickStockUse: AssistantRouteSpec(
      routeName: AppRoutes.quickStockUse,
      requiresAccount: true,
      buildArgs: (accountName) => QuickStockUseArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.calendar: AssistantRouteSpec(
      routeName: AppRoutes.calendar,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),

    // Assets
    AppRoutes.assetDashboard: AssistantRouteSpec(
      routeName: AppRoutes.assetDashboard,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.assetTab: AssistantRouteSpec(
      routeName: AppRoutes.assetTab,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.assetAllocation: AssistantRouteSpec(
      routeName: AppRoutes.assetAllocation,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.assetManagement: AssistantRouteSpec(
      routeName: AppRoutes.assetManagement,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.assetSimpleInput: AssistantRouteSpec(
      routeName: AppRoutes.assetSimpleInput,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),

    AppRoutes.assetProject100m: AssistantRouteSpec(
      routeName: AppRoutes.assetProject100m,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),

    // Settings / customization
    AppRoutes.currencySettings: AssistantRouteSpec(
      routeName: AppRoutes.currencySettings,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.backgroundSettings: AssistantRouteSpec(
      routeName: AppRoutes.backgroundSettings,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.fileViewer: AssistantRouteSpec(
      routeName: AppRoutes.fileViewer,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.page1BottomIconSettings: AssistantRouteSpec(
      routeName: AppRoutes.page1BottomIconSettings,
      requiresAccount: true,
      buildArgs: (accountName) => AccountArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.featureIconsCatalog: AssistantRouteSpec(
      routeName: AppRoutes.featureIconsCatalog,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.iconManagement: AssistantRouteSpec(
      routeName: AppRoutes.iconManagement,
      requiresAccount: true,
      buildArgs: (accountName) => IconManagementArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.iconManagement2: AssistantRouteSpec(
      routeName: AppRoutes.iconManagement2,
      requiresAccount: true,
      buildArgs: (accountName) => IconManagementArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.iconManagementAsset: AssistantRouteSpec(
      routeName: AppRoutes.iconManagementAsset,
      requiresAccount: true,
      buildArgs: (accountName) => IconManagementArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),
    AppRoutes.iconManagementRoot: AssistantRouteSpec(
      routeName: AppRoutes.iconManagementRoot,
      requiresAccount: true,
      buildArgs: (accountName) => IconManagementArgs(
        accountName: accountName ?? resolveDefaultAccountName() ?? '',
      ),
    ),

    // Root (admin) - opened via voice, gated by in-app auth.
    AppRoutes.rootTransactions: AssistantRouteSpec(
      routeName: AppRoutes.rootTransactions,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.rootSearch: AssistantRouteSpec(
      routeName: AppRoutes.rootSearch,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.rootAccountManage: AssistantRouteSpec(
      routeName: AppRoutes.rootAccountManage,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.rootMonthEnd: AssistantRouteSpec(
      routeName: AppRoutes.rootMonthEnd,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
    AppRoutes.rootScreenSaverSettings: AssistantRouteSpec(
      routeName: AppRoutes.rootScreenSaverSettings,
      requiresAccount: false,
      buildArgs: (_) => null,
    ),
  };
}
