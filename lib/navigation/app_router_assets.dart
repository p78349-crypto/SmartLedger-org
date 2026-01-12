part of 'app_router.dart';

class _AssetRoutes {
  static Route<dynamic>? resolve(
    RouteSettings settings,
    String name,
    Object? args,
  ) {
    switch (name) {
      case AppRoutes.assetTab:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('자산 관리')),
            body: AssetTabScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.assetDashboard:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: Scaffold(
              appBar: AppBar(title: const Text('자산 대시보드')),
              body: AssetDashboardScreen(accountName: a.accountName),
            ),
          ),
        );

      case AppRoutes.assetAllocation:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: AssetAllocationScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.assetManagement:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: AssetManagementScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.assetSimpleInput:
        final a = args is AssetSimpleInputArgs
            ? args
            : AssetSimpleInputArgs(
                accountName: (args as AccountArgs).accountName,
              );
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: AssetSimpleInputScreen(
              accountName: a.accountName,
              initialCategory: a.initialCategory,
              initialName: a.initialName,
              initialAmount: a.initialAmount,
              initialLocation: a.initialLocation,
              initialMemo: a.initialMemo,
              autoSubmitOnStart: a.autoSubmit,
            ),
          ),
        );

      case AppRoutes.assetDetailInput:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: AssetInputScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.assetProject100m:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: OneHundredMillionProjectScreen(
              accountName: a.accountName,
            ),
          ),
        );

      case AppRoutes.fixedCostTab:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => FixedCostTabScreen(accountName: a.accountName),
        );

      case AppRoutes.fixedCostStats:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => FixedCostStatsScreen(accountName: a.accountName),
        );

      case AppRoutes.savingsPlanList:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SavingsPlanListScreen(
            accountName: a.accountName,
          ),
        );

      default:
        return null;
    }
  }
}
