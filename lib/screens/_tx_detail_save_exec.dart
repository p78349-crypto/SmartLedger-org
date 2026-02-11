part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Save-confirm dialog and post-save execution (add / update, post-actions).
extension TxDetailSaveExec on _TransactionAddDetailedFormState {
  Future<bool?> _showSaveConfirmDialog({
    required String desc,
    required int qty,
    required double unit,
    required double amount,
    required double? cardChargedAmount,
    required String effectiveMainCategory,
    required String payment,
    required String memo,
    required bool isExpense,
    required bool isSavings,
  }) async {
    final isShoppingCategory = _isShoppingCategory(
      effectiveMainCategory,
      _selectedSubCategory,
    );
    final canShowShoppingCompare = isExpense && isShoppingCategory;
    final Future<String?>? shoppingCompareFuture = canShowShoppingCompare
        ? _buildShoppingSpendComparisonTooltip(
            accountName: widget.accountName,
          )
        : null;

    if (!mounted) return null;

    return showDialog<bool>(
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
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            if (shoppingCompareFuture == null)
              FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
  }

  /// Executes add / update and performs all post-save side-effects.
  Future<void> _commitAndPostProcess(
    Transaction transaction,
    NavigatorState navigator,
  ) async {
    final existing = _isEditing ? widget.initialTransaction : null;
    final isExpense = transaction.type == TransactionType.expense;
    final isSavings = transaction.type == TransactionType.savings;
    final unitStr = _unitController.text.trim();

    final service = TransactionService();
    try {
      if (existing == null) {
        await service.addTransaction(widget.accountName, transaction);

        if (_addToShoppingList) {
          await _addToShoppingCart(transaction);
        }

        if (transaction.mainCategory !=
            DetailedCategoryDefinitions.defaultCategory) {
          unawaited(
            CategoryUsageService.increment(
              main: transaction.mainCategory,
              sub: transaction.subCategory,
              detail: transaction.detailCategory,
            ),
          );
          unawaited(
            RecentInputService.saveCategory(
              CategoryUsageService.labelFor(
                main: transaction.mainCategory,
                sub: transaction.subCategory,
                detail: transaction.detailCategory,
              ),
            ),
          );
        }

        final isFood =
            transaction.mainCategory == '식품·음료비' ||
            transaction.mainCategory == '식비' ||
            transaction.mainCategory == 'Food';
        if (isExpense && isFood && _expiryDate != null) {
          unawaited(
            ConsumableInventoryService.instance.addItem(
              name: transaction.description,
              purchaseDate: _transactionDate,
              expiryDate: _expiryDate,
              currentStock: transaction.quantity.toDouble(),
              unit: unitStr.isNotEmpty ? unitStr : '개',
              price: transaction.amount,
            ),
          );
        }

        if (_selectedType == TransactionType.income && !isSavings) {
          if (!mounted) return;
          final shouldDistribute = await _showAssetAllocationDialog(
            transaction,
          );
          if (shouldDistribute == null) return;
          if (shouldDistribute) {
            if (!mounted) return;
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => IncomeSplitScreen(
                  accountName: widget.accountName,
                  initialIncomeAmount: transaction.amount,
                ),
              ),
            );
          } else {
            await _addToCashAsset(transaction);
          }
        }
      } else {
        final updated = await service.updateTransaction(
          widget.accountName,
          transaction,
        );
        if (!updated) {
          if (!mounted) return;
          SnackbarUtils.showError(context, '거래 수정에 실패했습니다. 다시 시도하세요');
          return;
        }

        if (transaction.mainCategory != _defaultCategory) {
          unawaited(
            CategoryUsageService.increment(
              main: transaction.mainCategory,
              sub: transaction.subCategory,
            ),
          );
          unawaited(
            RecentInputService.saveCategory(
              CategoryUsageService.labelFor(
                main: transaction.mainCategory,
                sub: transaction.subCategory,
              ),
            ),
          );
        }
      }

      final baseMessage = existing == null ? '거래가 저장되었습니다' : '거래가 수정되었습니다';
      final detail =
          isSavings ? ' (${_savingsAllocation.snackBarDetail})' : '';
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '$baseMessage$detail');
      await _clearDraft();

      if (widget.learnCategoryHintFromDescription &&
          transaction.mainCategory != _defaultCategory) {
        unawaited(
          UserPrefService.setShoppingCategoryHint(
            accountName: widget.accountName,
            keyword: transaction.description,
            hint: CategoryHint(
              mainCategory: transaction.mainCategory,
              subCategory: transaction.subCategory,
              detailCategory: transaction.detailCategory,
            ),
          ),
        );
      }

      final result = TransactionAddResult(
        saved: true,
        paymentMethod: transaction.paymentMethod,
        memo: transaction.memo,
        mainCategory: transaction.mainCategory,
        subCategory: transaction.subCategory,
      );

      if (existing != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) navigator.pop(result);
        });
      } else {
        if (widget.closeAfterSave) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) navigator.pop(result);
          });
          return;
        }
        if (!mounted) return;
        _didSaveAtLeastOnce = true;
        _resetForNextEntry();
      }

      _initialSnapshot = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _captureInitialSnapshotIfNeeded();
      });
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, '거래 저장 중 오류: ${e.toString()}');
    }
  }

}
