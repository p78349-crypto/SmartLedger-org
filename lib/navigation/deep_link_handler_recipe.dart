part of deep_link_handler;

mixin _DeepLinkHandlerRecipe on _DeepLinkHandlerBase {
  Future<void> _handleRecipeRecommend(
    NavigatorState navigator,
    RecipeRecommendAction action,
  ) async {
    final accountService = AccountService();
    await accountService.loadAccounts();
    final accounts = accountService.accounts;
    if (accounts.isEmpty) {
      _showSimpleInfoDialog(
        navigator,
        title: '계정 없음',
        message: '먼저 계정을 생성해주세요.',
      );
      VoiceAssistantAnalytics.logCommand(
        assistant: 'Bixby',
        route: '/food/expiry',
        intent: 'recipe_recommend',
        success: false,
        failureReason: 'ACCOUNT_REQUIRED',
      );
      return;
    }

    final accountName = accounts.first.name;
    await UserPrefService.setLastAccountName(accountName);

    final mealLabel = _getMealLabel(action.mealType);

    VoiceAssistantAnalytics.logCommand(
      assistant: 'Bixby',
      route: '/food/expiry',
      intent: 'recipe_recommend',
      success: true,
    );

    navigator.pushNamed(
      AppRoutes.foodExpiry,
      arguments: const FoodExpiryArgs(
        openCookableRecipePickerOnStart: true,
        scrollToDailyRecipeRecommendationOnStart: true,
      ),
    );

    Future.delayed(const Duration(milliseconds: 800), () {
      if (navigator.mounted) {
        String message;
        if (action.prioritizeExpiring) {
          message =
              '⚠️ 유통기한 임박 재료 활용 요리!\n'
              '🕒 빨리 소진해야 할 재료 우선 사용\n'
              '✅ 현재 재고로 만들 수 있는 레시피\n'
              '📝 부족한 재료는 장바구니에 추가';
        } else if (action.ingredients != null &&
            action.ingredients!.isNotEmpty) {
          final ingredientsText = action.ingredients!.join(', ');
          message =
              '💡 $ingredientsText 사용 가능한 $mealLabel 추천!\n'
              '✅ 현재 재고로 만들 수 있는 레시피\n'
              '📝 부족한 재료는 장바구니에 자동 추가';
        } else if (action.mealType != null) {
          message =
              '💡 $mealLabel 추천!\n'
              '✅ 냉장고 재료로 만들 수 있는 요리\n'
              '📝 부족한 재료는 장바구니에 추가 가능';
        } else {
          message =
              '💡 냉장고 재료로 만들 수 있는 요리 추천!\n'
              '✅ 유통기한 임박 재료 우선 사용\n'
              '📝 부족한 재료는 장바구니에 자동 추가';
        }

        ScaffoldMessenger.of(navigator.context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: '확인', onPressed: () {}),
          ),
        );
      }
    });
  }

  Future<void> _handleReceiptAnalyze(
    NavigatorState navigator,
    ReceiptAnalyzeAction action,
  ) async {
    VoiceAssistantAnalytics.logCommand(
      assistant: 'Bixby',
      route: '/food/health-analyzer',
      intent: 'receipt_analyze',
      success: true,
    );

    navigator.pushNamed(AppRoutes.healthAnalyzer);

    Future.delayed(const Duration(milliseconds: 800), () {
      if (navigator.mounted) {
        String message;
        if (action.ingredients != null && action.ingredients!.isNotEmpty) {
          message =
              '✅ 입력한 재료의 건강도를 분석합니다\n'
              '💚 5점: 매우 건강 (채소, 버섯)\n'
              '🟡 3점: 보통 (닭고기, 쌀)\n'
              '🔴 1점: 비건강 (튀김, 가공식품)';
        } else {
          message =
              '📋 영수증 재료를 입력하세요\n'
              '✅ 체크박스로 간편하게 선택\n'
              '💚 실시간 건강 점수 계산\n'
              '📊 건강한 재료 비율 통계';
        }

        ScaffoldMessenger.of(navigator.context).showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '확인',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    });
  }

  String _getMealLabel(String? mealType) {
    if (mealType == null) return '요리';
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '아침 메뉴';
      case 'lunch':
        return '점심 메뉴';
      case 'dinner':
        return '저녁 메뉴';
      default:
        return '요리';
    }
  }
}
