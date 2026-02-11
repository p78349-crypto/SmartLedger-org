// ignore_for_file: invalid_use_of_protected_member
part of 'consumable_inventory_screen.dart';

extension _ActionsExt on _ConsumableInventoryScreenState {
  Future<void> _loadCountLikeUnits() async {
    try {
      final units = await UserPrefService.getCountLikeUnitsV1();
      if (!mounted) return;
      setState(() {
        _countLikeUnits =
            units.map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
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
    final warning = await ConsumableInventoryService.instance.useItem(
      item.id,
      1.0,
    );
    if (!mounted) return;
    if (warning != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(warning.message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddItemDialog() {
    ConsumableInventoryDialogs.showItemDialog(context: context);
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
        final warning = await ConsumableInventoryService.instance.useItem(
          item.id,
          amount,
        );
        if (!mounted) return;
        if (warning != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(warning.message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name}은(는) 이미 장바구니에 있습니다.'),
          ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name}을(를) 장바구니에 담았습니다.')),
      );
    }
  }
}
