// ignore_for_file: invalid_use_of_protected_member

part of 'transaction_detail_screen.dart';

/// Bottom-sheet action dialog (edit / refund / move / delete).
extension TransactionDetailActions on _TransactionDetailScreenState {
  Future<void> _showTransactionActionDialog(Transaction tx) async {
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
              leading:
                  Icon(IconCatalog.edit, color: theme.colorScheme.primary),
              title: const Text('편집'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            if (tx.type == TransactionType.expense && !tx.isRefund)
              ListTile(
                leading: const Icon(IconCatalog.refund, color: Colors.green),
                title: const Text('반품'),
                onTap: () => Navigator.pop(context, 'refund'),
              ),
            if (tx.type == TransactionType.income)
              ListTile(
                leading:
                    const Icon(IconCatalog.moveDown, color: Colors.blue),
                title: const Text('이동'),
                subtitle: const Text('수입을 다른 곳으로 이동'),
                onTap: () => Navigator.pop(context, 'move'),
              ),
            ListTile(
              leading: const Icon(IconCatalog.delete, color: Colors.red),
              title: const Text('삭제'),
              onTap: () async {
                Navigator.pop(context);
                final messenger = ScaffoldMessenger.of(context);
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
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('삭제'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  if (!mounted) return;
                  await TransactionService().deleteTransaction(
                    widget.accountName,
                    tx.id,
                  );
                  if (!mounted) return;
                  setState(() {});
                  messenger.showSnackBar(
                    const SnackBar(content: Text('거래가 삭제되었습니다')),
                  );
                }
              },
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
            builder: (_) => TransactionAddDetailedScreen(
              accountName: widget.accountName,
              initialTransaction: tx,
            ),
          ),
        );
        if (mounted) setState(() {});
        break;
      case 'refund':
        await _showRefundDialog(tx);
        break;
      case 'move':
        await _showMoveIncomeDialog(tx);
        break;
      default:
        break;
    }
  }
}
