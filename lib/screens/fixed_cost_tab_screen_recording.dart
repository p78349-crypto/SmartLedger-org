// ignore_for_file: invalid_use_of_protected_member
part of 'fixed_cost_tab_screen.dart';

/// 고정비용 → 거래 기록 변환 및 UI 헬퍼
extension FixedCostTabTransactionRecording on _FixedCostTabScreenState {
  DateTime _suggestPaymentDate(FixedCost cost) {
    final now = DateTime.now();
    if (cost.dueDay == null) {
      return DateFormatter.stripTime(now);
    }
    final lastDay = DateUtils.getDaysInMonth(now.year, now.month);
    final targetDay = cost.dueDay!.clamp(1, lastDay).toInt();
    final candidate = DateTime(now.year, now.month, targetDay);
    return DateFormatter.stripTime(candidate);
  }

  List<Transaction> _findDuplicateTransactions(
    List<Transaction> transactions,
    FixedCost cost,
    DateTime targetDate,
  ) {
    return transactions.where((tx) {
      final sameDay = DateFormatter.isSameDay(tx.date, targetDate);
      final sameAmount = (tx.amount - cost.amount).abs() < 0.01;
      return tx.type == TransactionType.expense &&
          sameDay &&
          sameAmount &&
          tx.description.trim() == cost.name.trim();
    }).toList();
  }

  Future<void> _recordCostAsTransaction(FixedCost cost) async {
    final transactionService = TransactionService();
    await transactionService.loadTransactions();

    final targetDate = _suggestPaymentDate(cost);
    final existingTransactions = transactionService.getTransactions(
      widget.accountName,
    );
    final duplicates = _findDuplicateTransactions(
      existingTransactions,
      cost,
      targetDate,
    );

    final amountLabel = CurrencyFormatter.format(cost.amount);
    final dateLabel = DateFormats.yMd.format(targetDate);

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('고정비용을 지출로 기록할까요?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$dateLabel에 ${cost.name}을(를) 지출로 반영합니다.'),
            const SizedBox(height: 12),
            Text('금액: $amountLabel'),
            Text('결제 수단: ${cost.paymentMethod}'),
            if (duplicates.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '⚠️ 동일한 금액/이름의 지출이 이미 ${duplicates.length}건 존재합니다. '
                '중복 기록이 필요하지 않은지 확인하세요.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if ((cost.memo ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('메모: ${cost.memo}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('기록'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    final memoBuffer = StringBuffer('[고정비 자동기록]');
    final trimmedMemo = cost.memo?.trim();
    if (trimmedMemo != null && trimmedMemo.isNotEmpty) {
      memoBuffer.write(' ');
      memoBuffer.write(trimmedMemo);
    }

    final transaction = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.expense,
      description: cost.name,
      amount: cost.amount,
      date: targetDate,
      unitPrice: cost.amount,
      paymentMethod: cost.paymentMethod,
      memo: memoBuffer.toString(),
    );

    await transactionService.addTransaction(widget.accountName, transaction);
    await RecentInputService.saveValue(_paymentPrefsKey, cost.paymentMethod);
    if (trimmedMemo != null && trimmedMemo.isNotEmpty) {
      await RecentInputService.saveValue(_memoPrefsKey, trimmedMemo);
    }

    if (!mounted) return;
    SnackbarUtils.showSuccess(
      context,
      '지출이 기록되었습니다. 필요하면 거래 내역에서 카테고리를 정리하세요.',
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
