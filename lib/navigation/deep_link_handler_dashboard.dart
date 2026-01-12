part of deep_link_handler;

mixin _DeepLinkHandlerDashboard on _DeepLinkHandlerBase {
  void _handleOpenDashboard(NavigatorState navigator) {
    navigator.popUntil((route) => route.isFirst);
  }

  void _handleOpenFeature(NavigatorState navigator, OpenFeatureAction action) {
    void logSuccess(String routeName) {
      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.params),
        route: routeName,
        intent: 'open_feature',
        success: true,
      );
    }

    final route = action.routeName;
    if (route == null) {
      VoiceAssistantAnalytics.logError(
        assistant: _detectAssistant(action.params),
        route: 'unknown',
        errorType: 'ROUTE_NOT_ALLOWED',
      );
      debugPrint('DeepLinkHandler: Unknown feature: ${action.featureId}');
      _showSimpleInfoDialog(
        navigator,
        title: '보안 안내',
        message:
            '보안 사항 접근 안 됩니다.'
            '\n음성비서로는 지원되지 않는 기능입니다.'
            '\n(${action.featureId})',
      );
      return;
    }

    if (route == '/') {
      logSuccess('/');
      navigator.popUntil((route) => route.isFirst);
      return;
    }

    switch (action.featureId) {
      case 'food_expiry':
        logSuccess(AppRoutes.foodExpiry);
        navigator.pushNamed(AppRoutes.foodExpiry);
      case 'shopping_cart':
        logSuccess(AppRoutes.shoppingCart);
        logSuccess(AppRoutes.shoppingCart);
        navigator.pushNamed(AppRoutes.shoppingCart);
      case 'assets':
        logSuccess(AppRoutes.assetDashboard);
        navigator.pushNamed(AppRoutes.assetDashboard);
      case 'recipe':
        logSuccess(AppRoutes.foodCookingStart);
        navigator.pushNamed(AppRoutes.foodCookingStart);
      case 'consumables':
        logSuccess(AppRoutes.householdConsumables);
        navigator.pushNamed(AppRoutes.householdConsumables);
      case 'calendar':
        logSuccess(AppRoutes.calendar);
        navigator.pushNamed(AppRoutes.calendar);
      case 'savings':
        logSuccess(AppRoutes.savingsPlanList);
        navigator.pushNamed(AppRoutes.savingsPlanList);
      case 'emergency_fund':
        logSuccess(AppRoutes.emergencyFund);
        navigator.pushNamed(AppRoutes.emergencyFund);
      case 'stats':
        logSuccess(AppRoutes.monthlyStats);
        navigator.pushNamed(AppRoutes.monthlyStats);
      case 'voice':
      case 'voice_dashboard':
        logSuccess(AppRoutes.voiceDashboard);
        navigator.pushNamed(AppRoutes.voiceDashboard);
      case 'transaction_add':
        _handleAddTransaction(
          navigator,
          const AddTransactionAction(type: 'expense'),
        );
      case 'income_add':
        _handleAddTransaction(
          navigator,
          const AddTransactionAction(type: 'income'),
        );
      case 'quick_stock':
        logSuccess(AppRoutes.quickStockUse);
        navigator.pushNamed(AppRoutes.quickStockUse);
      default:
        VoiceAssistantAnalytics.logError(
          assistant: _detectAssistant(action.params),
          route: 'unknown',
          errorType: 'ROUTE_NOT_ALLOWED',
        );
        debugPrint('DeepLinkHandler: No route mapping for ${action.featureId}');
        _showSimpleInfoDialog(
          navigator,
          title: '보안 안내',
          message:
              '보안 사항 접근 안 됩니다.'
              '\n음성비서로는 지원되지 않는 기능입니다.'
              '\n(${action.featureId})',
        );
    }
  }
}
