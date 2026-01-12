library app_router;

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
import '../screens/emergency_screen.dart';
import '../screens/feature_icons_catalog_screen.dart';
import '../screens/file_viewer_screen.dart';
import '../screens/fixed_cost_stats_screen.dart';
import '../screens/fixed_cost_tab_screen.dart';
import '../screens/food_expiry_main_screen.dart';
import '../screens/household_consumables_screen.dart';
import '../screens/consumable_inventory_screen.dart';
import '../screens/quick_stock_use_screen.dart';
import '../screens/food_cooking_start_screen.dart';
import '../screens/quick_health_analyzer_screen.dart';
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
import '../screens/ceo_assistant_dashboard.dart';
import '../screens/ceo_exception_details_screen.dart';
import '../screens/ceo_monthly_defense_report_screen.dart';
import '../screens/ceo_recovery_plan_screen.dart';
import '../screens/ceo_roi_detail_screen.dart';
import '../screens/savings_plan_list_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/shopping_cart_screen.dart';
import '../screens/shopping_guide_screen.dart';
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
import '../screens/voice_shortcuts_screen.dart';
import '../screens/voice_assistant_settings_screen.dart';
import '../screens/voice_dashboard_screen.dart';
import '../widgets/asset_route_auth_gate.dart';
import '../widgets/root_auth_gate.dart';
import '../widgets/user_account_auth_gate.dart';

part 'app_router_top_level.dart';
part 'app_router_transactions.dart';
part 'app_router_settings.dart';
part 'app_router_stats.dart';
part 'app_router_shopping.dart';
part 'app_router_assets.dart';
part 'app_router_root.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    final args = settings.arguments;

    if (name == null) {
      return null;
    }

    return _TopLevelRoutes.resolve(settings, name, args) ??
        _TransactionRoutes.resolve(settings, name, args) ??
        _SettingsRoutes.resolve(settings, name, args) ??
        _StatsRoutes.resolve(settings, name, args) ??
        _ShoppingRoutes.resolve(settings, name, args) ??
        _AssetRoutes.resolve(settings, name, args) ??
        _RootRoutes.resolve(settings, name, args);
  }
}
