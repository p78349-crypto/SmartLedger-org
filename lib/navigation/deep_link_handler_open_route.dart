part of deep_link_handler;

mixin _DeepLinkHandlerOpenRoute on _DeepLinkHandlerBase {
  void _handleOpenRoute(NavigatorState navigator, OpenRouteAction action) {
    final spec = AssistantRouteCatalog.specs[action.routeName];
    if (spec == null) {
      _logAndShowError(
        navigator: navigator,
        errorType: 'ROUTE_NOT_ALLOWED',
        route: action.routeName,
        assistant: _detectAssistant(action.params),
        message:
            '음성비서로는 해당 화면을 열 수 없습니다.\n'
            '앱에서 직접 열어주세요.\n'
            '(${action.routeName})',
      );
      return;
    }

    final accountName =
        action.accountName ?? AssistantRouteCatalog.resolveDefaultAccountName();
    if (spec.requiresAccount && (accountName == null || accountName.isEmpty)) {
      _logAndShowError(
        navigator: navigator,
        errorType: 'ACCOUNT_REQUIRED',
        route: action.routeName,
        assistant: _detectAssistant(action.params),
        message: '먼저 계정을 생성하거나 선택해주세요.',
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(navigator.context);
              navigator.pushNamed(AppRoutes.accountSelect);
            },
            child: const Text('계정 선택'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(navigator.context),
            child: const Text('취소'),
          ),
        ],
      );
      return;
    }

    final args = spec.buildArgs(accountName);

    final validationResult = RouteParamValidator.validate(
      action.routeName,
      action.params,
    );
    final validatedParams = validationResult.validated;

    final rejectedKeys = validationResult.rejected;
    if (rejectedKeys.isNotEmpty) {
      debugPrint('DeepLinkHandler: Rejected params: $rejectedKeys');
      VoiceAssistantAnalytics.logRejectedParams(
        route: action.routeName,
        rejected: rejectedKeys,
        assistant: _detectAssistant(action.params),
      );
    }

    final filteredParams = validatedParams;

    if (_handleOpenRouteTransactionScan(
      navigator: navigator,
      action: action,
      spec: spec,
      args: args,
      filteredParams: filteredParams,
    )) {
      return;
    }

    if (_handleOpenRouteFoodExpiry(
      navigator: navigator,
      action: action,
      spec: spec,
      filteredParams: filteredParams,
    )) {
      return;
    }

    if (_handleOpenRouteAsset(
      navigator: navigator,
      action: action,
      spec: spec,
      filteredParams: filteredParams,
      accountName: accountName,
    )) {
      return;
    }

    if (_handleOpenRouteQuickExpense(
      navigator: navigator,
      action: action,
      spec: spec,
      filteredParams: filteredParams,
      accountName: accountName,
    )) {
      return;
    }

    VoiceAssistantAnalytics.logCommand(
      assistant: _detectAssistant(action.params),
      route: action.routeName,
      intent: action.intent ?? 'open',
      success: true,
    );

    navigator.pushNamed(spec.routeName, arguments: args);
  }

  bool _handleOpenRouteTransactionScan({
    required NavigatorState navigator,
    required OpenRouteAction action,
    required AssistantRouteSpec spec,
    required Object? args,
    required Map<String, String> filteredParams,
  }) {
    if (action.routeName != AppRoutes.transactionAdd) {
      return false;
    }
    if (args is! TransactionAddArgs) return false;

    final intent = (action.intent ?? '').trim().toLowerCase();
    final requestedAction = (filteredParams['action'] ?? '')
        .trim()
        .toLowerCase();

    final wantsScan =
        intent == 'scan_receipt' ||
        intent == 'scan' ||
        requestedAction == 'scan';

    if (!wantsScan) return false;

    navigator.pushNamed(
      spec.routeName,
      arguments: TransactionAddArgs(
        accountName: args.accountName,
        initialTransaction: args.initialTransaction,
        learnCategoryHintFromDescription: args.learnCategoryHintFromDescription,
        confirmBeforeSave: args.confirmBeforeSave,
        treatAsNew: args.treatAsNew,
        closeAfterSave: args.closeAfterSave,
        autoSubmit: args.autoSubmit,
        openReceiptScannerOnStart: true,
      ),
    );
    return true;
  }
}
