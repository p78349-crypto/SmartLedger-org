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
            // Split policy: asset/root managed via dedicated screens.
            // Hide asset pages (6~7 => {5,6}) and root pages (8~9 => {7,8})
            // from the page picker.
            hiddenPageIndices: const <int>{5, 6, 7, 8},
            // Also hide asset/root icons from the catalog
            // (asset icons live on page 5, root icons on page 6).
            catalogHiddenPageIndices: const <int>{5, 6},
          ),
        );

      case AppRoutes.iconManagement2:
        final a = args as IconManagementArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IconManagement2Screen(
            accountName: a.accountName,
          ),
        );

      case AppRoutes.iconManagementAsset:
        final a = args as IconManagementArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IconManagementAssetScreen(
            accountName: a.accountName,
          ),
        );

      case AppRoutes.iconManagementRoot:
        final a = args as IconManagementArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IconManagementRootScreen(
            accountName: a.accountName,
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
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const VoiceShortcutsScreen(),
        );

      case AppRoutes.voiceAssistantSettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const VoiceAssistantSettingsScreen(),
        );

      case AppRoutes.voiceDashboard:
        final a = args as AccountArgs?;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => VoiceDashboardScreen(
            accountName: a?.accountName,
          ),
        );

      case AppRoutes.page1BottomIconSettings:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Page1BottomIconSettingsScreen(
            accountName: a.accountName,
          ),
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

      default:
        return null;
    }
  }
}
