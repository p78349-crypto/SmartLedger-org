import 'package:flutter/material.dart';

import '../models/shopping_cart_item.dart';
import '../services/user_pref_service.dart';

class ShoppingCartSyncUtils {
  /// Shows a confirmation dialog and, if confirmed, loads shopping items.
  /// Returns the loaded items or null if the user cancelled.
  static Future<List<ShoppingCartItem>?> confirmAndLoadCheckedItems(
    BuildContext context,
    String accountName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('장바구니 동기화'),
          content: const Text('장바구니 항목을 불러와 현재 입력값을 덮어씁니다. 계속할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('동기화'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return null;

    final items = await UserPrefService.getShoppingCartItems(
      accountName: accountName,
    );
    return items;
  }
}
