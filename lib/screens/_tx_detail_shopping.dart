part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Shopping-cart picker and spend-comparison tooltip.
extension TxDetailShopping on _TransactionAddDetailedFormState {
  Future<String?> _buildShoppingSpendComparisonTooltip({
    required String accountName,
  }) async {
    final service = TransactionService();
    await service.loadTransactions();

    final all = service.getTransactions(accountName);
    if (all.isEmpty) return null;

    final now = DateTime.now();
    final today = _dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));
    final rangeStart = yesterday.subtract(
      const Duration(days: _shoppingAvgLookbackDays - 1),
    );

    final totalsByDay = <DateTime, double>{};

    for (final tx in all) {
      if (tx.type != TransactionType.expense) continue;
      if (!_isShoppingCategory(tx.mainCategory, tx.subCategory)) continue;

      final day = _dateOnly(tx.date);
      if (day.isBefore(rangeStart) || day.isAfter(yesterday)) continue;

      totalsByDay[day] = (totalsByDay[day] ?? 0) + tx.amount;
    }

    double sum = 0;
    for (var i = 0; i < _shoppingAvgLookbackDays; i++) {
      final day = rangeStart.add(Duration(days: i));
      sum += totalsByDay[day] ?? 0;
    }

    final yesterdayTotal = totalsByDay[yesterday] ?? 0;
    final avg = sum / _shoppingAvgLookbackDays;

    final yText = CurrencyFormatter.format(yesterdayTotal);
    final avgText = CurrencyFormatter.format(avg);

    String deltaText = '';
    if (avg.abs() > 0.000001) {
      final pct = ((yesterdayTotal - avg) / avg) * 100.0;
      final sign = pct >= 0 ? '+' : '';
      deltaText = ' ($sign${pct.toStringAsFixed(0)}%)';
    }

    return '쇼핑 기준(식비/생활용품/의류)\n'
        '어제: $yText\n'
        '최근 $_shoppingAvgLookbackDays일 일평균: $avgText$deltaText';
  }

  Future<void> confirmAndOpenShoppingCartPicker() async {
    final items = await ShoppingCartSyncUtils.confirmAndLoadCheckedItems(
      context,
      widget.accountName,
    );
    if (!mounted || items == null) return;

    await _saveDraft();

    await openShoppingCartPicker();
  }

  Future<void> openShoppingCartPicker() async {
    FocusScope.of(context).unfocus();
    await _saveDraft();

    var items = await UserPrefService.getShoppingCartItems(
      accountName: widget.accountName,
    );

    if (!mounted || items.isEmpty) {
      if (mounted) {
        SnackbarUtils.showInfo(context, '장바구니에 저장된 항목이 없습니다.');
      }
      return;
    }

    final local = items.map((e) => e.copyWith()).toList();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _buildShoppingPickerSheet(local, sheetContext),
    );

    if (!mounted || confirmed != true) return;

    items = local;
    final checkedItems = items.where((i) => i.isChecked).toList();

    if (checkedItems.length == 1) {
      await _handleSingleShoppingItem(checkedItems.first, items);
      return;
    }

    // 다중 항목 선택 시 bulk flow
    final hints = await UserPrefService.getShoppingCategoryHints(
      accountName: widget.accountName,
    );
    if (!mounted) return;

    await ShoppingCartBulkLedgerUtils.addCheckedItemsToLedgerBulk(
      context: context,
      accountName: widget.accountName,
      items: items,
      categoryHints: hints,
      saveItems: (next) async {
        await UserPrefService.setShoppingCartItems(
          accountName: widget.accountName,
          items: next,
        );
      },
      reload: () async {},
      useDetailedMode: true,
    );
  }

  Future<void> _handleSingleShoppingItem(
    ShoppingCartItem item,
    List<ShoppingCartItem> allItems,
  ) async {
    debugPrint(
      '[openShoppingCartPicker] 단일 항목 선택(자동입력 비활성): '
      'name=${item.name}',
    );

    setState(() {
      _descController.text = item.name;
    });

    await UserPrefService.setShoppingCartItems(
      accountName: widget.accountName,
      items: allItems.where((i) => i.id != item.id).toList(),
    );

    final at = DateTime.now();
    await UserPrefService.addShoppingCartHistoryEntry(
      accountName: widget.accountName,
      entry: ShoppingCartHistoryEntry(
        id: 'hist_${at.microsecondsSinceEpoch}',
        action: ShoppingCartHistoryAction.addToLedger,
        itemId: item.id,
        name: item.name,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        isPlanned: item.isPlanned,
        at: at,
      ),
    );

    if (mounted) {
      SnackbarUtils.showInfo(context, '${item.name}을(를) 입력 필드에 추가했습니다.');
    }
  }
}
