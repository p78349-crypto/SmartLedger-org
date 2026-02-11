// ignore_for_file: invalid_use_of_protected_member

part of 'food_expiry_items_screen.dart';

/// Bulk usage application and prompt-add-missing-to-cart dialog.
extension FoodExpiryUsageApplyExt on _FoodExpiryItemsScreenState {
  Future<void> _applyBulkUsage() async {
    if (_usageMap.isEmpty) return;

    final recipeName = (_activeRecipeName ?? '').trim();

    int updatedCount = 0;
    final items = FoodExpiryService.instance.items.value;
    final List<String> itemsToRemove = [];

    final usedIngredients = <Map<String, dynamic>>[];
    double totalUsedPrice = 0.0;

    for (var entry in _usageMap.entries) {
      if (entry.value <= 0) continue;

      final item = items.firstWhere(
        (i) => i.id == entry.key,
        orElse: () => items.first,
      );
      if (item.id != entry.key) continue;

      final newQty = (item.quantity - entry.value).clamp(0.0, double.infinity);

      if (item.price > 0 && item.quantity > 0 && entry.value > 0) {
        final unitPrice = item.price / item.quantity;
        final usedPrice = unitPrice * entry.value;
        totalUsedPrice += usedPrice;
        usedIngredients.add(<String, dynamic>{
          'name': item.name,
          'used': entry.value,
          'unit': item.unit,
          'price': usedPrice,
        });
      } else {
        usedIngredients.add(<String, dynamic>{
          'name': item.name,
          'used': entry.value,
          'unit': item.unit,
          'price': 0.0,
        });
      }

      if (newQty <= 0) {
        itemsToRemove.add(item.id);
      } else {
        await FoodExpiryService.instance.updateItem(
          id: item.id,
          name: item.name,
          purchaseDate: item.purchaseDate,
          expiryDate: item.expiryDate,
          memo: item.memo,
          quantity: newQty,
          unit: item.unit,
          category: item.category,
          location: item.location,
          price: item.price,
          supplier: item.supplier,
          healthTags: item.healthTags,
        );
      }
      updatedCount++;
    }

    if (itemsToRemove.isNotEmpty) {
      for (final id in itemsToRemove) {
        await FoodExpiryService.instance.deleteById(id);
      }
    }

    setState(() {
      _isUsageMode = false;
      _usageMap.clear();
      _activeUsageItems.clear();
      _activeRecipeName = null;
    });

    if (usedIngredients.isNotEmpty) {
      await SavingsStatisticsService.instance.addLog(
        recipeName: recipeName.isEmpty ? '사용 기록' : recipeName,
        totalUsedPrice: totalUsedPrice,
        usedIngredientsJson: jsonEncode(usedIngredients),
        isFromExistingInventory: widget.autoUsageMode,
      );
    }

    if (mounted) {
      String msg = '$updatedCount개의 항목 사용량이 기록되었습니다.';
      if (itemsToRemove.isNotEmpty) {
        msg += '\n(${itemsToRemove.length}개 항목 소진되어 삭제됨)';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _promptAddMissingToCart(List<String> missingNames) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.shopping_cart,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('부족한 재료'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✅ 현재 재고로 요리 가능합니다!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('하지만 다음 재료가 없어요:'),
            const SizedBox(height: 12),
            Container(
              width: double.maxFinite,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: missingNames
                    .map(
                      (name) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.remove_circle_outline,
                              size: 16,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '💡 장바구니에 추가해서 다음에 구매하세요!',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('나중에'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: const Text('장바구니 추가'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final accountName = await UserPrefService.getLastAccountName();
      if (accountName == null) return;

      final currentItems = await UserPrefService.getShoppingCartItems(
        accountName: accountName,
      );

      final now = DateTime.now();
      final List<ShoppingCartItem> newItems = [];

      for (var name in missingNames) {
        newItems.add(
          ShoppingCartItem(
            id: 'shop_${now.microsecondsSinceEpoch}_${newItems.length}',
            name: name,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      await UserPrefService.setShoppingCartItems(
        accountName: accountName,
        items: [...newItems, ...currentItems],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newItems.length}개의 재료를 장바구니에 담았습니다.'),
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
}
