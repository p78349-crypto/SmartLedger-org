// ignore_for_file: invalid_use_of_protected_member

part of 'transaction_detail_screen.dart';

/// Move-income dialog.
extension TransactionDetailMove on _TransactionDetailScreenState {
  Future<void> _showMoveIncomeDialog(Transaction tx) async {
    final theme = Theme.of(context);
    final String? selectedDestination = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('수입 이동'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${CurrencyFormatter.format(tx.amount)}을(를) 어디로 이동하시겠습니까?'),
            const SizedBox(height: 16),
            ...[
              (
                title: '지출 예산',
                subtitle: '이번 달 지출 예산으로 사용',
                value: 'expense',
                isSelected: tx.savingsAllocation == SavingsAllocation.expense,
              ),
              (
                title: '비상금',
                subtitle: '비상금으로 보관',
                value: 'emergency',
                isSelected: tx.savingsAllocation == null,
              ),
              (
                title: '자산',
                subtitle: '자산으로 저축',
                value: 'asset',
                isSelected:
                    tx.savingsAllocation == SavingsAllocation.assetIncrease,
              ),
            ].map(
              (option) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  option.isSelected
                      ? IconCatalog.radioButtonChecked
                      : IconCatalog.radioButtonOff,
                  color: option.isSelected ? theme.colorScheme.primary : null,
                ),
                title: Text(option.title),
                subtitle: Text(option.subtitle),
                onTap: () => Navigator.pop(context, option.value),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (!mounted || selectedDestination == null) return;

    String destinationFor(SavingsAllocation? allocation) {
      switch (allocation) {
        case SavingsAllocation.expense:
          return 'expense';
        case SavingsAllocation.assetIncrease:
          return 'asset';
        case null:
          return 'emergency';
      }
    }

    final previousDestination = destinationFor(tx.savingsAllocation);
    if (selectedDestination == previousDestination) return;

    SavingsAllocation? newAllocation;

    final budgetService = BudgetService();
    final emergencyFundService = EmergencyFundService();
    final assetService = AssetService();
    final assetMoveService = AssetMoveService();
    final linkedId = 'income_move_${tx.id}';

    await Future.wait([
      emergencyFundService.ensureLoaded(),
      assetService.loadAssets(),
      assetMoveService.loadMoves(),
    ]);

    // 1) Revert previous side-effects.
    await _revertMoveSideEffects(
      previousDestination,
      tx,
      linkedId,
      budgetService: budgetService,
      emergencyFundService: emergencyFundService,
      assetService: assetService,
      assetMoveService: assetMoveService,
    );

    // 2) Apply new destination side-effects.
    newAllocation = await _applyMoveSideEffects(
      selectedDestination,
      tx,
      linkedId,
      budgetService: budgetService,
      emergencyFundService: emergencyFundService,
      assetService: assetService,
      assetMoveService: assetMoveService,
    );

    // Update transaction.
    final updatedTx = Transaction(
      id: tx.id,
      type: tx.type,
      description: tx.description,
      amount: tx.amount,
      date: tx.date,
      quantity: tx.quantity,
      unitPrice: tx.unitPrice,
      paymentMethod: tx.paymentMethod,
      memo: tx.memo,
      store: tx.store,
      savingsAllocation: newAllocation,
      isRefund: tx.isRefund,
      originalTransactionId: tx.originalTransactionId,
      mainCategory: tx.mainCategory,
      subCategory: tx.subCategory,
    );
    await TransactionService().updateTransaction(widget.accountName, updatedTx);

    if (!mounted) return;
    setState(() {});

    final destination = selectedDestination == 'expense'
        ? '지출 예산'
        : selectedDestination == 'asset'
        ? '자산'
        : '비상금';
    final movedMessage =
        '${CurrencyFormatter.format(tx.amount)}이(가) '
        '$destination(으)로 이동되었습니다';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(movedMessage)));
  }

  Future<void> _revertMoveSideEffects(
    String previousDestination,
    Transaction tx,
    String linkedId, {
    required BudgetService budgetService,
    required EmergencyFundService emergencyFundService,
    required AssetService assetService,
    required AssetMoveService assetMoveService,
  }) async {
    if (previousDestination == 'expense') {
      final currentBudget = budgetService.getBudget(widget.accountName);
      await budgetService.setBudget(
        widget.accountName,
        (currentBudget - tx.amount).clamp(0.0, double.infinity).toDouble(),
      );
    } else if (previousDestination == 'emergency') {
      await emergencyFundService.deleteTransaction(
        widget.accountName,
        linkedId,
      );
    } else if (previousDestination == 'asset') {
      final assets = assetService.getAssets(widget.accountName);
      final depositAsset = assets
          .where((a) => a.category == AssetCategory.deposit)
          .cast<Asset?>()
          .firstWhere(
            (a) => a != null && a.name.contains('수입 이동'),
            orElse: () => null,
          );
      if (depositAsset != null) {
        final updated = depositAsset.copyWith(
          amount: (depositAsset.amount - tx.amount)
              .clamp(0.0, double.infinity)
              .toDouble(),
        );
        await assetService.updateAsset(widget.accountName, updated);
      }
      await assetMoveService.removeMove(widget.accountName, linkedId);
    }
  }

  Future<SavingsAllocation?> _applyMoveSideEffects(
    String selectedDestination,
    Transaction tx,
    String linkedId, {
    required BudgetService budgetService,
    required EmergencyFundService emergencyFundService,
    required AssetService assetService,
    required AssetMoveService assetMoveService,
  }) async {
    if (selectedDestination == 'expense') {
      final currentBudget = budgetService.getBudget(widget.accountName);
      await budgetService.setBudget(
        widget.accountName,
        currentBudget + tx.amount,
      );
      return SavingsAllocation.expense;
    }

    if (selectedDestination == 'asset') {
      final assets = assetService.getAssets(widget.accountName);
      Asset? depositAsset;
      for (final a in assets) {
        if (a.category == AssetCategory.deposit && a.name.contains('수입 이동')) {
          depositAsset = a;
          break;
        }
      }
      depositAsset ??= Asset(
        id: 'income_move_deposit',
        name: '수입 이동 예금',
        amount: 0,
        category: AssetCategory.deposit,
        memo: '자동 생성: 수입 이동(자산) 반영용',
        date: DateTime.now(),
      );
      if (!assets.any((a) => a.id == depositAsset!.id)) {
        await assetService.addAsset(widget.accountName, depositAsset);
      }

      final updatedDeposit = depositAsset.copyWith(
        amount: depositAsset.amount + tx.amount,
      );
      await assetService.updateAsset(widget.accountName, updatedDeposit);

      await assetMoveService.upsertMove(
        widget.accountName,
        AssetMove(
          id: linkedId,
          accountName: widget.accountName,
          fromAssetId: 'income',
          toAssetId: depositAsset.id,
          toCategoryName: '수입',
          amount: tx.amount,
          type: AssetMoveType.deposit,
          memo: '수입 이동: ${tx.description}',
          date: tx.date,
          createdAt: DateTime.now(),
        ),
      );
      return SavingsAllocation.assetIncrease;
    }

    // emergency
    await emergencyFundService.upsertTransaction(
      widget.accountName,
      EmergencyTransaction(
        id: linkedId,
        description: '수입 이동: ${tx.description}',
        amount: tx.amount,
        date: tx.date,
      ),
    );
    return null;
  }
}
