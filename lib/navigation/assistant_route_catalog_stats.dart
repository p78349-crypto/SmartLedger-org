part of assistant_route_catalog;

final Map<String, AssistantRouteSpec> _statsSpecs = {
  AppRoutes.accountStats: AssistantRouteSpec(
    routeName: AppRoutes.accountStats,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.accountStatsDecade: AssistantRouteSpec(
    routeName: AppRoutes.accountStatsDecade,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.accountStatsSearch: AssistantRouteSpec(
    routeName: AppRoutes.accountStatsSearch,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.categoryStats: AssistantRouteSpec(
    routeName: AppRoutes.categoryStats,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.periodStatsWeek: AssistantRouteSpec(
    routeName: AppRoutes.periodStatsWeek,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.periodStatsMonth: AssistantRouteSpec(
    routeName: AppRoutes.periodStatsMonth,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.periodStatsQuarter: AssistantRouteSpec(
    routeName: AppRoutes.periodStatsQuarter,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.periodStatsHalfYear: AssistantRouteSpec(
    routeName: AppRoutes.periodStatsHalfYear,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.periodStatsYear: AssistantRouteSpec(
    routeName: AppRoutes.periodStatsYear,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.periodStatsDecade: AssistantRouteSpec(
    routeName: AppRoutes.periodStatsDecade,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.shoppingCheapestMonth: AssistantRouteSpec(
    routeName: AppRoutes.shoppingCheapestMonth,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.weatherPricePrediction: AssistantRouteSpec(
    routeName: AppRoutes.weatherPricePrediction,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.monthlyStats: AssistantRouteSpec(
    routeName: AppRoutes.monthlyStats,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.spendingAnalysis: AssistantRouteSpec(
    routeName: AppRoutes.spendingAnalysis,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.cardDiscountStats: AssistantRouteSpec(
    routeName: AppRoutes.cardDiscountStats,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.pointsMotivationStats: AssistantRouteSpec(
    routeName: AppRoutes.pointsMotivationStats,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.fixedCostStats: AssistantRouteSpec(
    routeName: AppRoutes.fixedCostStats,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
};
