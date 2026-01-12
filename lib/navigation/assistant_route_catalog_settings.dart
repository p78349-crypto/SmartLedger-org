part of assistant_route_catalog;

final Map<String, AssistantRouteSpec> _settingsSpecs = {
  AppRoutes.currencySettings: const AssistantRouteSpec(
    routeName: AppRoutes.currencySettings,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.backgroundSettings: const AssistantRouteSpec(
    routeName: AppRoutes.backgroundSettings,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.fileViewer: const AssistantRouteSpec(
    routeName: AppRoutes.fileViewer,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.page1BottomIconSettings: AssistantRouteSpec(
    routeName: AppRoutes.page1BottomIconSettings,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.featureIconsCatalog: const AssistantRouteSpec(
    routeName: AppRoutes.featureIconsCatalog,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.iconManagement: AssistantRouteSpec(
    routeName: AppRoutes.iconManagement,
    requiresAccount: true,
    buildArgs: (accountName) => IconManagementArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.iconManagement2: AssistantRouteSpec(
    routeName: AppRoutes.iconManagement2,
    requiresAccount: true,
    buildArgs: (accountName) => IconManagementArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.iconManagementAsset: AssistantRouteSpec(
    routeName: AppRoutes.iconManagementAsset,
    requiresAccount: true,
    buildArgs: (accountName) => IconManagementArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.iconManagementRoot: AssistantRouteSpec(
    routeName: AppRoutes.iconManagementRoot,
    requiresAccount: true,
    buildArgs: (accountName) => IconManagementArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
};
