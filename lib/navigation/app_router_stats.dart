part of 'app_router.dart';

class _StatsRoutes {
  static Route<dynamic>? resolve(
    RouteSettings settings,
    String name,
    Object? args,
  ) {
    switch (name) {
      case AppRoutes.accountStats:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: AccountStatsScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.accountStatsDecade:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: AccountStatsScreen(
              accountName: a.accountName,
              initialView: 'decade',
              initialRangeView: 'decade',
            ),
          ),
        );

      case AppRoutes.monthlyStats:
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
            child: MonthlyStatsScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.categoryStats:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CategoryStatsScreen(accountName: a.accountName),
        );

      case AppRoutes.cardDiscountStats:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => CardDiscountStatsScreen(accountName: a.accountName),
        );

      case AppRoutes.pointsMotivationStats:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              PointsMotivationStatsScreen(accountName: a.accountName),
        );

      case AppRoutes.rewardSystemStats:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RewardSystemStatsScreen(accountName: a.accountName),
        );

      case AppRoutes.spendingAnalysis:
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
            child: SpendingAnalysisScreen(accountName: a.accountName),
          ),
        );

      case AppRoutes.advancedFinancialAnalytics:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AdvancedFinancialAnalyticsScreen(),
        );

      case AppRoutes.ceoPredictionDashboard:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CeoPredictionDashboardScreen(),
        );

      case AppRoutes.weatherPricePrediction:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              WeatherPricePredictionScreen(accountName: a.accountName),
        );

      case AppRoutes.weatherManualInput:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const WeatherManualInputScreen(),
        );

      case AppRoutes.microSavings:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => MicroSavingsNudgeScreen(accountName: a.accountName),
        );

      case AppRoutes.accountStatsSearch:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AccountStatsSearchScreen(accountName: a.accountName),
        );

      case AppRoutes.periodStatsWeek:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: PeriodStatsScreen(
              accountName: a.accountName,
              view: period.PeriodType.week,
            ),
          ),
        );

      case AppRoutes.periodStatsMonth:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: PeriodStatsScreen(
              accountName: a.accountName,
              view: period.PeriodType.month,
            ),
          ),
        );

      case AppRoutes.periodStatsQuarter:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: PeriodStatsScreen(
              accountName: a.accountName,
              view: period.PeriodType.quarter,
            ),
          ),
        );

      case AppRoutes.periodStatsHalfYear:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: PeriodStatsScreen(
              accountName: a.accountName,
              view: period.PeriodType.halfYear,
            ),
          ),
        );

      case AppRoutes.periodStatsYear:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: PeriodStatsScreen(
              accountName: a.accountName,
              view: period.PeriodType.year,
            ),
          ),
        );

      case AppRoutes.periodStatsDecade:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: PeriodStatsScreen(
              accountName: a.accountName,
              view: period.PeriodType.decade,
            ),
          ),
        );

      case AppRoutes.incomeSplit:
        final a = args as AccountArgs;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AssetRouteAuthGate(
            child: IncomeSplitScreen(
              accountName: a.accountName,
              initialIncomeAmount: a.initialIncomeAmount,
            ),
          ),
        );

      default:
        return null;
    }
  }
}
