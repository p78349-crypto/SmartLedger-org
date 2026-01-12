part of assistant_route_catalog;

final Map<String, AssistantRouteSpec> _assetSpecs = {
  AppRoutes.assetDashboard: AssistantRouteSpec(
    routeName: AppRoutes.assetDashboard,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.assetTab: AssistantRouteSpec(
    routeName: AppRoutes.assetTab,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.assetAllocation: AssistantRouteSpec(
    routeName: AppRoutes.assetAllocation,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.assetManagement: AssistantRouteSpec(
    routeName: AppRoutes.assetManagement,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.assetSimpleInput: AssistantRouteSpec(
    routeName: AppRoutes.assetSimpleInput,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.assetProject100m: AssistantRouteSpec(
    routeName: AppRoutes.assetProject100m,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
};
