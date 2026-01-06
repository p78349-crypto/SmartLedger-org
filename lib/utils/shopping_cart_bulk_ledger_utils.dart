import 'package:flutter/material.dart';

import 'package:smart_ledger/models/category_hint.dart';
import 'package:smart_ledger/models/shopping_cart_history_entry.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
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

    // Sequential quick saves: after the first save, payment/memo will be
    // auto-prefilled on the next screen.
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

  static Future<void> addCheckedItemsToLedgerMartShopping({
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

    // 1. Collect common info (Store, Payment, Date)
    final commonInfo = await showDialog<_MartCommonInfo>(
      context: context,
      builder: (context) => _MartCommonInfoDialog(accountName: accountName),
    );

    if (commonInfo == null || !context.mounted) return;

    // 2. Proceed with bulk entry using common info
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

      final result = await navigator.pushNamed(
        AppRoutes.transactionAdd,
        arguments: TransactionAddArgs(
          accountName: accountName,
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
        await navigator.pushNamed(
          AppRoutes.dailyTransactions,
          arguments: DailyTransactionsArgs(
            accountName: accountName,
            initialDay: commonInfo.date,
            savedCount: selected.length,
            showShoppingPointsInputCta: true,
          ),
        );
      }
    }
    await reload();
  }
}

class _MartCommonInfo {
  final String store;
  final String payment;
  final DateTime date;
  const _MartCommonInfo(this.store, this.payment, this.date);
}

class _MartCommonInfoDialog extends StatefulWidget {
  final String accountName;
  const _MartCommonInfoDialog({required this.accountName});

  @override
  State<_MartCommonInfoDialog> createState() => _MartCommonInfoDialogState();
}

class _MartCommonInfoDialogState extends State<_MartCommonInfoDialog> {
  final _storeController = TextEditingController();
  final _paymentController = TextEditingController();
  DateTime _date = DateTime.now();

  List<String> _recentStores = [];
  List<String> _recentPayments = [];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    final stores = await UserPrefService.getRecentStores(widget.accountName);
    final payments = await UserPrefService.getRecentPayments(
      widget.accountName,
    );
    if (mounted) {
      setState(() {
        _recentStores = stores;
        _recentPayments = payments;
        if (stores.isNotEmpty) _storeController.text = stores.first;
        if (payments.isNotEmpty) _paymentController.text = payments.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('마트 쇼핑 정보 입력'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _storeController,
              decoration: const InputDecoration(
                labelText: '마트/쇼핑몰',
                hintText: '예: 이마트, 쿠팡 등',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: _recentStores
                  .take(3)
                  .map(
                    (s) => ActionChip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      onPressed: () =>
                          setState(() => _storeController.text = s),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _paymentController,
              decoration: const InputDecoration(
                labelText: '결제수단',
                hintText: '예: 현대카드, 현금 등',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              children: _recentPayments
                  .take(3)
                  .map(
                    (p) => ActionChip(
                      label: Text(p, style: const TextStyle(fontSize: 11)),
                      onPressed: () =>
                          setState(() => _paymentController.text = p),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('쇼핑 날짜'),
              subtitle: Text('${_date.year}-${_date.month}-${_date.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_storeController.text.trim().isEmpty ||
                _paymentController.text.trim().isEmpty) {
              return;
            }
            Navigator.pop(
              context,
              _MartCommonInfo(
                _storeController.text.trim(),
                _paymentController.text.trim(),
                _date,
              ),
            );
          },
          child: const Text('시작하기'),
        ),
      ],
    );
  }
}
