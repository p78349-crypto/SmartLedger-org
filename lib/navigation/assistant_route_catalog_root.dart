part of assistant_route_catalog;

final Map<String, AssistantRouteSpec> _rootSpecs = {
  AppRoutes.rootTransactions: const AssistantRouteSpec(
    routeName: AppRoutes.rootTransactions,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.rootSearch: const AssistantRouteSpec(
    routeName: AppRoutes.rootSearch,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.rootAccountManage: const AssistantRouteSpec(
    routeName: AppRoutes.rootAccountManage,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.rootMonthEnd: const AssistantRouteSpec(
    routeName: AppRoutes.rootMonthEnd,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.rootScreenSaverSettings: const AssistantRouteSpec(
    routeName: AppRoutes.rootScreenSaverSettings,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
};
