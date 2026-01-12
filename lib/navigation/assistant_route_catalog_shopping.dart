part of assistant_route_catalog;

final Map<String, AssistantRouteSpec> _shoppingSpecs = {
  AppRoutes.foodExpiry: const AssistantRouteSpec(
    routeName: AppRoutes.foodExpiry,
    requiresAccount: true,
    buildArgs: _buildFoodExpiryArgs,
  ),
  AppRoutes.foodCookingStart: const AssistantRouteSpec(
    routeName: AppRoutes.foodCookingStart,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.nutritionReport: const AssistantRouteSpec(
    routeName: AppRoutes.nutritionReport,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.weatherManualInput: const AssistantRouteSpec(
    routeName: AppRoutes.weatherManualInput,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.ingredientSearch: const AssistantRouteSpec(
    routeName: AppRoutes.ingredientSearch,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.microSavings: AssistantRouteSpec(
    routeName: AppRoutes.microSavings,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.savingsPlanList: AssistantRouteSpec(
    routeName: AppRoutes.savingsPlanList,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.shoppingCart: AssistantRouteSpec(
    routeName: AppRoutes.shoppingCart,
    requiresAccount: true,
    buildArgs: (accountName) => ShoppingCartArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.shoppingPrep: AssistantRouteSpec(
    routeName: AppRoutes.shoppingPrep,
    requiresAccount: true,
    buildArgs: (accountName) => ShoppingCartArgs(
      accountName: _accountNameOrDefault(accountName),
      openPrepOnStart: true,
    ),
  ),
  AppRoutes.shoppingPointsInput: AssistantRouteSpec(
    routeName: AppRoutes.shoppingPointsInput,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.householdConsumables: AssistantRouteSpec(
    routeName: AppRoutes.householdConsumables,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.consumableInventory: AssistantRouteSpec(
    routeName: AppRoutes.consumableInventory,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.quickStockUse: AssistantRouteSpec(
    routeName: AppRoutes.quickStockUse,
    requiresAccount: true,
    buildArgs: (accountName) => QuickStockUseArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.calendar: AssistantRouteSpec(
    routeName: AppRoutes.calendar,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
};

Object? _buildFoodExpiryArgs(String? _) => const FoodExpiryArgs();
