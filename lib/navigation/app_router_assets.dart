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
          builder: (_) => AssetManagementScreen(accountName: a.accountName),
        );

      case AppRoutes.assetList:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: AssetListScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.assetExport:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: AssetExportScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.dataFlexibleExport:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: DataFlexibleExportScreen(accountName: a.accountName),
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
            child: OneHundredMillionProjectScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.assetPortfolioAnalysis:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => AssetRouteAuthGate(
            requiresSubscription: true,
            subscriptionUserId: a.accountName,
            onSubscriptionAction: () {
              Navigator.of(context).pushNamed(
                AppRoutes.subscriptionManage,
                arguments: a.accountName,
              );
            },
            child: AssetPortfolioAnalysisScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.assetInvestmentRoadmap:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => AssetRouteAuthGate(
            requiresSubscription: true,
            subscriptionUserId: a.accountName,
            onSubscriptionAction: () {
              Navigator.of(context).pushNamed(
                AppRoutes.subscriptionManage,
                arguments: a.accountName,
              );
            },
            child: AssetInvestmentRoadmapScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.aiInvestmentAdvisor:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AssetRouteAuthGate(
            child: AiInvestmentAdvisorScreen(),
          ),
        );

      case AppRoutes.assetSecuritySettings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AssetSecuritySettingsScreen(),
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
          builder: (_) => SavingsPlanListScreen(accountName: a.accountName),
        );

      case AppRoutes.iconManagementAsset:
        final a = args as IconManagementArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => IconManagementAssetScreen(accountName: a.accountName),
        );

      default:
        return null;
    }
  }
}
