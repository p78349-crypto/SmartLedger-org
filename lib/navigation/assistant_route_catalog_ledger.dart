part of assistant_route_catalog;

final Map<String, AssistantRouteSpec> _ledgerSpecs = {
  AppRoutes.accountMain: AssistantRouteSpec(
    routeName: AppRoutes.accountMain,
    requiresAccount: true,
    buildArgs: (accountName) => AccountMainArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.transactionAdd: AssistantRouteSpec(
    routeName: AppRoutes.transactionAdd,
    requiresAccount: true,
    buildArgs: (accountName) => TransactionAddArgs(
      accountName: _accountNameOrDefault(accountName),
      treatAsNew: true,
      closeAfterSave: true,
    ),
  ),
  AppRoutes.transactionAddIncome: AssistantRouteSpec(
    routeName: AppRoutes.transactionAddIncome,
    requiresAccount: true,
    buildArgs: (accountName) => TransactionAddArgs(
      accountName: _accountNameOrDefault(accountName),
      treatAsNew: true,
      closeAfterSave: true,
    ),
  ),
  AppRoutes.transactionAddDetailed: AssistantRouteSpec(
    routeName: AppRoutes.transactionAddDetailed,
    requiresAccount: true,
    buildArgs: (accountName) => TransactionAddArgs(
      accountName: _accountNameOrDefault(accountName),
      treatAsNew: true,
      closeAfterSave: true,
    ),
  ),
  AppRoutes.dailyTransactions: AssistantRouteSpec(
    routeName: AppRoutes.dailyTransactions,
    requiresAccount: true,
    buildArgs: (accountName) => DailyTransactionsArgs(
      accountName: _accountNameOrDefault(accountName),
      initialDay: DateTime.now(),
    ),
  ),
  AppRoutes.refundTransactions: AssistantRouteSpec(
    routeName: AppRoutes.refundTransactions,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.backup: AssistantRouteSpec(
    routeName: AppRoutes.backup,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.monthEndCarryover: AssistantRouteSpec(
    routeName: AppRoutes.monthEndCarryover,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.incomeSplit: AssistantRouteSpec(
    routeName: AppRoutes.incomeSplit,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
  AppRoutes.emergencyFund: AssistantRouteSpec(
    routeName: AppRoutes.emergencyFund,
    requiresAccount: true,
    buildArgs: (accountName) => AccountArgs(
      accountName: _accountNameOrDefault(accountName),
    ),
  ),
};
