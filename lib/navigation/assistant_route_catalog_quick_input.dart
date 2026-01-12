part of assistant_route_catalog;

final Map<String, AssistantRouteSpec> _quickInputSpecs = {
  AppRoutes.quickSimpleExpenseInput: AssistantRouteSpec(
    routeName: AppRoutes.quickSimpleExpenseInput,
    requiresAccount: true,
    buildArgs: (accountName) => QuickSimpleExpenseInputArgs(
      accountName: _accountNameOrDefault(accountName),
      initialDate: DateTime.now(),
    ),
  ),
  AppRoutes.transactionDetail: AssistantRouteSpec(
    routeName: AppRoutes.transactionDetail,
    requiresAccount: true,
    buildArgs: (accountName) => TransactionDetailArgs(
      accountName: _accountNameOrDefault(accountName),
      initialType: TransactionType.expense,
    ),
  ),
  AppRoutes.transactionDetailIncome: AssistantRouteSpec(
    routeName: AppRoutes.transactionDetailIncome,
    requiresAccount: true,
    buildArgs: (accountName) => TransactionDetailArgs(
      accountName: _accountNameOrDefault(accountName),
      initialType: TransactionType.income,
    ),
  ),
};
