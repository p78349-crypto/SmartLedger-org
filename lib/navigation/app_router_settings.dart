part of 'app_router.dart';

class _SettingsRoutes {
  static Route<dynamic>? resolve(
    RouteSettings settings,
    String name,
    Object? args,
  ) {
    switch (name) {
      case AppRoutes.settings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SettingsScreen(),
        );

      case AppRoutes.subscriptionManage:
        final userId = args is String ? args : null;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SubscriptionManageScreen(userId: userId),
        );

      case AppRoutes.serverSyncSettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ServerSyncSettingsScreen(),
        );

      case AppRoutes.applicationSettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ApplicationSettingsScreen(),
        );

      case AppRoutes.databaseEncryption:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DatabaseEncryptionScreen(),
        );

      case AppRoutes.securitySettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SecuritySettingsScreen(),
        );

      case AppRoutes.iconManagement:
        final a = args as IconManagementArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IconManagementScreen(
            accountName: a.accountName,
            titleOverride: '아이콘 관리',
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

      case AppRoutes.iconManagementSettings:
        final a = args as IconManagementArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              IconManagementSettingsScreen(accountName: a.accountName),
        );

      case AppRoutes.pageIconManagement:
        final a = args as PageIconManagementArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => PageIconManagementScreen(
            accountName: a.accountName,
            pageIndex: a.pageIndex,
            pageTitle: a.pageTitle,
          ),
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

      case AppRoutes.voiceShortcuts:
        if (!AppConstants.voiceInputEnabled) {
          return _voiceDisabledRoute(settings);
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const VoiceShortcutsScreen(),
        );

      case AppRoutes.voiceAssistantSettings:
        if (!AppConstants.voiceInputEnabled) {
          return _voiceDisabledRoute(settings);
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const VoiceAssistantSettingsScreen(),
        );

      case AppRoutes.voiceDashboard:
        if (!AppConstants.voiceInputEnabled) {
          return _voiceDisabledRoute(settings);
        }
        final a = args as AccountArgs?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => VoiceDashboardScreen(accountName: a?.accountName),
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

      case AppRoutes.gemmaApiTest:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const GemmaApiTestScreen(),
        );

      default:
        return null;
    }
  }
}
