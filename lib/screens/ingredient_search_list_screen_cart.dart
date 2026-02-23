// ignore_for_file: invalid_use_of_protected_member

part of 'ingredient_search_list_screen.dart';

/// 장바구니 관련 메서드
extension IngredientSearchCart on _IngredientSearchListScreenState {
  Future<void> _addSingleToCart(String itemName) async {
    final accountName = await UserPrefService.getLastAccountName();
    if (accountName == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('계정이 선택되지 않았습니다.')));
      }
      return;
    }

    final currentItems = await UserPrefService.getShoppingCartItems(
      accountName: accountName,
    );

    final now = DateTime.now();
    final newItem = ShoppingCartItem(
      id: 'shop_${now.microsecondsSinceEpoch}',
      name: itemName,
      createdAt: now,
      updatedAt: now,
    );

    final merged = ShoppingPrepUtils.mergeByName(
      existing: currentItems,
      incoming: [newItem],
    );

    await UserPrefService.setShoppingCartItems(
      accountName: accountName,
      items: merged.merged,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$itemName을(를) 장바구니에 추가했습니다.'),
          action: SnackBarAction(
            label: '장바구니 이동',
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.shoppingCart,
                arguments: ShoppingCartArgs(accountName: accountName),
              );
            },
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _sendToShoppingCart() async {
    if (_selectedNames.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('선택된 식재료가 없습니다.')));
      return;
    }

    final selectedItems = _selectedNames.toList();

    if (widget.onSelect != null) {
      // 장바구니로 보내기 (각 항목을 callbacks으로 전송)
      for (final item in selectedItems) {
        widget.onSelect?.call(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedItems.length}개 식재료를 장바구니에 추가했습니다.'),
          ),
        );
        Navigator.pop(context);
      }
      return;
    } else {
      // Default behavior: add directly to shopping prep/cart.
      final accountName = await UserPrefService.getLastAccountName();
      if (accountName == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('계정이 선택되지 않았습니다.')));
        }
        return;
      }

      final currentItems = await UserPrefService.getShoppingCartItems(
        accountName: accountName,
      );

      final now = DateTime.now();
      final incoming = <ShoppingCartItem>[];
      for (var i = 0; i < selectedItems.length; i++) {
        final name = selectedItems[i].trim();
        if (name.isEmpty) continue;
        incoming.add(
          ShoppingCartItem(
            id: 'shop_${now.microsecondsSinceEpoch}_$i',
            name: name,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final merged = ShoppingPrepUtils.mergeByName(
        existing: currentItems,
        incoming: incoming,
      );

      await UserPrefService.setShoppingCartItems(
        accountName: accountName,
        items: merged.merged,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${merged.added}개 식재료를 장바구니에 추가했습니다.'),
            action: SnackBarAction(
              label: '장바구니 이동',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.shoppingCart,
                  arguments: ShoppingCartArgs(accountName: accountName),
                );
              },
            ),
          ),
        );
        Navigator.pop(context);
      }

      return;
    }
  }
}
