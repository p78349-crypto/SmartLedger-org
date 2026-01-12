part of 'shopping_cart_bulk_ledger_utils.dart';

Future<void> _addCheckedItemsToLedgerBulk({
  required BuildContext context,
  required String accountName,
  required List<ShoppingCartItem> items,
  required Map<String, CategoryHint> categoryHints,
  required Future<void> Function(List<ShoppingCartItem> next) saveItems,
  required Future<void> Function() reload,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  final selected = items.where((i) => i.isChecked).toList();
  if (selected.isEmpty) {
    messenger.showSnackBar(
      const SnackBar(content: Text('체크된 항목이 없습니다.')),
    );
    return;
  }

  int qtyOf(ShoppingCartItem i) => i.quantity <= 0 ? 1 : i.quantity;

  if (selected.length == 1) {
    final item = selected.first;
    final qty = qtyOf(item);
    final unit = item.unitPrice;
    final total = unit * qty;
    final suggested = ShoppingCategoryUtils.suggest(
      item,
      learnedHints: categoryHints,
    );

    final baseNow = DateTime.now();

    final saved = await navigator.pushNamed(
      AppRoutes.transactionAdd,
      arguments: TransactionAddArgs(
        accountName: accountName,
        closeAfterSave: true,
        initialTransaction: Transaction(
          id: 'tmp_${baseNow.microsecondsSinceEpoch}',
          type: TransactionType.expense,
          description: item.name,
          amount: total,
          date: baseNow,
          quantity: qty,
          unitPrice: unit,
          mainCategory: suggested.mainCategory,
          subCategory: suggested.subCategory,
          detailCategory: suggested.detailCategory,
        ),
        treatAsNew: true,
      ),
    );

    final savedBool = saved is bool ? saved : null;

    if (!context.mounted) return;

    if (savedBool == true) {
      await UserPrefService.addShoppingCartHistoryEntry(
        accountName: accountName,
        entry: ShoppingCartHistoryEntry(
          id: 'hist_${baseNow.microsecondsSinceEpoch}',
          action: ShoppingCartHistoryAction.addToLedger,
          itemId: item.id,
          name: item.name,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          isPlanned: item.isPlanned,
          at: baseNow,
        ),
      );

      if (!context.mounted) return;

      final remaining = items.where((i) => i.id != item.id).toList();
      final shouldClear = await _confirmClearRemainingAfterShopping(
        context: context,
        remainingCount: remaining.length,
      );
      if (!context.mounted) return;

      await saveItems(shouldClear ? const [] : remaining);
    }

    await reload();
    return;
  }

  var currentItems = items;
  for (var index = 0; index < selected.length; index++) {
    if (!context.mounted) return;
    final item = selected[index];
    final qty = qtyOf(item);
    final unit = item.unitPrice;
    final itemTotal = unit * qty;
    final suggested = ShoppingCategoryUtils.suggest(
      item,
      learnedHints: categoryHints,
    );

    final result = await navigator.pushNamed(
      AppRoutes.transactionAdd,
      arguments: TransactionAddArgs(
        accountName: accountName,
        closeAfterSave: true,
        initialTransaction: Transaction(
          id: 'tmp_${DateTime.now().microsecondsSinceEpoch}',
          type: TransactionType.expense,
          description: item.name,
          amount: itemTotal,
          date: DateTime.now(),
          quantity: qty,
          unitPrice: unit,
          mainCategory: suggested.mainCategory,
          subCategory: suggested.subCategory,
          detailCategory: suggested.detailCategory,
        ),
        treatAsNew: true,
      ),
    );

    if (!context.mounted) return;

    final savedBool = result is bool ? result : null;
    if (savedBool != true) {
      break;
    }

    final at = DateTime.now();
    await UserPrefService.addShoppingCartHistoryEntry(
      accountName: accountName,
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

    currentItems = currentItems.where((i) => i.id != item.id).toList();
    await saveItems(currentItems);

    if (!context.mounted) return;

    if (index == selected.length - 1) {
      final shouldClear = await _confirmClearRemainingAfterShopping(
        context: context,
        remainingCount: currentItems.length,
      );
      if (!context.mounted) return;

      await saveItems(shouldClear ? const [] : currentItems);
      await reload();
      if (!context.mounted) return;

      await navigator.pushNamed(
        AppRoutes.dailyTransactions,
        arguments: DailyTransactionsArgs(
          accountName: accountName,
          initialDay: DateTime.now(),
          savedCount: selected.length,
          showShoppingPointsInputCta: true,
        ),
      );
      return;
    }
  }

  await reload();
}
