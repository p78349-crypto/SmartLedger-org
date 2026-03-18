part of 'consumable_inventory_screen.dart';

extension ConsumableInventoryLogic on _ConsumableInventoryScreenState {
  Future<void> _loadCountLikeUnits() async {
    try {
      final units = await UserPrefService.getCountLikeUnitsV1();
      if (!mounted) return;
      setState(() {
        _countLikeUnits = units
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toSet();
      });
    } catch (_) {
      // Best-effort
    }
  }

  Future<void> _showCountLikeUnitsDialog() async {
    final result = await ConsumableInventoryDialogs.showCountLikeUnitsDialog(
      context: context,
      currentUnits: _countLikeUnits,
    );

    if (result == null) return;
    await UserPrefService.setCountLikeUnitsV1(result);
    await _loadCountLikeUnits();
  }

  Future<void> _quickDecrementOne(ConsumableInventoryItem item) async {
    await ConsumableInventoryService.instance.useItem(item.id, 1.0);
    // Warning removed as per Diet UI
  }

  void _selectAll() {
    final items = ConsumableInventoryService.instance.items.value;
    setState(() {
      if (_selectedForCartIds.length == items.length) {
        _selectedForCartIds.clear();
      } else {
        _selectedForCartIds.addAll(items.map((e) => e.id));
      }
    });
  }

  Future<void> _addSelectedToCart() async {
    final inventoryItems = ConsumableInventoryService.instance.items.value;
    final selectedItems = inventoryItems
        .where((e) => _selectedForCartIds.contains(e.id))
        .toList();

    if (selectedItems.isEmpty) return;

    final current = await AppRepositories.shoppingCart.getItems(
      accountName: widget.accountName,
    );

    final now = DateTime.now();
    final newCartItems = <ShoppingCartItem>[];
    int skippedCount = 0;

    for (var i = 0; i < selectedItems.length; i++) {
      final item = selectedItems[i];
      if (current.any((c) => c.name == item.name)) {
        skippedCount++;
        continue;
      }

      newCartItems.add(
        ShoppingCartItem(
          id: 'cart_${now.microsecondsSinceEpoch}_$i',
          name: item.name,
          memo: '나의 생활용품에서 추가',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (newCartItems.isNotEmpty) {
      final next = List<ShoppingCartItem>.from(current)..addAll(newCartItems);
      await AppRepositories.shoppingCart.setItems(
        accountName: widget.accountName,
        items: next,
      );
    }

    if (mounted) {
      String msg = '${newCartItems.length}개 항목을 장바구니에 담았습니다.';
      if (skippedCount > 0) {
        msg += ' ($skippedCount개 이미 있음)';
      }
      SnackbarUtils.showSuccess(context, msg);
      setState(() {
        _isCartSelectionMode = false;
        _selectedForCartIds.clear();
      });
    }
  }

  void _showAddItemDialog() {
    final isWarehouseTab = _mainTabController.index == 1;
    ConsumableInventoryDialogs.showItemDialog(
      context: context,
      initialLocation: isWarehouseTab ? '창고' : '주방',
    );
  }

  void _showEditItemDialog(ConsumableInventoryItem item) {
    ConsumableInventoryDialogs.showItemDialog(context: context, item: item);
  }

  void _useItem(ConsumableInventoryItem item) {
    ConsumableInventoryDialogs.showAmountDialog(
      context: context,
      title: '사용량 입력',
      item: item,
      onConfirm: (amount) async {
        await ConsumableInventoryService.instance.useItem(item.id, amount);
      },
    );
  }

  void _refillItem(ConsumableInventoryItem item) {
    ConsumableInventoryDialogs.showAmountDialog(
      context: context,
      title: '추가량 입력',
      item: item,
      onConfirm: (amount) async {
        await ConsumableInventoryService.instance.updateItem(
          item.copyWith(currentStock: item.currentStock + amount),
        );
      },
    );
  }

  Future<void> _sendToCart(ConsumableInventoryItem item) async {
    final current = await AppRepositories.shoppingCart.getItems(
      accountName: widget.accountName,
    );

    if (current.any((i) => i.name == item.name)) {
      if (mounted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name}은(는) 이미 장바구니에 있습니다.')),
        );
      }
      return;
    }

    final now = DateTime.now();
    final newItem = ShoppingCartItem(
      id: 'cart_${now.microsecondsSinceEpoch}',
      name: item.name,
      memo: '재고 부족으로 자동 추가',
      createdAt: now,
      updatedAt: now,
    );

    final next = List<ShoppingCartItem>.from(current)..add(newItem);
    await AppRepositories.shoppingCart.setItems(
      accountName: widget.accountName,
      items: next,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${item.name}을(를) 장바구니에 담았습니다.')));
    }
  }
}
