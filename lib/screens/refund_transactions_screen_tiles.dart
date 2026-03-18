part of 'refund_transactions_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension RefundTiles on _RefundTransactionsScreenState {
  Widget buildRefundTile(
    ThemeData theme,
    Transaction tx, {
    required bool showDate,
  }) {
    const txColor = RefundUtils.color;
    final memoText = tx.memo.trim();
    final storeText = tx.store?.trim() ?? '';
    final dateText = DateFormat('yyyy-MM-dd').format(tx.date);
    final qty = tx.quantity;
    final unit = tx.unitPrice;
    final cardCharged = tx.cardChargedAmount;

    final subtitleLines = <String>[
      if (showDate) '일자: $dateText',
      '카테고리: ${_categoryText(tx)}',
      '결제: ${tx.paymentMethod}',
      if (storeText.isNotEmpty) '구매자/거래처: $storeText',
      if (qty != 0 || unit != 0)
        '수량/단가: ${_numberFormat.format(qty)} × ${_numberFormat.format(unit)}원',
      if (cardCharged != null) '카드금액: ${_numberFormat.format(cardCharged)}원',
      if (memoText.isNotEmpty) '메모: $memoText',
    ];

    final titleText = tx.description.trim().isEmpty ? '(미입력)' : tx.description;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: txColor.withValues(alpha: 0.2),
        child: const Icon(Icons.replay, color: RefundUtils.color),
      ),
      title: Text(
        titleText,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitleLines.join('\n'),
        style: theme.textTheme.bodySmall,
      ),
      isThreeLine: subtitleLines.length >= 2,
      trailing: Text(
        '⊕${_numberFormat.format(tx.amount)}원',
        style: const TextStyle(
          color: RefundUtils.color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      onTap: () => showTransactionActionSheet(tx),
    );
  }

  Widget buildLandscapeRow(
    ThemeData theme,
    Transaction tx, {
    required bool queryActive,
  }) {
    final categoryText = _categoryText(tx);
    final memoText = tx.memo.trim().isEmpty ? '-' : tx.memo.trim();
    final storeText = tx.store?.trim() ?? '';
    final memoColText = storeText.isEmpty
        ? memoText
        : (memoText == '-' ? storeText : '$storeText | $memoText');

    final cardCharged = tx.cardChargedAmount;
    final cardText = cardCharged == null
        ? '-'
        : '${_numberFormat.format(cardCharged)}원';

    final dateText = DateFormat('yyyy-MM-dd').format(tx.date);
    final qtyText = _numberFormat.format(tx.quantity);
    final unitText = '${_numberFormat.format(tx.unitPrice)}원';

    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Row(
        children: [
          if (queryActive) ...[
            Expanded(
              flex: 2,
              child: Text(
                dateText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 4,
            child: Text(
              tx.description.trim().isEmpty ? '(미입력)' : tx.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              categoryText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              tx.paymentMethod,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              qtyText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              unitText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              memoColText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '⊕${_numberFormat.format(tx.amount)}원',
            style: const TextStyle(
              color: RefundUtils.color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            cardText,
            style: const TextStyle(fontSize: 12, color: RefundUtils.color),
          ),
        ],
      ),
      onTap: () => showTransactionActionSheet(tx),
    );
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
              leading: Icon(IconCatalog.edit, color: theme.colorScheme.primary),
              title: const Text('편집'),
              onTap: () => Navigator.pop(context, 'edit'),
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
        await _loadData();
        break;
      case 'delete':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('반품 삭제'),
            content: const Text('이 반품 내역을 삭제하시겠습니까?'),
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
          await _loadData();
        }
        break;
    }
  }
}
