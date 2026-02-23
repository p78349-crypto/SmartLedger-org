import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/shopping_cart_item.dart';
import '../models/transaction.dart';
import '../services/transaction_service.dart';
import '../services/user_pref_service.dart';
import '../theme/app_colors.dart';
import '../utils/icon_catalog.dart';
import '../utils/refund_utils.dart';
import 'transaction_add_screen.dart';

/// Shows the action bottom-sheet (edit / cart / delete) for a transaction.
Future<void> showDailyTransactionActionSheet({
  required BuildContext context,
  required Transaction tx,
  required String accountName,
  required Future<void> Function() onReload,
}) async {
  final theme = Theme.of(context);
  final action = await showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(IconCatalog.edit, color: theme.colorScheme.primary),
            title: const Text('편집'),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: const Icon(IconCatalog.shoppingCart),
            title: const Text('장바구니 추가'),
            onTap: () => Navigator.pop(context, 'add_to_cart'),
          ),
          ListTile(
            leading: const Icon(IconCatalog.delete, color: Colors.red),
            title: const Text('삭제'),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (action == null || !context.mounted) return;

  switch (action) {
    case 'edit':
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionAddScreen(
            accountName: accountName,
            initialTransaction: tx,
          ),
        ),
      );
      await onReload();
      break;
    case 'add_to_cart':
      await addTransactionToCart(
        context: context,
        tx: tx,
        accountName: accountName,
      );
      break;
    case 'delete':
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('거래 삭제'),
          content: const Text('이 거래를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('삭제'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await TransactionService().deleteTransaction(accountName, tx.id);
        await onReload();
      }
      break;
  }
}

/// Adds the given transaction as a shopping-cart item.
Future<void> addTransactionToCart({
  required BuildContext context,
  required Transaction tx,
  required String accountName,
}) async {
  final name = tx.description.trim();
  if (name.isEmpty) return;

  final qty = tx.quantity > 0 ? tx.quantity : 1;
  final unitPrice =
      tx.unitPrice > 0 ? tx.unitPrice : (tx.amount.abs() / qty);
  final now = DateTime.now();

  final newItem = ShoppingCartItem(
    id: 'cart_${now.microsecondsSinceEpoch}',
    name: name,
    quantity: qty,
    unitPrice: unitPrice.isNaN || unitPrice.isInfinite ? 0 : unitPrice,
    unitLabel: tx.unit ?? '',
    memo: tx.store ?? tx.memo,
    createdAt: now,
    updatedAt: now,
  );

  final existing = await UserPrefService.getShoppingCartItems(
    accountName: accountName,
  );
  final next = [newItem, ...existing];
  await UserPrefService.setShoppingCartItems(
    accountName: accountName,
    items: next.take(30).toList(growable: false),
  );

  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('장바구니에 추가했습니다.')));
}

/// Format a discount amount label.
String formatDiscountLabel(num amount, NumberFormat numberFormat) {
  final formatted = numberFormat.format(amount);
  return '할인 $formatted원';
}

/// A single transaction row (portrait or landscape layout).
class DailyTransactionTile extends StatelessWidget {
  const DailyTransactionTile({
    super.key,
    required this.tx,
    required this.isLandscape,
    required this.numberFormat,
    required this.onTap,
  });

  final Transaction tx;
  final bool isLandscape;
  final NumberFormat numberFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color txColor;
    String prefix;
    switch (tx.type) {
      case TransactionType.income:  txColor = AppColors.income;  prefix = '+';
      case TransactionType.expense: txColor = AppColors.expense; prefix = '-';
      case TransactionType.savings: txColor = AppColors.savings; prefix = '⊕';
      case TransactionType.refund:  txColor = RefundUtils.color; prefix = '⊕';
    }

    if (!isLandscape) {
      return ListTile(
        leading: CircleAvatar(
          backgroundColor: txColor.withValues(alpha: 0.2),
          child: Icon(Icons.receipt_long, color: txColor),
        ),
        title: Text(
          tx.description,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: tx.memo.isNotEmpty ? Text(tx.memo) : null,
        trailing: Text(
          '$prefix${numberFormat.format(tx.amount)}원',
          style: TextStyle(
            color: txColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: onTap,
      );
    }

    final sub = tx.subCategory?.trim();
    final categoryText = (sub == null || sub.isEmpty)
        ? tx.mainCategory
        : '${tx.mainCategory} · $sub';
    final memoText = tx.memo.trim().isEmpty ? '-' : tx.memo.trim();
    final cardCharged = tx.cardChargedAmount;
    final cardText =
        cardCharged == null ? '-' : '${numberFormat.format(cardCharged)}원';
    final baseAbs = tx.amount.abs();
    final hasMismatch =
        cardCharged != null && (cardCharged - baseAbs).abs() >= 1;
    final discountAmount = (cardCharged != null &&
            tx.type == TransactionType.expense &&
            cardCharged < baseAbs)
        ? (baseAbs - cardCharged)
        : null;

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      title: Row(
        children: [
          Expanded(flex: 4, child: Text(tx.description,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: Text(categoryText,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)),
          const SizedBox(width: 10),
          Expanded(flex: 2, child: Text(tx.paymentMethod,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)),
          const SizedBox(width: 10),
          Expanded(flex: 4, child: Text(memoText,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)),
          const SizedBox(width: 10),
          Text(
            '$prefix${numberFormat.format(tx.amount)}원',
            style: TextStyle(color: txColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                cardText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: hasMismatch
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: hasMismatch ? FontWeight.w600 : null,
                ),
              ),
              if (discountAmount != null)
                Text(
                  formatDiscountLabel(discountAmount, numberFormat),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
