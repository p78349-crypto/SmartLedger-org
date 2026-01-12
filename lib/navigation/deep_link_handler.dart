library deep_link_handler;

import 'dart:async';

import 'package:flutter/material.dart';

import 'app_routes.dart';
import 'global_navigator_key.dart';
import '../models/shopping_cart_item.dart';
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../services/consumable_inventory_service.dart';
import '../services/deep_link_service.dart';
import '../services/health_guardrail_service.dart';
import '../services/product_location_service.dart';
import '../services/user_pref_service.dart';
import '../services/voice_assistant_analytics.dart';
import 'assistant_route_catalog.dart';
import 'route_param_validator.dart';
import '../utils/date_parser.dart';

part 'deep_link_handler_open_route.dart';
part 'deep_link_handler_open_route_food_expiry.dart';
part 'deep_link_handler_open_route_asset.dart';
part 'deep_link_handler_open_route_quick_expense.dart';
part 'deep_link_handler_transactions.dart';
part 'deep_link_handler_cart.dart';
part 'deep_link_handler_dashboard.dart';
part 'deep_link_handler_stock.dart';
part 'deep_link_handler_recipe.dart';
part 'deep_link_handler_helpers.dart';

abstract class _DeepLinkHandlerBase {
  void _showSimpleInfoDialog(
    NavigatorState navigator, {
    required String title,
    required String message,
    // ignore: unused_element_parameter
    List<Widget>? actions,
  });

  String _detectAssistant(Map<String, String>? params);

  void _logAndShowError({
    required NavigatorState navigator,
    required String errorType,
    required String route,
    String? assistant,
    String? message,
    List<Widget>? actions,
    List<String>? rejectedParams,
  });

  Widget _buildInfoRow(String label, String value, Color valueColor);

  String _formatQty(double value);

  String _accountNameOrDefault(String? accountName);

  void _handleAddTransaction(
    NavigatorState navigator,
    AddTransactionAction action,
  );

  bool _handleOpenRouteFoodExpiry({
    required NavigatorState navigator,
    required OpenRouteAction action,
    required AssistantRouteSpec spec,
    required Map<String, String> filteredParams,
  });

  bool _handleOpenRouteAsset({
    required NavigatorState navigator,
    required OpenRouteAction action,
    required AssistantRouteSpec spec,
    required Map<String, String> filteredParams,
    required String? accountName,
  });

  bool _handleOpenRouteQuickExpense({
    required NavigatorState navigator,
    required OpenRouteAction action,
    required AssistantRouteSpec spec,
    required Map<String, String> filteredParams,
    required String? accountName,
  });
}

/// Deep link handler that listens to incoming deep links
/// and navigates to the appropriate screen.
class DeepLinkHandler extends _DeepLinkHandlerBase
    with
        _DeepLinkHandlerHelpers,
        _DeepLinkHandlerOpenRoute,
        _DeepLinkHandlerOpenRouteFoodExpiry,
        _DeepLinkHandlerOpenRouteAsset,
        _DeepLinkHandlerOpenRouteQuickExpense,
        _DeepLinkHandlerTransactions,
        _DeepLinkHandlerCart,
        _DeepLinkHandlerDashboard,
        _DeepLinkHandlerStock,
        _DeepLinkHandlerRecipe {
  DeepLinkHandler._();
  static final DeepLinkHandler instance = DeepLinkHandler._();

  StreamSubscription<DeepLinkAction>? _subscription;
  bool _initialized = false;

  /// Initialize the deep link handler.
  /// Should be called once from main.dart after services are loaded.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Initialize the deep link service first
    await DeepLinkService.instance.init();

    // Listen to deep link events
    _subscription = DeepLinkService.instance.linkStream.listen(_handleAction);
  }

  void _handleAction(DeepLinkAction action) {
    final navigator = appNavigatorKey.currentState;
    if (navigator == null) {
      debugPrint('DeepLinkHandler: Navigator not available');
      return;
    }

    debugPrint('DeepLinkHandler: Received action: ${_summarizeAction(action)}');

    switch (action) {
      case AddTransactionAction():
        _handleAddTransaction(navigator, action);
      case OpenDashboardAction():
        _handleOpenDashboard(navigator);
      case OpenFeatureAction():
        _handleOpenFeature(navigator, action);
      case AddToCartAction():
        _handleAddToCart(navigator, action);
      case RecipeRecommendAction():
        _handleRecipeRecommend(navigator, action);
      case ReceiptAnalyzeAction():
        _handleReceiptAnalyze(navigator, action);
      case OpenRouteAction():
        _handleOpenRoute(navigator, action);
      case CheckStockAction():
        _handleCheckStock(navigator, action);
      case UseStockAction():
        _handleUseStock(navigator, action);
    }
  }

  String _summarizeAction(DeepLinkAction action) {
    switch (action) {
      case AddTransactionAction():
        return 'AddTransactionAction(type: ${action.type}, '
            'autoSubmit: ${action.autoSubmit}, '
            'confirmed: ${action.confirmed}, '
            'openReceiptScannerOnStart: '
            '${action.openReceiptScannerOnStart})';
      case OpenDashboardAction():
        return 'OpenDashboardAction()';
      case OpenFeatureAction():
        return 'OpenFeatureAction(featureId: ${action.featureId})';
      case AddToCartAction():
        return 'AddToCartAction(name: ${action.name}, '
            'location: ${action.location})';
      case RecipeRecommendAction():
        return 'RecipeRecommendAction(mealType: ${action.mealType}, '
            'ingredients: ${action.ingredients}, '
            'prioritizeExpiring: ${action.prioritizeExpiring})';
      case ReceiptAnalyzeAction():
        return 'ReceiptAnalyzeAction(ingredients: ${action.ingredients})';
      case OpenRouteAction():
        final keys = action.params.keys.toList()..sort();
        return 'OpenRouteAction(routeName: ${action.routeName}, '
            'intent: ${action.intent}, '
            'autoSubmit: ${action.autoSubmit}, '
            'confirmed: ${action.confirmed}, '
            'paramKeys: $keys)';
      case CheckStockAction():
        return 'CheckStockAction()';
      case UseStockAction():
        return 'UseStockAction(autoSubmit: ${action.autoSubmit}, '
            'confirmed: ${action.confirmed})';
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
