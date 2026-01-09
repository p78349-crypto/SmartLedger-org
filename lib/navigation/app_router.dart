import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'app_routes.dart';
import '../screens/account_create_screen.dart';
import '../screens/account_main_screen.dart';
import '../screens/account_select_screen.dart';
import '../screens/account_stats_screen.dart';
import '../screens/application_settings_screen.dart';
import '../screens/asset_allocation_screen.dart';
import '../screens/asset_dashboard_screen.dart';
import '../screens/asset_input_screen.dart';
import '../screens/asset_management_screen.dart';
import '../screens/asset_simple_input_screen.dart';
import '../screens/asset_tab_screen.dart';
import '../screens/background_settings_screen.dart';
import '../screens/backup_screen.dart';
import '../screens/calendar_screen.dart';
import '../screens/card_discount_stats_screen.dart';
import '../screens/category_stats_screen.dart';
import '../screens/currency_settings_screen.dart';
import '../screens/daily_transactions_screen.dart';
import '../screens/display_settings_screen.dart';
import '../screens/emergency_fund_screen.dart';
import '../screens/feature_icons_catalog_screen.dart';
import '../screens/file_viewer_screen.dart';
import '../screens/fixed_cost_stats_screen.dart';
import '../screens/fixed_cost_tab_screen.dart';
import '../screens/food_expiry_main_screen.dart';
import '../screens/household_consumables_screen.dart';
import '../screens/consumable_inventory_screen.dart';
import '../screens/quick_stock_use_screen.dart';
import '../screens/food_cooking_start_screen.dart';
import '../screens/icon_management2_screen.dart';
import '../screens/icon_management_asset_screen.dart';
import '../screens/icon_management_root_screen.dart';
import '../screens/icon_management_screen.dart';
import '../screens/income_split_screen.dart';
import '../screens/language_settings_screen.dart';
import '../screens/launch_screen.dart';
import '../screens/micro_savings_nudge_screen.dart';
import '../screens/month_end_carryover_screen.dart';
import '../screens/monthly_stats_screen.dart';
import '../screens/nutrition_report_screen.dart';
import '../screens/one_hundred_million_project_screen.dart';
import '../screens/page1_bottom_icon_settings_screen.dart';
import '../screens/period_stats_screen.dart';
import '../utils/period_utils.dart' as period;
import '../screens/ingredient_search_list_screen.dart';
import '../screens/points_motivation_stats_screen.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/quick_simple_expense_input_screen.dart';
import '../screens/refund_transactions_screen.dart';
import '../screens/root_account_manage_screen.dart';
import '../screens/root_month_end_screen.dart';
import '../screens/root_screen_saver_exposure_settings_screen.dart';
import '../screens/root_screen_saver_settings_screen.dart';
import '../screens/root_search_screen.dart';
import '../screens/root_transaction_manager_screen.dart';
import '../screens/savings_plan_list_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/shopping_cart_screen.dart';
import '../screens/shopping_cheapest_month_screen.dart';
import '../screens/shopping_points_input_screen.dart';
import '../screens/spending_analysis_screen.dart';
import '../screens/store_merge_screen.dart';
import '../screens/theme_settings_screen.dart';
import '../screens/top_level_main_screen.dart';
import '../screens/weather_price_prediction_screen.dart';
import '../screens/weather_manual_input_screen.dart';
import '../screens/transaction_add_screen.dart';
import '../screens/transaction_add_detailed_screen.dart';
import '../screens/transaction_detail_screen.dart';
import '../screens/trash_screen.dart';
import '../widgets/asset_route_auth_gate.dart';
import '../widgets/root_auth_gate.dart';
import '../widgets/user_account_auth_gate.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    final args = settings.arguments;

    switch (name) {
      case AppRoutes.topLevelMain:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LaunchScreen(),
        );

      case AppRoutes.topLevelStatsDetail:
        final a = args as TopLevelStatsDetailArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TopLevelStatsDetailScreen(dashboard: a.dashboard),
        );

      case AppRoutes.accountMain:
        final a = args as AccountMainArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => UserAccountAuthGate(
            child: AccountMainScreen(
              accountName: a.accountName,
              initialIndex: a.initialIndex,
            ),
          ),
        );

      case AppRoutes.accountCreate:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AccountCreateScreen(),
        );

      case AppRoutes.accountSelect:
        final a = args as AccountSelectArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AccountSelectScreen(accounts: a.accounts),
        );

      case AppRoutes.transactionAdd:
        final a = args as TransactionAddArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TransactionAddScreen(
            accountName: a.accountName,
            initialTransaction: a.initialTransaction as Transaction?,
            learnCategoryHintFromDescription:
                a.learnCategoryHintFromDescription,
            confirmBeforeSave: a.confirmBeforeSave,
            treatAsNew: a.treatAsNew,
            closeAfterSave: a.closeAfterSave,
          ),
        );

      case AppRoutes.transactionAddDetailed:
        final a = args as TransactionAddArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TransactionAddDetailedScreen(
            accountName: a.accountName,
            initialTransaction: a.initialTransaction as Transaction?,
            learnCategoryHintFromDescription:
                a.learnCategoryHintFromDescription,
            confirmBeforeSave: a.confirmBeforeSave,
            treatAsNew: a.treatAsNew,
            closeAfterSave: a.closeAfterSave,
          ),
        );

      case AppRoutes.transactionAddIncome:
        final a = args as TransactionAddArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TransactionAddScreen(
            accountName: a.accountName,
            initialTransaction: a.initialTransaction as Transaction?,
            learnCategoryHintFromDescription:
                a.learnCategoryHintFromDescription,
            confirmBeforeSave: a.confirmBeforeSave,
            treatAsNew: a.treatAsNew,
            closeAfterSave: a.closeAfterSave,
          ),
        );

      case AppRoutes.transactionDetail:
        final a = args as TransactionDetailArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TransactionDetailScreen(
            accountName: a.accountName,
            initialType: a.initialType as TransactionType,
          ),
        );

      case AppRoutes.transactionDetailIncome:
        final a = args as TransactionDetailArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TransactionDetailScreen(
            accountName: a.accountName,
            initialType: a.initialType as TransactionType,
          ),
        );

      case AppRoutes.monthEndCarryover:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MonthEndCarryoverScreen(accountName: a.accountName),
        );

      case AppRoutes.dailyTransactions:
        final a = args as DailyTransactionsArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DailyTransactionsScreen(
            accountName: a.accountName,
            initialDay: a.initialDay,
            savedCount: a.savedCount,
            showShoppingPointsInputCta: a.showShoppingPointsInputCta,
          ),
        );

      case AppRoutes.refundTransactions:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RefundTransactionsScreen(
            accountName: a.accountName,
            initialDay: DateTime.now(),
          ),
        );

      case AppRoutes.quickSimpleExpenseInput:
        final a = args as QuickSimpleExpenseInputArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => QuickSimpleExpenseInputScreen(
            accountName: a.accountName,
            initialDate: a.initialDate,
          ),
        );

      case AppRoutes.storeMerge:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => UserAccountAuthGate(
            child: StoreMergeScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.emergencyFund:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => EmergencyFundScreen(accountName: a.accountName),
        );

      case AppRoutes.trash:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TrashScreen(),
        );

      case AppRoutes.backup:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => BackupScreen(accountName: a.accountName),
        );

      case AppRoutes.settings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );

      case AppRoutes.applicationSettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ApplicationSettingsScreen(),
        );

      case AppRoutes.iconManagement:
        final a = args as IconManagementArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IconManagementScreen(
            accountName: a.accountName,
            titleOverride: '아이콘 관리(일반)',
            // Split policy: asset/root are managed only via dedicated screens.
            // Hide asset pages (6~7 => {5,6}) and root pages (8~9 => {7,8})
            // from the page picker.
            hiddenPageIndices: const <int>{5, 6, 7, 8},
            // Also hide asset/root icons from the catalog.
            // (asset icons live on catalog page 5; root icons live on page 6)
            catalogHiddenPageIndices: const <int>{5, 6},
          ),
        );

      case AppRoutes.iconManagement2:
        final a = args as IconManagementArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IconManagement2Screen(accountName: a.accountName),
        );

      case AppRoutes.iconManagementAsset:
        final a = args as IconManagementArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IconManagementAssetScreen(accountName: a.accountName),
        );

      case AppRoutes.iconManagementRoot:
        final a = args as IconManagementArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IconManagementRootScreen(accountName: a.accountName),
        );

      case AppRoutes.featureIconsCatalog:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const FeatureIconsCatalogScreen(),
        );

      case AppRoutes.themeSettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ThemeSettingsScreen(),
        );

      case AppRoutes.backgroundSettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const BackgroundSettingsScreen(),
        );

      case AppRoutes.languageSettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LanguageSettingsScreen(),
        );

      case AppRoutes.displaySettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DisplaySettingsScreen(),
        );

      case AppRoutes.currencySettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CurrencySettingsScreen(),
        );

      case AppRoutes.page1BottomIconSettings:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              Page1BottomIconSettingsScreen(accountName: a.accountName),
        );

      case AppRoutes.privacyPolicy:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PrivacyPolicyScreen(),
        );

      case AppRoutes.fileViewer:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const FileViewerScreen(),
        );

      case AppRoutes.accountStats:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AccountStatsScreen(accountName: a.accountName),
        );

      case AppRoutes.accountStatsDecade:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AccountStatsScreen(
            accountName: a.accountName,
            initialView: 'decade',
            initialRangeView: 'decade',
          ),
        );

      case AppRoutes.monthlyStats:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MonthlyStatsScreen(accountName: a.accountName),
        );

      case AppRoutes.categoryStats:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CategoryStatsScreen(accountName: a.accountName),
        );

      case AppRoutes.cardDiscountStats:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CardDiscountStatsScreen(accountName: a.accountName),
        );

      case AppRoutes.pointsMotivationStats:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              PointsMotivationStatsScreen(accountName: a.accountName),
        );

      case AppRoutes.spendingAnalysis:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              SpendingAnalysisScreen(accountName: a.accountName),
        );

      case AppRoutes.weatherPricePrediction:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              WeatherPricePredictionScreen(accountName: a.accountName),
        );

      case AppRoutes.weatherManualInput:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const WeatherManualInputScreen(),
        );

      case AppRoutes.microSavings:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MicroSavingsNudgeScreen(accountName: a.accountName),
        );

      case AppRoutes.accountStatsSearch:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AccountStatsSearchScreen(accountName: a.accountName),
        );

      case AppRoutes.periodStatsWeek:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PeriodStatsScreen(
            accountName: a.accountName,
            view: period.PeriodType.week,
          ),
        );

      case AppRoutes.periodStatsMonth:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PeriodStatsScreen(
            accountName: a.accountName,
            view: period.PeriodType.month,
          ),
        );

      case AppRoutes.periodStatsQuarter:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PeriodStatsScreen(
            accountName: a.accountName,
            view: period.PeriodType.quarter,
          ),
        );

      case AppRoutes.periodStatsHalfYear:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PeriodStatsScreen(
            accountName: a.accountName,
            view: period.PeriodType.halfYear,
          ),
        );

      case AppRoutes.periodStatsYear:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PeriodStatsScreen(
            accountName: a.accountName,
            view: period.PeriodType.year,
          ),
        );

      case AppRoutes.periodStatsDecade:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PeriodStatsScreen(
            accountName: a.accountName,
            view: period.PeriodType.decade,
          ),
        );

      case AppRoutes.incomeSplit:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IncomeSplitScreen(
            accountName: a.accountName,
            initialIncomeAmount: a.initialIncomeAmount,
          ),
        );

      case AppRoutes.foodExpiry:
        final a = args is FoodExpiryArgs ? args : const FoodExpiryArgs();
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => FoodExpiryMainScreen(
            initialIngredients: a.initialIngredients,
            autoUsageMode: a.autoUsageMode,
            openUpsertOnStart: a.openUpsertOnStart,
            openCookableRecipePickerOnStart: a.openCookableRecipePickerOnStart,
          ),
        );

      case AppRoutes.foodCookingStart:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const FoodCookingStartScreen(),
        );

      case AppRoutes.calendar:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CalendarScreen(accountName: a.accountName),
        );

      case AppRoutes.shoppingCart:
        final a = args as ShoppingCartArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ShoppingCartScreen(
            accountName: a.accountName,
            openPrepOnStart: a.openPrepOnStart,
            initialItems: a.initialItems,
          ),
        );

      case AppRoutes.shoppingPrep:
        final a = args as ShoppingCartArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ShoppingCartScreen(
            accountName: a.accountName,
            openPrepOnStart: true,
            initialItems: a.initialItems,
          ),
        );

      case AppRoutes.householdConsumables:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HouseholdConsumablesScreen(
            accountName: a.accountName,
          ),
        );

      case AppRoutes.consumableInventory:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ConsumableInventoryScreen(accountName: a.accountName),
        );

      case AppRoutes.quickStockUse:
        final a = args as QuickStockUseArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => QuickStockUseScreen(
            accountName: a.accountName,
            initialProductName: a.initialProductName,
          ),
        );

      case AppRoutes.shoppingPointsInput:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ShoppingPointsInputScreen(accountName: a.accountName),
        );

      case AppRoutes.shoppingCheapestMonth:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              ShoppingCheapestMonthScreen(accountName: a.accountName),
        );

      case AppRoutes.assetTab:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('자산 관리')),
            body: AssetTabScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.assetDashboard:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: Scaffold(
              appBar: AppBar(title: const Text('자산 대시보드')),
              body: AssetDashboardScreen(accountName: a.accountName),
            ),
          ),
        );

      case AppRoutes.assetAllocation:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: AssetAllocationScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.assetManagement:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: AssetManagementScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.assetSimpleInput:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: AssetSimpleInputScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.assetDetailInput:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: AssetInputScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.assetProject100m:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: OneHundredMillionProjectScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.fixedCostTab:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => FixedCostTabScreen(accountName: a.accountName),
        );

      case AppRoutes.fixedCostStats:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => FixedCostStatsScreen(accountName: a.accountName),
        );

      case AppRoutes.savingsPlanList:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SavingsPlanListScreen(accountName: a.accountName),
        );

      case AppRoutes.nutritionReport:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const NutritionReportScreen(rawText: ''),
        );

      case AppRoutes.ingredientSearch:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const _IngredientSearchInputScreen(),
        );

      case AppRoutes.rootTransactions:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              const RootAuthGate(child: RootTransactionManagerScreen()),
        );

      case AppRoutes.rootSearch:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RootAuthGate(child: RootSearchScreen()),
        );

      case AppRoutes.rootAccountManage:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RootAuthGate(child: RootAccountManageScreen()),
        );

      case AppRoutes.rootMonthEnd:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RootAuthGate(child: RootMonthEndScreen()),
        );

      case AppRoutes.rootScreenSaverSettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RootScreenSaverSettingsScreen(),
        );

      case AppRoutes.rootScreenSaverExposureSettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RootScreenSaverExposureSettingsScreen(),
        );
    }

    return null;
  }
}

/// 식재료 검색 입력 화면 (요리 필요 재료 검색)
class _IngredientSearchInputScreen extends StatefulWidget {
  const _IngredientSearchInputScreen();

  @override
  State<_IngredientSearchInputScreen> createState() =>
      _IngredientSearchInputScreenState();
}

class _IngredientSearchInputScreenState
    extends State<_IngredientSearchInputScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (query.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('검색어를 입력하세요.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => IngredientSearchListScreen(
          searchQuery: query,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('요리 필요 재료 검색'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: theme.colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              '요리 이름을 입력하세요',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '예: 닭고기, 돼지고기, 생선 등',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '요리 이름 입력',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: _search,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _search(_controller.text),
              icon: const Icon(Icons.search),
              label: const Text('검색'),
            ),
          ],
        ),
      ),
    );
  }
}
