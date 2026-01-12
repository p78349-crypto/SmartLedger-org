part of 'shopping_cart_bulk_ledger_utils.dart';

Future<bool> _confirmClearRemainingAfterShopping({
  required BuildContext context,
  required int remainingCount,
}) async {
  if (remainingCount <= 0) return true;

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('장바구니 정리'),
      content: Text(
        '지출 입력이 완료되었습니다.\n'
        '남은 $remainingCount개 항목을 장바구니에서 삭제할까요?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('유지'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('삭제'),
        ),
      ],
    ),
  );

  return result ?? false;
}

class ShoppingCartBulkLedgerUtils {
  ShoppingCartBulkLedgerUtils._();

  static Future<void> addCheckedItemsToLedgerBulk({
    required BuildContext context,
    required String accountName,
    required List<ShoppingCartItem> items,
    required Map<String, CategoryHint> categoryHints,
    required Future<void> Function(List<ShoppingCartItem> next) saveItems,
    required Future<void> Function() reload,
  }) async {
    await _addCheckedItemsToLedgerBulk(
      context: context,
      accountName: accountName,
      items: items,
      categoryHints: categoryHints,
      saveItems: saveItems,
      reload: reload,
    );
  }

  static Future<void> addCheckedItemsToLedgerMartShopping({
    required BuildContext context,
    required String accountName,
    required List<ShoppingCartItem> items,
    required Map<String, CategoryHint> categoryHints,
    required Future<void> Function(List<ShoppingCartItem> next) saveItems,
    required Future<void> Function() reload,
  }) async {
    await _addCheckedItemsToLedgerMartShopping(
      context: context,
      accountName: accountName,
      items: items,
      categoryHints: categoryHints,
      saveItems: saveItems,
      reload: reload,
    );
  }
}
