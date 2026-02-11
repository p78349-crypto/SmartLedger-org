// ignore_for_file: invalid_use_of_protected_member

part of 'transaction_detail_screen.dart';

/// Refund dialog – form UI.
extension TransactionDetailRefund on _TransactionDetailScreenState {
  Future<void> _showRefundDialog(Transaction tx) async {
    int refundQuantity = 1;
    final maxQuantity = tx.quantity > 0 ? tx.quantity : 1;

    double calcDefaultAmount(int qty) {
      if (tx.unitPrice > 0) return tx.unitPrice * qty;
      if (tx.quantity > 0) return (tx.amount.abs() / tx.quantity) * qty;
      return tx.amount.abs();
    }

    final textController = TextEditingController(
      text: calcDefaultAmount(refundQuantity).toStringAsFixed(0),
    );
    final memoController = TextEditingController(text: tx.memo);
    final refundMethodController = TextEditingController(
      text: tx.paymentMethod,
    );
    final recentPaymentMethods =
        await RecentInputService.loadPaymentMethods();
    if (!mounted) return;
    String refundChannel = '카드';
    final quantityController = TextEditingController(
      text: refundQuantity.toString(),
    );
    String selectedAccount = '지출 예산';

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _refundSheetHandle(context),
                  _refundSheetHeader(context),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${tx.description}을(를) 반품 처리하시겠습니까?'),
                          const SizedBox(height: 16),
                          _refundQuantityRow(
                            tx,
                            maxQuantity,
                            quantityController,
                            textController,
                            calcDefaultAmount,
                            refundQuantity,
                            (qty) {
                              refundQuantity = qty;
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 12),
                          _refundAmountField(textController),
                          const SizedBox(height: 12),
                          _refundMemoField(memoController),
                          const SizedBox(height: 12),
                          _refundChannelSelector(
                            context,
                            refundChannel,
                            (v) => setState(
                              () => refundChannel = v,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (refundChannel == '카드' ||
                              refundChannel == '기타')
                            _refundMethodAutocomplete(
                              refundChannel,
                              refundMethodController,
                              recentPaymentMethods,
                            ),
                          const SizedBox(height: 16),
                          _refundAccountSelector(
                            context,
                            selectedAccount,
                            (v) => setState(
                              () => selectedAccount = v,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _refundActionButtons(
                            context,
                            tx,
                            refundQuantity,
                            textController,
                            memoController,
                            refundMethodController,
                            refundChannel,
                            selectedAccount,
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      textController.dispose();
      memoController.dispose();
      quantityController.dispose();
      refundMethodController.dispose();
    }
  }

  Widget _refundSheetHandle(BuildContext ctx) => Center(
    child: Container(
      width: 40, height: 4,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(ctx).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );

  Widget _refundSheetHeader(BuildContext ctx) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text('반품 처리',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      IconButton(
        icon: const Icon(IconCatalog.close),
        onPressed: () => Navigator.pop(ctx),
      ),
    ],
  );

  Widget _refundQuantityRow(
    Transaction tx,
    int maxQuantity,
    TextEditingController quantityCtrl,
    TextEditingController amountCtrl,
    double Function(int) calcDefaultAmount,
    int refundQuantity,
    void Function(int) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: quantityCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '반품 수량 (최대 $maxQuantity)',
              helperText: '여러 개 중 일부만 반품 시 수정하세요',
              suffixText: '개',
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              final parsed = int.tryParse(value) ?? 1;
              final clamped = parsed.clamp(1, maxQuantity);
              if (clamped != parsed) {
                quantityCtrl.text = clamped.toString();
                quantityCtrl.selection = TextSelection.fromPosition(
                  TextPosition(offset: quantityCtrl.text.length),
                );
              }
              if (tx.unitPrice > 0 || tx.quantity > 0) {
                amountCtrl.text =
                    calcDefaultAmount(clamped).toStringAsFixed(0);
              }
              onChanged(clamped);
            },
          ),
        ),
        const SizedBox(width: 12),
        Text('구매 수량: $maxQuantity개'),
      ],
    );
  }

  Widget _refundAmountField(TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: '환불 금액',
        suffixText: '원',
        helperText: '배송비 등을 제외한 실제 환불 받을 금액을 입력하세요',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _refundMemoField(TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: '메모 (반품 사유)',
        helperText: '반품 사유나 참고 메모를 적어주세요',
        alignLabelWithHint: true,
        border: OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

}
