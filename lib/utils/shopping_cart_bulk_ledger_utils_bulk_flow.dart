part of 'shopping_cart_bulk_ledger_utils.dart';

Future<void> _addCheckedItemsToLedgerBulk({
  required BuildContext context,
  required String accountName,
  required List<ShoppingCartItem> items,
  required Map<String, CategoryHint> categoryHints,
  required Future<void> Function(List<ShoppingCartItem> next) saveItems,
  required Future<void> Function() reload,
  bool useDetailedMode = false,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);

  final selected = items.where((i) => i.isChecked).toList();
  if (selected.isEmpty) {
    messenger.showSnackBar(const SnackBar(content: Text('체크된 항목이 없습니다.')));
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

    debugPrint(
      '[ShoppingCartBulkLedgerUtils] 단일 항목 선택: '
      'name=${item.name}, qty=$qty, unit=$unit, total=$total',
    );

    final saved = await navigator.pushNamed(
      useDetailedMode
          ? AppRoutes.transactionAddDetailed
          : AppRoutes.transactionAdd,
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
  // 연속 입력 시 이전 결제수단/메모/카테고리 유지를 위한 변수
  String? lastPaymentMethod;
  String? lastMemo;
  String? lastMainCategory;
  String? lastSubCategory;

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

    // 첫 번째 아이템은 추천 카테고리, 이후는 이전 선택값 유지
    final useMainCategory = lastMainCategory ?? suggested.mainCategory;
    final useSubCategory = lastSubCategory ?? suggested.subCategory;

    final result = await navigator.pushNamed(
      useDetailedMode
          ? AppRoutes.transactionAddDetailed
          : AppRoutes.transactionAdd,
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
          mainCategory: useMainCategory,
          subCategory: useSubCategory,
          detailCategory: suggested.detailCategory,
        ),
        treatAsNew: true,
        // 이전 입력의 결제수단/메모 유지
        initialPaymentMethod: lastPaymentMethod,
        initialMemo: lastMemo,
      ),
    );

    if (!context.mounted) return;

    // TransactionAddResult 또는 bool 처리
    final TransactionAddResult? addResult = result is TransactionAddResult
        ? result
        : null;
    final bool saved = addResult?.saved ?? (result is bool && result);

    if (!saved) {
      break;
    }

    // 다음 아이템을 위해 결제수단/메모/카테고리 저장
    if (addResult != null) {
      lastPaymentMethod = addResult.paymentMethod;
      lastMemo = addResult.memo;
      lastMainCategory = addResult.mainCategory;
      lastSubCategory = addResult.subCategory;
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

      // 일일지출내역 표시 후 포인트 입력 화면으로 이동
      await navigator.pushNamed(
        AppRoutes.dailyTransactions,
        arguments: DailyTransactionsArgs(
          accountName: accountName,
          initialDay: DateTime.now(),
          savedCount: selected.length,
        ),
      );
      if (!context.mounted) return;

      // 포인트 입력 화면 표시 (사용자가 수동 종료)
      await navigator.pushNamed(
        AppRoutes.shoppingPointsInput,
        arguments: ShoppingPointsInputArgs(accountName: accountName),
      );
      return;
    }
  }

  await reload();
}
