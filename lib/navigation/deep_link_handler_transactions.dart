part of deep_link_handler;

mixin _DeepLinkHandlerTransactions on _DeepLinkHandlerBase {
  @override
  void _handleAddTransaction(
    NavigatorState navigator,
    AddTransactionAction action,
  ) {
    final validationResult = RouteParamValidator.validate(
      action.isIncome
          ? AppRoutes.transactionAddIncome
          : AppRoutes.transactionAdd,
      action.toParams(),
    );

    if (!validationResult.isValid) {
      _logAndShowError(
        navigator: navigator,
        errorType: 'INVALID_PARAMS',
        route: action.isIncome
            ? AppRoutes.transactionAddIncome
            : AppRoutes.transactionAdd,
        assistant: _detectAssistant(action.toParams()),
        rejectedParams: validationResult.rejected,
      );
      return;
    }

    final resolvedAccountName =
        AssistantRouteCatalog.resolveDefaultAccountName() ??
        (AccountService().accounts.isNotEmpty
            ? AccountService().accounts.first.name
            : null);
    if (resolvedAccountName == null || resolvedAccountName.isEmpty) {
      debugPrint('DeepLinkHandler: No accounts available');
      _logAndShowError(
        navigator: navigator,
        errorType: 'ACCOUNT_REQUIRED',
        route: action.isIncome
            ? AppRoutes.transactionAddIncome
            : AppRoutes.transactionAdd,
        assistant: _detectAssistant(action.toParams()),
      );
      return;
    }

    final now = DateTime.now();
    final type = action.isIncome
        ? TransactionType.income
        : action.isSavings
        ? TransactionType.savings
        : action.isRefund
        ? TransactionType.refund
        : TransactionType.expense;
    final amount = action.amount;
    final quantityRaw = action.quantity;
    final unit = action.unit?.trim() ?? '';
    final unitPriceRaw = action.unitPrice;
    final desc = action.description?.trim();
    var memo = action.memo?.trim() ?? '';
    final paymentMethod = action.paymentMethod?.trim() ?? '';
    final store = action.store?.trim() ?? '';
    final savingsAllocation = action.savingsAllocation;

    if (action.items != null && action.items!.isNotEmpty) {
      final itemsList = action.items!
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (itemsList.isNotEmpty) {
        final itemsText = itemsList.join(', ');
        memo = memo.isEmpty ? '📋 $itemsText' : '$memo\n📋 $itemsText';
      }
    }

    final qty = (quantityRaw != null && quantityRaw > 0)
        ? quantityRaw.round()
        : 1;

    final hasUnitPrice = unitPriceRaw != null && unitPriceRaw > 0;
    final hasQty = quantityRaw != null && quantityRaw > 0;

    Transaction? initialTransaction;
    final hasDesc = desc != null && desc.isNotEmpty;
    if (amount != null || hasDesc || hasUnitPrice || hasQty) {
      final computedAmount =
          amount ?? (hasUnitPrice ? (unitPriceRaw * qty) : 0);
      final computedUnitPrice = hasUnitPrice
          ? unitPriceRaw
          : (qty > 0 ? (computedAmount / qty) : computedAmount);
      initialTransaction = Transaction(
        id: '',
        type: type,
        amount: computedAmount,
        quantity: qty,
        unit: unit.isEmpty ? null : unit,
        unitPrice: computedUnitPrice,
        date: now,
        description: desc ?? '',
        paymentMethod: paymentMethod.isEmpty ? '현금' : paymentMethod,
        memo: memo,
        store: store.isEmpty ? null : store,
        isRefund: action.isRefund,
        savingsAllocation: type == TransactionType.savings
            ? (savingsAllocation ?? SavingsAllocation.assetIncrease)
            : null,
        mainCategory: action.category,
      );
    }

    final routeName = action.isIncome
        ? AppRoutes.transactionAddIncome
        : AppRoutes.transactionAdd;

    void openScreen({required bool autoSubmit}) {
      navigator.pushNamed(
        routeName,
        arguments: TransactionAddArgs(
          accountName: resolvedAccountName,
          initialTransaction: initialTransaction,
          treatAsNew: true,
          closeAfterSave: true,
          autoSubmit: autoSubmit,
          openReceiptScannerOnStart: action.openReceiptScannerOnStart,
        ),
      );
    }

    if (action.autoSubmit) {
      final missingForAuto =
          amount == null || amount <= 0 || desc == null || desc.isEmpty;
      if (missingForAuto) {
        _showSimpleInfoDialog(
          navigator,
          title: '자동 저장 불가',
          message:
              '자동 저장을 위해서는 설명과 금액이 필요합니다.\n'
              '화면을 열어 입력을 계속 진행하세요.',
        );
        openScreen(autoSubmit: false);
        return;
      }

      if (!action.confirmed) {
        final typeText = action.isIncome
            ? '수입'
            : action.isSavings
            ? '저축'
            : action.isRefund
            ? '반품'
            : '지출';
        final categoryText =
            (action.category == null || action.category!.trim().isEmpty)
            ? '미분류'
            : action.category!.trim();
        final amountText = amount.toStringAsFixed(
          amount == amount.roundToDouble() ? 0 : 2,
        );
        final qtyText = qty <= 1 ? '' : qty.toString();
        final unitText = unit.isEmpty ? '' : unit;
        final unitLine = (qtyText.isEmpty && unitText.isEmpty)
            ? ''
            : '$qtyText$unitText';

        showDialog<bool>(
          context: navigator.context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('저장 전에 확인'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('종류: $typeText'),
                  Text('설명: $desc'),
                  Text('금액: $amountText원'),
                  if (unitLine.isNotEmpty) Text('수량: $unitLine'),
                  Text('카테고리: $categoryText'),
                  if (memo.isNotEmpty) Text('메모: $memo'),
                  const SizedBox(height: 8),
                  const Text('이대로 저장할까요?'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('취소'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('저장'),
                ),
              ],
            );
          },
        ).then((confirmed) {
          if (confirmed == true) {
            openScreen(autoSubmit: true);
          }
        });
        return;
      }

      VoiceAssistantAnalytics.logCommand(
        assistant: _detectAssistant(action.toParams()),
        route: action.isIncome
            ? AppRoutes.transactionAddIncome
            : AppRoutes.transactionAdd,
        intent: 'transaction_add',
        success: true,
      );

      openScreen(autoSubmit: true);
      return;
    }

    VoiceAssistantAnalytics.logCommand(
      assistant: _detectAssistant(action.toParams()),
      route: action.isIncome
          ? AppRoutes.transactionAddIncome
          : AppRoutes.transactionAdd,
      intent: 'transaction_add',
      success: true,
    );

    openScreen(autoSubmit: false);
  }
}
