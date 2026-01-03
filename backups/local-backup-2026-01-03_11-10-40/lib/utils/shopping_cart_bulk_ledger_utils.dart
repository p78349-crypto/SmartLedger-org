import 'package:flutter/material.dart';

import 'package:smart_ledger/models/category_hint.dart';
import 'package:smart_ledger/models/shopping_cart_history_entry.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/currency_formatter.dart';
import 'package:smart_ledger/utils/shopping_category_utils.dart';

class ShoppingCartBulkLedgerUtils {
  ShoppingCartBulkLedgerUtils._();

  static Future<bool> _confirmClearRemainingAfterShopping({
    required BuildContext context,
    required int remainingCount,
  }) async {
    if (remainingCount <= 0) return true;
    return false;
  }

  static Future<void> addCheckedItemsToLedgerBulk({
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

    int qtyOf(ShoppingCartItem i) => i.quantity <= 0 ? 1 : i.quantity;

    // Single item: lightweight quick transaction.
    if (selected.length == 1) {
      final item = selected.first;
      final qty = qtyOf(item);
      final unit = item.unitPrice;
      if (unit <= 0) {
        messenger.showSnackBar(const SnackBar(content: Text('단가를 입력하세요.')));
        return;
      }
      final total = unit * qty;
      final suggested = ShoppingCategoryUtils.suggest(
        item,
        learnedHints: categoryHints,
      );

      final baseNow = DateTime.now();

      final saved = await navigator.pushNamed(
        AppRoutes.shoppingCartQuickTransaction,
        arguments: ShoppingCartQuickTransactionArgs(
          accountName: accountName,
          title: '장바구니',
          description: item.name,
          quantity: qty,
          unitPrice: unit,
          total: total,
          initialMainCategory: suggested.mainCategory,
          initialSubCategory: suggested.subCategory,
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

    final itemsMissingUnitPrice = selected
        .where((i) => i.unitPrice <= 0)
        .toList();
    if (itemsMissingUnitPrice.isNotEmpty) {
      final firstName = itemsMissingUnitPrice.first.name;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '단가 미입력 항목이 있어요: “$firstName” 등 ${itemsMissingUnitPrice.length}개',
          ),
        ),
      );
      return;
    }
    final total = selected.fold<double>(
      0.0,
      (sum, i) => sum + (qtyOf(i) * i.unitPrice),
    );
    if (total <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('합계 금액이 0원입니다. 단가를 확인하세요.')),
      );
      return;
    }

    final bulkPreviewLines = selected
        .map((i) {
          final qty = qtyOf(i);
          final unit = i.unitPrice;
          final lineTotal = qty * unit;
          final left = '${i.name} ($qty개)';
          final right = CurrencyFormatter.format(lineTotal);
          return '$left = $right';
        })
        .toList(growable: false);

    // Sequential quick saves: after the first save, payment/memo will be
    // auto-prefilled on the next screen. From the 2nd item, the screen can
    // also save the remaining items at once ("나머지 모두 저장").
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

      final remaining = selected.sublist(index);
      final result = await navigator.pushNamed(
        AppRoutes.shoppingCartQuickTransaction,
        arguments: ShoppingCartQuickTransactionArgs(
          accountName: accountName,
          title: '장바구니(일괄) ${index + 1}/${selected.length}',
          description: item.name,
          quantity: qty,
          unitPrice: unit,
          total: itemTotal,
          initialMainCategory: suggested.mainCategory,
          initialSubCategory: suggested.subCategory,
          bulkRemainingItems: remaining,
          bulkIndex: index,
          bulkTotalCount: selected.length,
          bulkCategoryHints: categoryHints,
          bulkGrandTotal: total,
          bulkPreviewLines: bulkPreviewLines,
        ),
      );

      if (!context.mounted) return;

      if (result is ShoppingCartQuickTransactionSaveRestResult) {
        for (final savedId in result.savedItemIds) {
          final savedItem = selected.firstWhere(
            (i) => i.id == savedId,
            orElse: () => ShoppingCartItem(
              id: savedId,
              name: '',
              quantity: 1,
              unitPrice: 0,
              isPlanned: false,
              isChecked: false,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          final at = DateTime.now();
          await UserPrefService.addShoppingCartHistoryEntry(
            accountName: accountName,
            entry: ShoppingCartHistoryEntry(
              id: 'hist_${at.microsecondsSinceEpoch}',
              action: ShoppingCartHistoryAction.addToLedger,
              itemId: savedId,
              name: savedItem.name,
              quantity: savedItem.quantity,
              unitPrice: savedItem.unitPrice,
              isPlanned: savedItem.isPlanned,
              at: at,
            ),
          );
        }

        final ids = result.savedItemIds.toSet();
        currentItems = currentItems.where((i) => !ids.contains(i.id)).toList();

        if (!context.mounted) return;

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
            savedCount: result.savedItemIds.length,
            showShoppingPointsInputCta: true,
          ),
        );
        return;
      }

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
}
