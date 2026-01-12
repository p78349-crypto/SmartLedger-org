part of assistant_route_catalog;

final Map<String, AssistantRouteSpec> _topLevelSpecs = {
  AppRoutes.topLevelMain: const AssistantRouteSpec(
    routeName: AppRoutes.topLevelMain,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.settings: const AssistantRouteSpec(
    routeName: AppRoutes.settings,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.applicationSettings: const AssistantRouteSpec(
    routeName: AppRoutes.applicationSettings,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.themeSettings: const AssistantRouteSpec(
    routeName: AppRoutes.themeSettings,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.displaySettings: const AssistantRouteSpec(
    routeName: AppRoutes.displaySettings,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.languageSettings: const AssistantRouteSpec(
    routeName: AppRoutes.languageSettings,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.privacyPolicy: const AssistantRouteSpec(
    routeName: AppRoutes.privacyPolicy,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.trash: const AssistantRouteSpec(
    routeName: AppRoutes.trash,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.voiceShortcuts: const AssistantRouteSpec(
    routeName: AppRoutes.voiceShortcuts,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
  AppRoutes.voiceDashboard: const AssistantRouteSpec(
    routeName: AppRoutes.voiceDashboard,
    requiresAccount: false,
    buildArgs: _returnNull,
  ),
};

Object? _returnNull(String? _) => null;

String _accountNameOrDefault(String? accountName) {
  return accountName ??
      AssistantRouteCatalog.resolveDefaultAccountName() ??
      '';
}
