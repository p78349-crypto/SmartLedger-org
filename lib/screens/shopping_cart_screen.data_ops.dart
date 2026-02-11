// ignore_for_file: invalid_use_of_protected_member
part of 'shopping_cart_screen.dart';

/// Extension: data load/save, ordering, add/delete, flush.
extension ShoppingCartDataOps on _ShoppingCartScreenState {
  Future<void> _load() async {
    setState(() => _isLoading = true);

    final items = List<ShoppingCartItem>.from(
      await UserPrefService.getShoppingCartItems(
        accountName: widget.accountName,
      ),
    );

    // Merge initial items if provided (e.g. from Recipe Picker)
    if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
      for (final initItem in widget.initialItems!) {
        final exists = items.any(
          (e) =>
              e.name.trim().toLowerCase() == initItem.name.trim().toLowerCase(),
        );
        if (!exists) {
          items.insert(0, initItem);
        }
      }
      final limited = items.take(30).toList();
      await UserPrefService.setShoppingCartItems(
        accountName: widget.accountName,
        items: limited,
      );
    }

    final hints = await UserPrefService.getShoppingCategoryHints(
      accountName: widget.accountName,
    );

    if (!mounted) return;
    setState(() {
      _items = items;
      _categoryHints = hints;
      _isLoading = false;
    });

    _syncInlineControllers(items);
  }

  Future<void> _save(List<ShoppingCartItem> next) async {
    final limited = next.take(30).toList();
    setState(() => _items = limited);
    _syncInlineControllers(limited);
    await UserPrefService.setShoppingCartItems(
      accountName: widget.accountName,
      items: limited,
    );
  }

  String _formatDateLabel(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  List<ShoppingCartItem> _orderedItems(List<ShoppingCartItem> list) {
    if (widget.openPrepOnStart) return list;
    final unChecked = <ShoppingCartItem>[];
    final checked = <ShoppingCartItem>[];
    for (final item in list) {
      (item.isChecked ? checked : unChecked).add(item);
    }
    return [...unChecked, ...checked];
  }

  Future<void> _toggleChecked(ShoppingCartItem item) async {
    final updated = item.copyWith(
      isChecked: !item.isChecked,
      updatedAt: DateTime.now(),
    );
    final next = _items.map((i) => i.id == item.id ? updated : i).toList();
    await _save(next);
  }

  Future<void> _openTransactionAdd() async {
    await _flushInlineEdits();
    if (!mounted) return;
    await ShoppingCartBulkLedgerUtils.addCheckedItemsToLedgerBulk(
      context: context,
      accountName: widget.accountName,
      items: _items,
      categoryHints: _categoryHints,
      saveItems: _save,
      reload: _load,
    );
  }

  Future<void> _flushInlineEdits() async {
    bool changed = false;
    final next = _items
        .map((item) {
          final bundleRaw = _qtyControllers[item.id]?.text.trim() ?? '';
          final perBundleRaw =
              _bundleSizeControllers[item.id]?.text.trim() ?? '';
          final unitRaw = _unitPriceControllers[item.id]?.text.trim() ?? '';
          final memoRaw = _memoControllers[item.id]?.text.trim() ?? item.memo;

          final parsedBundle = int.tryParse(bundleRaw);
          final parsedPerBundle = int.tryParse(perBundleRaw);
          final parsedUnit = CurrencyFormatter.parse(unitRaw);

          final nextBundle = (parsedBundle == null)
              ? item.bundleCount
              : (parsedBundle < 0 ? 0 : parsedBundle);
          final nextPerBundle = (parsedPerBundle == null)
              ? item.unitsPerBundle
              : (parsedPerBundle < 0 ? 0 : parsedPerBundle);
          final nextQty = nextBundle * nextPerBundle;
          final nextUnit = (parsedUnit == null) ? item.unitPrice : parsedUnit;
          final nextMemo = memoRaw;

          if (nextBundle == item.bundleCount &&
              nextPerBundle == item.unitsPerBundle &&
              nextUnit == item.unitPrice &&
              nextMemo == item.memo) {
            return item;
          }

          changed = true;
          return item.copyWith(
            bundleCount: nextBundle,
            unitsPerBundle: nextPerBundle,
            quantity: nextQty,
            unitPrice: nextUnit,
            memo: nextMemo,
            updatedAt: DateTime.now(),
          );
        })
        .toList(growable: false);

    if (changed) {
      await _save(next);
    }
  }

  Future<void> _addItem({bool keepKeyboardOpen = false}) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final previousLocation = await ProductLocationService.instance.getLocation(
      accountName: widget.accountName,
      productName: name,
    );

    final now = DateTime.now();
    final item = ShoppingCartItem(
      id: 'shop_${now.microsecondsSinceEpoch}',
      name: name,
      storeLocation: previousLocation ?? '',
      createdAt: now,
      updatedAt: now,
    );

    final next = [item, ..._items];
    _nameController.clear();
    await _save(next);

    if (!mounted) return;
    if (keepKeyboardOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _nameFocusNode.requestFocus();
      });
    }
  }

  Future<void> _deleteItem(ShoppingCartItem item) async {
    final next = _items.where((i) => i.id != item.id).toList();
    await _save(next);
  }

  Future<void> _deleteItemWithUndo(ShoppingCartItem item) async {
    final prev = List<ShoppingCartItem>.from(_items);
    await _deleteItem(item);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('삭제됨: ${item.name}'),
        action: SnackBarAction(
          label: '되돌리기',
          onPressed: () async {
            await _save(prev);
          },
        ),
      ),
    );
  }
}
