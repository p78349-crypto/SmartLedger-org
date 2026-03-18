// ignore_for_file: invalid_use_of_protected_member

part of 'transaction_detail_screen.dart';

/// Refund processing – action buttons, backend logic, and form widgets.
extension TransactionDetailRefundProcess on _TransactionDetailScreenState {
  Widget _refundActionButtons(
    BuildContext ctx,
    Transaction tx,
    int refundQuantity,
    TextEditingController textController,
    TextEditingController memoController,
    TextEditingController refundMethodController,
    String refundChannel,
    String selectedAccount,
  ) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: () => _processRefund(
              ctx,
              tx,
              refundQuantity,
              textController,
              memoController,
              refundMethodController,
              refundChannel,
              selectedAccount,
            ),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('반품 처리'),
          ),
        ),
      ],
    );
  }

  Future<void> _processRefund(
    BuildContext ctx,
    Transaction tx,
    int refundQuantity,
    TextEditingController textController,
    TextEditingController memoController,
    TextEditingController refundMethodController,
    String refundChannel,
    String selectedAccount,
  ) async {
    final refundAmount =
        double.tryParse(textController.text.replaceAll(',', '')) ?? tx.amount;
    final service = TransactionService();
    // 1. 원본 거래 수량/금액 차감
    final remainingQty = tx.quantity - refundQuantity;
    if (remainingQty > 0) {
      final perUnit = tx.unitPrice > 0
          ? tx.unitPrice
          : (tx.amount / tx.quantity);
      final remainingAmount = perUnit * remainingQty;
      final refundNote =
          '$refundQuantity개 반품됨 (${refundAmount.toStringAsFixed(0)}원)';
      final updatedMemo = tx.memo.isEmpty
          ? refundNote
          : '$tx.memo\n[$refundNote]';
      final updatedTx = Transaction(
        id: tx.id,
        type: tx.type,
        description: tx.description,
        amount: remainingAmount,
        date: tx.date,
        quantity: remainingQty,
        unitPrice: tx.unitPrice,
        paymentMethod: tx.paymentMethod,
        memo: updatedMemo,
        store: tx.store,
        savingsAllocation: tx.savingsAllocation,
        isRefund: tx.isRefund,
        originalTransactionId: tx.originalTransactionId,
        mainCategory: tx.mainCategory,
        subCategory: tx.subCategory,
      );
      await service.updateTransaction(widget.accountName, updatedTx);
    } else {
      await service.deleteTransaction(widget.accountName, tx.id);
    }
    // 2. 환불 처리
    if (selectedAccount == '지출 예산') {
      await _refundToBudget(
        tx,
        refundAmount,
        refundQuantity,
        memoController,
        refundMethodController,
        refundChannel,
        service,
      );
    } else {
      await _refundToOther(
        tx,
        refundAmount,
        refundQuantity,
        memoController,
        refundMethodController,
        refundChannel,
        selectedAccount,
        service,
      );
    }

    if (ctx.mounted) {
      Navigator.pop(ctx);
      Navigator.pop(ctx, true);
      final processedMessage =
          '반품이 처리되었습니다 (환불: '
          '${refundAmount.toStringAsFixed(0)}원 → $selectedAccount)';
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(SnackBar(content: Text(processedMessage)));
    }
  }

  Future<void> _refundToBudget(
    Transaction tx,
    double refundAmount,
    int refundQuantity,
    TextEditingController memoCtrl,
    TextEditingController methodCtrl,
    String refundChannel,
    TransactionService service,
  ) async {
    final budgetService = BudgetService();
    final currentBudget = budgetService.getBudget(widget.accountName);
    await budgetService.setBudget(
      widget.accountName,
      currentBudget + refundAmount,
    );

    final refundAmountText = refundAmount.toStringAsFixed(0);
    final origDate = DateFormatter.defaultDate.format(tx.date);
    final autoMemo =
        '${tx.description} $refundQuantity개 환불받음 '
        '$refundAmountText원 → 지출예산\n';
    final memoSuffix = '\n원구매일: $origDate, 원결제수단: ${tx.paymentMethod}';
    final refundTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.refund,
      description: '${tx.description} (반품환불)',
      amount: refundAmount,
      date: DateTime.now(),
      quantity: refundQuantity,
      unitPrice: tx.unitPrice,
      paymentMethod: _resolvedPaymentMethod(methodCtrl, refundChannel),
      memo: memoCtrl.text.isEmpty ? autoMemo : '${memoCtrl.text}$memoSuffix',
      store: tx.store,
      isRefund: true,
      originalTransactionId: tx.id,
      mainCategory: tx.mainCategory,
      subCategory: tx.subCategory,
    );
    await service.addTransaction(widget.accountName, refundTx);
    await RecentInputService.savePaymentMethod(refundTx.paymentMethod);
  }

  Future<void> _refundToOther(
    Transaction tx,
    double refundAmount,
    int refundQuantity,
    TextEditingController memoCtrl,
    TextEditingController methodCtrl,
    String refundChannel,
    String selectedAccount,
    TransactionService service,
  ) async {
    SavingsAllocation? allocation;
    if (selectedAccount == '자산') {
      allocation = SavingsAllocation.assetIncrease;
    }

    final refundAmountText = refundAmount.toStringAsFixed(0);
    final origDate = DateFormatter.defaultDate.format(tx.date);
    final refundNote = '$refundAmountText원 → $selectedAccount';
    final refundDetails = '\n원구매일: $origDate, 원결제수단: ${tx.paymentMethod}';
    final autoMemo =
        '${tx.description} $refundQuantity개 환불받음 '
        '$refundNote$refundDetails';
    final refundTx = Transaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: TransactionType.refund,
      description: '${tx.description} (반품환불)',
      amount: refundAmount,
      date: DateTime.now(),
      quantity: refundQuantity,
      unitPrice: tx.unitPrice,
      paymentMethod: _resolvedPaymentMethod(methodCtrl, refundChannel),
      memo: memoCtrl.text.isEmpty
          ? autoMemo
          : '${memoCtrl.text}\n원구매일: $origDate, '
                '원결제수단: ${tx.paymentMethod}',
      savingsAllocation: allocation,
      isRefund: true,
      originalTransactionId: tx.id,
      mainCategory: tx.mainCategory,
      subCategory: tx.subCategory,
    );
    await service.addTransaction(widget.accountName, refundTx);
    await RecentInputService.savePaymentMethod(refundTx.paymentMethod);
  }

  String _resolvedPaymentMethod(
    TextEditingController ctrl,
    String refundChannel,
  ) {
    return ctrl.text.trim().isEmpty
        ? (refundChannel == '카드' ? '카드' : refundChannel)
        : ctrl.text.trim();
  }

  // --- Refund form widgets --------------------------------------------------

  Widget _refundChannelSelector(
    BuildContext ctx,
    String refundChannel,
    void Function(String) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '환불 수단을 선택하세요',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ...['계좌이체', '카드', '현금', '기타'].map((option) {
          final sel = refundChannel == option;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              sel ? IconCatalog.radioButtonChecked : IconCatalog.radioButtonOff,
              color: sel ? Theme.of(ctx).colorScheme.primary : null,
            ),
            title: Text(option),
            onTap: () => onSelect(option),
          );
        }),
      ],
    );
  }

  Widget _refundMethodAutocomplete(
    String refundChannel,
    TextEditingController ctrl,
    List<String> recentMethods,
  ) => Autocomplete<String>(
    initialValue: TextEditingValue(text: ctrl.text),
    optionsBuilder: (tv) {
      final input = tv.text.toLowerCase();
      return input.isEmpty
          ? recentMethods
          : recentMethods.where((p) => p.toLowerCase().contains(input));
    },
    onSelected: (selection) => ctrl.text = selection,
    fieldViewBuilder: (ctx, controller, focusNode, onSubmitted) => TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: refundChannel == '카드' ? '카드사/카드명' : '환불 수단 상세',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (v) => ctrl.text = v,
    ),
  );

  Widget _refundAccountSelector(
    BuildContext ctx,
    String selectedAccount,
    void Function(String) onSelect,
  ) {
    final theme = Theme.of(ctx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '환불금을 어디로 받을까요?',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        ...['지출 예산', '비상금', '자산'].map((option) {
          final sel = selectedAccount == option;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(
              sel ? IconCatalog.radioButtonChecked : IconCatalog.radioButtonOff,
              color: sel
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            title: Text(option),
            onTap: () => onSelect(option),
          );
        }),
      ],
    );
  }
}
