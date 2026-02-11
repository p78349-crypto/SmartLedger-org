// ignore_for_file: invalid_use_of_protected_member

part of 'daily_transactions_screen.dart';

/// 거래 액션/다이얼로그/장바구니 관련 메서드
extension DailyTransactionsActions on _DailyTransactionsScreenState {
  Future<void> loadData() async {
    await TransactionService().loadTransactions();
    final transactions = TransactionService().getTransactions(
      widget.accountName,
    );

    final grouped = <DateTime, List<Transaction>>{};
    for (final tx in transactions) {
      final key = _stripTime(tx.date);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    final days = grouped.keys.toList()..sort();

    setState(() {
      _events = grouped;
      _eventDays = days;
    });
  }

  Future<void> showTransactionActionSheet(Transaction tx) async {
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
              leading: Icon(
                IconCatalog.edit,
                color: theme.colorScheme.primary,
              ),
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

    if (action == null || !mounted) return;

    switch (action) {
      case 'edit':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionAddScreen(
              accountName: widget.accountName,
              initialTransaction: tx,
            ),
          ),
        );
        await loadData();
        break;
      case 'add_to_cart':
        await _addTransactionToCart(tx);
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
          await TransactionService().deleteTransaction(
            widget.accountName,
            tx.id,
          );
          await loadData();
        }
        break;
    }
  }

  Future<void> _addTransactionToCart(Transaction tx) async {
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
      accountName: widget.accountName,
    );
    final next = [newItem, ...existing];
    await UserPrefService.setShoppingCartItems(
      accountName: widget.accountName,
      items: next.take(30).toList(growable: false),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('장바구니에 추가했습니다.')));
  }
}
