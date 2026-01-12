part of 'app_router.dart';

class _TopLevelRoutes {
  static Route<dynamic>? resolve(
    RouteSettings settings,
    String name,
    Object? args,
  ) {
    switch (name) {
      case AppRoutes.topLevelMain:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LaunchScreen(),
        );

      case AppRoutes.topLevelStatsDetail:
        final a = args as TopLevelStatsDetailArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => TopLevelStatsDetailScreen(
            dashboard: a.dashboard,
          ),
        );

      case AppRoutes.accountMain:
        final a = args as AccountMainArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => UserAccountAuthGate(
            child: AccountMainScreen(
              accountName: a.accountName,
              initialIndex: a.initialIndex,
            ),
          ),
        );

      case AppRoutes.accountCreate:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AccountCreateScreen(),
        );

      case AppRoutes.accountSelect:
        final a = args as AccountSelectArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AccountSelectScreen(accounts: a.accounts),
        );

      default:
        return null;
    }
  }
}
