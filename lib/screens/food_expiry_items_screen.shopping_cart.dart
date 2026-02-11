// ignore_for_file: invalid_use_of_protected_member

part of 'food_expiry_items_screen.dart';

/// Shopping cart related methods.
extension FoodExpiryShoppingCartExt on _FoodExpiryItemsScreenState {
  Future<void> _addToCart(BuildContext context, FoodExpiryItem item) async {
    final accountName = await UserPrefService.getLastAccountName();
    if (accountName == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('계정 정보를 불러올 수 없습니다.')));
      }
      return;
    }

    final currentItems = await UserPrefService.getShoppingCartItems(
      accountName: accountName,
    );

    final now = DateTime.now();
    final newItem = ShoppingCartItem(
      id: 'shop_${now.microsecondsSinceEpoch}',
      name: item.name,
      createdAt: now,
      updatedAt: now,
    );

    final nextItems = [newItem, ...currentItems];
    await UserPrefService.setShoppingCartItems(
      accountName: accountName,
      items: nextItems,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name}을(를) 장바구니에 담았습니다.'),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addMissingToCart(List<String> names) async {
    await _addIngredientNamesToCart(names);
  }

  Future<void> _addIngredientNamesToCart(List<String> names) async {
    final accountName = await UserPrefService.getLastAccountName();
    if (accountName == null) return;

    final currentItems = await UserPrefService.getShoppingCartItems(
      accountName: accountName,
    );

    final now = DateTime.now();
    final incoming = <ShoppingCartItem>[];
    for (var i = 0; i < names.length; i++) {
      final name = names[i].trim();
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

    if (merged.added <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('추가할 새 항목이 없습니다.')));
      }
      return;
    }

    await UserPrefService.setShoppingCartItems(
      accountName: accountName,
      items: merged.merged,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${merged.added}개의 재료를 장바구니에 담았습니다.'),
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
    }
  }
}
