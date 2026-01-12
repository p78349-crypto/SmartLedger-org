part of deep_link_handler;

mixin _DeepLinkHandlerCart on _DeepLinkHandlerBase {
  Future<void> _handleAddToCart(
    NavigatorState navigator,
    AddToCartAction action,
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
      return;
    }

    final accountName = accounts.first.name;
    await UserPrefService.setLastAccountName(accountName);

    final locationService = ProductLocationService.instance;
    final previousLocation = await locationService.getLocation(
      accountName: accountName,
      productName: action.name,
    );
    final finalLocation = action.location?.isNotEmpty == true
        ? action.location!
        : (previousLocation ?? '');

    final existingItems = await UserPrefService.getShoppingCartItems(
      accountName: accountName,
    );

    final now = DateTime.now();
    final newItem = ShoppingCartItem(
      id: 'shop_${now.microsecondsSinceEpoch}',
      name: action.name,
      quantity: action.quantity ?? 1,
      unitPrice: action.price ?? 0,
      storeLocation: finalLocation,
      createdAt: now,
      updatedAt: now,
    );

    final updatedItems = [newItem, ...existingItems];
    await UserPrefService.setShoppingCartItems(
      accountName: accountName,
      items: updatedItems,
    );

    if (finalLocation.isNotEmpty) {
      await locationService.saveLocation(
        accountName: accountName,
        productName: action.name,
        location: finalLocation,
      );
    }

    VoiceAssistantAnalytics.logCommand(
      assistant: 'voice',
      route: AppRoutes.shoppingCart,
      intent: 'add_to_cart',
      success: true,
    );

    navigator.pushNamed(
      AppRoutes.shoppingCart,
      arguments: ShoppingCartArgs(accountName: accountName),
    );
  }
}
