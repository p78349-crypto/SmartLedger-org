import '../models/transaction.dart';
import '../navigation/app_routes.dart';
import 'top_level_stats_utils.dart';

class IconLaunchRequest {
  const IconLaunchRequest({required this.routeName, this.arguments});
  final String routeName;
  final Object? arguments;
}

class IconLaunchUtils {
  const IconLaunchUtils._();

  static Transaction _buildIncomeTemplateTransaction() {
    return Transaction(
      id: 'template_income',
      type: TransactionType.income,
      description: '',
      amount: 0,
      date: DateTime.now(),
      mainCategory: Transaction.defaultMainCategory,
    );
  }

  /// Builds the route+args required to launch a feature from the main icon
  /// grid.
  ///
  /// Goal: keep icon taps tab-independent and “one-point”.
  static IconLaunchRequest? buildRequest({
    required String routeName,
    required String accountName,
  }) {
    final noArgsRoutes = <String>{
      AppRoutes.trash,
      AppRoutes.settings,
      AppRoutes.voiceShortcuts,
      AppRoutes.featureIconsCatalog,
      AppRoutes.themeSettings,
      AppRoutes.languageSettings,
      AppRoutes.displaySettings,
      AppRoutes.currencySettings,
      AppRoutes.privacyPolicy,
      AppRoutes.fileViewer,
      AppRoutes.rootTransactions,
      AppRoutes.rootSearch,
      AppRoutes.rootAccountManage,
      AppRoutes.rootMonthEnd,
      AppRoutes.rootScreenSaverSettings,
    };

    if (routeName == AppRoutes.transactionAdd) {
      return IconLaunchRequest(
        routeName: routeName,
        arguments: TransactionAddArgs(accountName: accountName),
      );
    }

    if (routeName == AppRoutes.transactionAddDetailed) {
      return IconLaunchRequest(
        routeName: routeName,
        arguments: TransactionAddArgs(accountName: accountName),
      );
    }

    if (routeName == AppRoutes.transactionAddIncome) {
      return IconLaunchRequest(
        routeName: routeName,
        arguments: TransactionAddArgs(
          accountName: accountName,
          initialTransaction: _buildIncomeTemplateTransaction(),
          treatAsNew: true,
        ),
      );
    }

    if (routeName == AppRoutes.iconManagement ||
        routeName == AppRoutes.iconManagement2 ||
        routeName == AppRoutes.iconManagementAsset ||
        routeName == AppRoutes.iconManagementRoot) {
      return IconLaunchRequest(
        routeName: routeName,
        arguments: IconManagementArgs(accountName: accountName),
      );
    }

    if (routeName == AppRoutes.topLevelStatsDetail) {
      final dashboard = TopLevelStatsUtils.buildDashboardContext();
      return IconLaunchRequest(
        routeName: routeName,
        arguments: TopLevelStatsDetailArgs(dashboard: dashboard),
      );
    }

    if (routeName == AppRoutes.transactionDetail) {
      return IconLaunchRequest(
        routeName: routeName,
        arguments: TransactionDetailArgs(
          accountName: accountName,
          initialType: TransactionType.expense,
        ),
      );
    }

    if (routeName == AppRoutes.transactionDetailIncome) {
      return IconLaunchRequest(
        routeName: routeName,
        arguments: TransactionDetailArgs(
          accountName: accountName,
          initialType: TransactionType.income,
        ),
      );
    }

    if (routeName == AppRoutes.dailyTransactions) {
      return IconLaunchRequest(
        routeName: routeName,
        arguments: DailyTransactionsArgs(
          accountName: accountName,
          initialDay: DateTime.now(),
        ),
      );
    }

    if (routeName == AppRoutes.quickSimpleExpenseInput) {
      return IconLaunchRequest(
        routeName: routeName,
        arguments: QuickSimpleExpenseInputArgs(
          accountName: accountName,
          initialDate: DateTime.now(),
        ),
      );
    }

    if (routeName == AppRoutes.quickStockUse) {
      return IconLaunchRequest(
        routeName: routeName,
        arguments: QuickStockUseArgs(accountName: accountName),
      );
    }

    if (routeName == AppRoutes.shoppingCart) {
      return IconLaunchRequest(
        routeName: routeName,
        arguments: ShoppingCartArgs(accountName: accountName),
      );
    }

    if (routeName == AppRoutes.shoppingPrep) {
      return IconLaunchRequest(
        routeName: routeName,
        arguments: ShoppingCartArgs(accountName: accountName),
      );
    }

    final args = noArgsRoutes.contains(routeName)
        ? null
        : AccountArgs(accountName: accountName);

    return IconLaunchRequest(routeName: routeName, arguments: args);
  }
}
