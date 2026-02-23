part of 'shopping_cart_bulk_ledger_utils.dart';

Future<void> _addCheckedItemsToLedgerMartShopping({
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
    messenger.showSnackBar(const SnackBar(content: Text('체크된 항목이 없습니다.')));
    return;
  }

  final commonInfo = await showDialog<_MartCommonInfo>(
    context: context,
    builder: (context) => _MartCommonInfoDialog(accountName: accountName),
  );

  if (commonInfo == null || !context.mounted) return;

  var currentItems = items;
  for (var index = 0; index < selected.length; index++) {
    if (!context.mounted) return;
    final item = selected[index];
    final qty = item.quantity <= 0 ? 1 : item.quantity;
    final unit = item.unitPrice;
    final itemTotal = unit * qty;
    final suggested = ShoppingCategoryUtils.suggest(
      item,
      learnedHints: categoryHints,
    );

    await CartTransactionPrefill.savePrefill(
      accountName: accountName,
      items: [
        Transaction(
          id: 'tmp_${DateTime.now().microsecondsSinceEpoch}',
          type: TransactionType.expense,
          description: item.name,
          amount: itemTotal,
          date: commonInfo.date,
          quantity: qty,
          unitPrice: unit,
          paymentMethod: commonInfo.payment,
          store: commonInfo.store,
          mainCategory: suggested.mainCategory,
          subCategory: suggested.subCategory,
          detailCategory: suggested.detailCategory,
        ),
      ],
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
          date: commonInfo.date,
          quantity: qty,
          unitPrice: unit,
          paymentMethod: commonInfo.payment,
          store: commonInfo.store,
          mainCategory: suggested.mainCategory,
          subCategory: suggested.subCategory,
          detailCategory: suggested.detailCategory,
        ),
        treatAsNew: true,
      ),
    );

    if (!context.mounted) return;

    if (result != true) break;

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

    if (index == selected.length - 1) {
      await reload();
      if (!context.mounted) return;

      // 일일지출내역 표시 후 포인트 입력 CTA만 표시
      await navigator.pushNamed(
        AppRoutes.dailyTransactions,
        arguments: DailyTransactionsArgs(
          accountName: accountName,
          initialDay: commonInfo.date,
          savedCount: selected.length,
          showShoppingPointsInputCta: true,  // ✅ 터치 시에만 포인트 입력 열림
        ),
      );
      return; // ✅ 포인트 입력 화면 자동 열기 제거, 터치 시에만 열림
    }
  }
  await reload();
}
