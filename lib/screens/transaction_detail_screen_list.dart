// ignore_for_file: invalid_use_of_protected_member

part of 'transaction_detail_screen.dart';

/// Transaction list with inline refund display.
extension TransactionDetailList on _TransactionDetailScreenState {
  List<Widget> _buildTransactionListWithRefunds(
    List<Transaction> transactions,
    ThemeData theme,
  ) {
    final widgets = <Widget>[];
    final originalTransactions = transactions
        .where((tx) => !tx.isRefund)
        .toList();

    for (final tx in originalTransactions) {
      final refunds = TransactionService().getRefundsForTransaction(
        widget.accountName,
        tx.id,
      );
      final hasRefund = refunds.isNotEmpty;
      final refundedQty = refunds.fold<int>(0, (s, r) => s + r.quantity);

      final netExpense = _selectedType == TransactionType.expense
          ? getNetExpense(tx, refunds)
          : 0;
      final showNetExpense =
          _selectedType == TransactionType.expense &&
          hasRefund &&
          netExpense > 0;

      widgets.add(
        _buildOriginalTxTile(
          tx,
          theme,
          hasRefund,
          refundedQty,
          showNetExpense,
          netExpense,
        ),
      );

      for (final refund in refunds) {
        widgets.add(_buildRefundTile(refund, theme));
      }
    }

    return widgets;
  }

  Widget _buildOriginalTxTile(
    Transaction tx,
    ThemeData theme,
    bool hasRefund,
    int refundedQty,
    bool showNetExpense,
    num netExpense,
  ) {
    return ListTile(
      onTap: () => _showTransactionActionDialog(tx),
      leading: CircleAvatar(
        backgroundColor: hasRefund
            ? theme.colorScheme.onSurfaceVariant.withAlpha(51)
            : _typeColor(_selectedType, theme).withAlpha(51),
        child: Icon(
          IconCatalog.receipt,
          color: hasRefund
              ? theme.colorScheme.onSurfaceVariant
              : _typeColor(_selectedType, theme),
          size: 20,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tx.description,
            style: TextStyle(
              decoration: hasRefund ? TextDecoration.lineThrough : null,
              color: hasRefund ? theme.colorScheme.onSurfaceVariant : null,
            ),
          ),
          if (showNetExpense || hasRefund)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (showNetExpense)
                    _badge(
                      CurrencyFormatter.format(netExpense),
                      Colors.red[400]!,
                      Colors.white,
                      theme,
                      bold: true,
                    ),
                  if (hasRefund)
                    _outlineBadge(
                      '환불은 지출 예산에 포함',
                      Colors.green,
                      Colors.green[700]!,
                      theme,
                    ),
                  if (refundedQty > 0 && refundedQty < tx.quantity)
                    _outlineBadge(
                      '부분 반품: $refundedQty/${tx.quantity}',
                      Colors.orange,
                      Colors.orange[800]!,
                      theme,
                    ),
                ],
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormatter.defaultDate.format(tx.date)}'
            '${tx.store != null && tx.store!.isNotEmpty ? ' · ${tx.store}' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (tx.memo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(tx.memo, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
      trailing: Text(
        CurrencyFormatter.format(tx.amount),
        style: theme.textTheme.titleMedium?.copyWith(
          color: hasRefund
              ? theme.colorScheme.onSurfaceVariant
              : _typeColor(_selectedType, theme),
          fontWeight: FontWeight.bold,
          decoration: hasRefund ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }

  Widget _buildRefundTile(Transaction refund, ThemeData theme) {
    final destination = refundDestinationLabel(refund);
    return Container(
      margin: const EdgeInsets.only(left: 56),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.green.withAlpha(128), width: 2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 12, right: 16),
        leading: Icon(IconCatalog.refund, size: 20, color: Colors.green[700]),
        title: Text(
          '환불 → $destination',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.green[700],
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormatter.defaultDate.format(refund.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green[600],
                fontSize: 11,
              ),
            ),
            if (refund.memo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  refund.memo,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green[700],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                '환불수단: ${refund.paymentMethod}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green[600],
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
        trailing: Text(
          CurrencyFormatter.format(refund.amount),
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- Badge helpers --------------------------------------------------------

  Widget _badge(
    String text,
    Color bg,
    Color fg,
    ThemeData theme, {
    bool bold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: fg,
          fontWeight: bold ? FontWeight.bold : null,
        ),
      ),
    );
  }

  Widget _outlineBadge(String text, Color bg, Color fg, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withAlpha(51),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 10,
          color: fg,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
