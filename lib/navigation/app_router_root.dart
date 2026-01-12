part of 'app_router.dart';

class _RootRoutes {
  static Route<dynamic>? resolve(
    RouteSettings settings,
    String name,
    Object? args,
  ) {
    switch (name) {
      case AppRoutes.rootTransactions:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              const RootAuthGate(child: RootTransactionManagerScreen()),
        );

      case AppRoutes.rootSearch:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RootAuthGate(child: RootSearchScreen()),
        );

      case AppRoutes.rootAccountManage:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RootAuthGate(
            child: RootAccountManageScreen(),
          ),
        );

      case AppRoutes.rootMonthEnd:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RootAuthGate(child: RootMonthEndScreen()),
        );

      case AppRoutes.rootScreenSaverSettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RootScreenSaverSettingsScreen(),
        );

      case AppRoutes.rootScreenSaverExposureSettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RootScreenSaverExposureSettingsScreen(),
        );

      case AppRoutes.ceoAssistant:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RootAuthGate(
            child: CEOAssistantDashboard(accountName: 'root'),
          ),
        );

      case AppRoutes.ceoExceptionDetails:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RootAuthGate(
            child: CEOExceptionDetailsScreen(accountName: 'root'),
          ),
        );

      case AppRoutes.ceoRoiDetail:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) {
            final now = DateTime.now();
            final start = DateTime(now.year, now.month - 11);
            final end = DateTime(now.year, now.month + 1);
            return RootAuthGate(
              child: CEORoiDetailScreen(
                accountName: 'root',
                start: start,
                end: end,
              ),
            );
          },
        );

      case AppRoutes.ceoMonthlyDefenseReport:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RootAuthGate(
            child: CEOMonthlyDefenseReportScreen(accountName: 'root'),
          ),
        );

      case AppRoutes.ceoRecoveryPlan:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RootAuthGate(
            child: CEORecoveryPlanScreen(accountName: 'root'),
          ),
        );

      default:
        return null;
    }
  }
}
