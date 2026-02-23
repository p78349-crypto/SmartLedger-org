part of 'transaction_add_screen.dart';

extension TransactionAddScreenDialogs on _NO1FormState {
  Future<void> _showRecentInputPicker({
    required BuildContext context,
    required List<String> items,
    required ValueChanged<String> onSelected,
    required String title,
  }) async {
    if (items.isEmpty) {
      SnackbarUtils.showInfo(context, '저장된 항목이 없습니다.');
      return;
    }

    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(title),
                    trailing: IconButton(
                      icon: const Icon(IconCatalog.close),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final value = items[index];
                        return ListTile(
                          title: Text(value),
                          onTap: () => Navigator.of(sheetContext).pop(value),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      onSelected(selected);
    }
  }

  Future<bool> _maybeConfirmPriceRise({
    required String accountName,
    required String description,
    required double currentUnitPrice,
    required String? excludeTransactionId,
  }) async {
    final normalized = _normalizeItemKey(description);
    if (normalized.isEmpty || currentUnitPrice <= 0) {
      return true;
    }

    final service = TransactionService();
    await service.loadTransactions();
    if (!mounted) return false;

    final all = service.getTransactions(accountName);
    final candidates = <Transaction>[];
    for (final t in all) {
      if (excludeTransactionId != null && t.id == excludeTransactionId) {
        continue;
      }
      if (t.type != TransactionType.expense) continue;
      if (t.isRefund) continue;
      if (_normalizeItemKey(t.description) != normalized) continue;
      candidates.add(t);
    }

    candidates.sort((a, b) => b.date.compareTo(a.date));
    final recent = candidates.take(_priceRiseLookbackCount).toList();
    final historyUnitPrices = <double>[];
    for (final t in recent) {
      if (t.unitPrice > 0) {
        historyUnitPrices.add(t.unitPrice);
        continue;
      }
      final qty = t.quantity;
      if (qty > 0 && t.amount > 0) {
        historyUnitPrices.add(t.amount / qty);
      }
    }

    if (historyUnitPrices.length < _priceRiseMinSamples) {
      return true;
    }

    final baseline = _median(historyUnitPrices);
    if (baseline <= 0) return true;

    final delta = currentUnitPrice - baseline;
    final pct = delta / baseline;
    final isRise =
        pct >= _priceRisePctThreshold && delta >= _priceRiseMinDeltaWon;
    if (!isRise) return true;

    final pctText = (pct * 100).toStringAsFixed(0);
    final deltaText = _formatWon(delta);
    final baselineText = _formatWon(baseline);
    final currentText = _formatWon(currentUnitPrice);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('가격 상승 감지'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('품목: $description'),
              Text('최근 ${historyUnitPrices.length}건 기준 단가(중앙값):'),
              Text('$baselineText원'),
              Text('현재 단가: $currentText원'),
              Text('변화: +$deltaText원 (+$pctText%)'),
              const SizedBox(height: 8),
              const Text('계속 저장할까요?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('계속 저장'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<bool> _confirmBeforeSaveIfNeeded({
    required bool skipConfirm,
    required String desc,
    required int qty,
    required double unit,
    required double amount,
    required double? cardChargedAmount,
    required String payment,
    required String memo,
    required bool isExpense,
    required bool isSavings,
    required String effectiveMainCategory,
    required String? effectiveSubCategory,
  }) async {
    if (!widget.confirmBeforeSave || skipConfirm) return true;

    final isShoppingCategory = _isShoppingCategory(
      effectiveMainCategory,
      effectiveSubCategory,
    );
    final canShowShoppingCompare = isExpense && isShoppingCategory;
    final Future<String?>? shoppingCompareFuture = canShowShoppingCompare
        ? _buildShoppingSpendComparisonTooltip(
            accountName: widget.accountName,
          )
        : null;

    if (!mounted) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final main = effectiveMainCategory.trim().isEmpty
            ? _defaultCategory
            : effectiveMainCategory;
        final categoryText = '$main / -';
        final qtyText = isExpense ? '$qty개' : '-';
        final unitDecimals = unit == unit.roundToDouble() ? 0 : 2;
        final unitFormatted = unit.toStringAsFixed(unitDecimals);
        final unitText = isExpense ? '$unitFormatted원' : '-';
        final amountDecimals = amount == amount.roundToDouble() ? 0 : 2;
        final amountFormatted = amount.toStringAsFixed(amountDecimals);
        final amountText = '$amountFormatted원';
        final cardText = (cardChargedAmount == null)
            ? '-'
            : '${cardChargedAmount.toStringAsFixed(0)}원';

        return AlertDialog(
          title: const Text('저장 전에 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('상품명: $desc'),
              Text('수량: $qtyText'),
              Text('단가: $unitText'),
              Text('금액: $amountText'),
              if (isExpense) Text('카드결제금액: $cardText'),
              Text('카테고리: $categoryText'),
              if (!isSavings) Text('결제수단: $payment'),
              if (memo.isNotEmpty) Text('메모: $memo'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            if (shoppingCompareFuture == null)
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('저장'),
              )
            else
              FutureBuilder<String?>(
                future: shoppingCompareFuture,
                builder: (context, snapshot) {
                  final message = switch (snapshot.connectionState) {
                    ConnectionState.waiting => '비교 계산 중…',
                    _ => snapshot.data,
                  };

                  final button = FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('저장'),
                  );

                  if (message == null || message.trim().isEmpty) {
                    return button;
                  }
                  return Tooltip(message: message, child: button);
                },
              ),
          ],
        );
      },
    );

    if (!mounted) return false;
    return confirmed == true;
  }
}
