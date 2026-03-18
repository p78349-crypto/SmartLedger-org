part of 'transaction_add_screen.dart';

extension TransactionAddScreenSave on _NO1FormState {
  Future<void> _saveTransaction({bool skipConfirm = false}) async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);

    final desc = _descController.text.trim();
    final isSavings = _selectedType == TransactionType.savings;
    final isExpense = _selectedType == TransactionType.expense;
    final qty = isExpense
        ? int.tryParse(_qtyController.text.isEmpty ? '1' : _qtyController.text)
        : 1;
    final parsedAmountText = _amountController.text.trim();
    final parsedUnitText = _unitPriceController.text.trim();
    final unit = isExpense
        ? TypeConverters.parseCurrency(parsedUnitText)
        : TypeConverters.parseCurrency(parsedAmountText);
    final amount = isExpense
        ? TypeConverters.parseCurrency(parsedAmountText)
        : unit;

    final cardChargedRaw = _cardChargedAmountController.text.trim();
    final cardChargedAmount = (!isExpense || cardChargedRaw.isEmpty)
        ? null
        : TypeConverters.parseCurrency(cardChargedRaw);
    final paymentRaw = _paymentController.text.trim();
    final payment = isSavings
        ? (paymentRaw.isEmpty ? '자동이체' : paymentRaw)
        : paymentRaw;
    final memo = _memoController.text.trim();
    final effectiveMainCategory = _selectedMainCategory;
    // TransactionAddScreen now stores main-category only.
    const String? effectiveSubCategory = null;

    final amountInvalid = amount == null || amount <= 0;
    final cardInvalid =
        isExpense &&
        cardChargedRaw.isNotEmpty &&
        (cardChargedAmount == null || cardChargedAmount <= 0);
    if (desc.isEmpty ||
        qty == null ||
        unit == null ||
        amountInvalid ||
        cardInvalid ||
        (!isSavings && payment.isEmpty)) {
      SnackbarUtils.showWarning(context, '모든 필드를 올바르게 입력하세요');
      return;
    }

    // 최근 상품명/결제수단/메모 저장 (빈값/중복 제외)
    if (_recentInputsEnabled) {
      final prefs = await SharedPreferences.getInstance();
      if (desc.isNotEmpty) {
        final updated = [desc, ..._recentDescriptions.where((e) => e != desc)];
        final clipped = updated.take(_recentInputsMaxCount).toList();
        await prefs.setStringList(_recentDescriptionsKey, clipped);
        _recentDescriptions = clipped;
      }
      if (payment.isNotEmpty) {
        final updated = [
          payment,
          ..._recentPayments.where((e) => e != payment),
        ];
        final clipped = updated.take(_recentInputsMaxCount).toList();
        await prefs.setStringList(_recentPaymentsKey, clipped);
        _recentPayments = clipped;
      }
      if (memo.isNotEmpty) {
        final updated = [memo, ..._recentMemos.where((e) => e != memo)];
        final clipped = updated.take(_recentInputsMaxCount).toList();
        await prefs.setStringList(_recentMemosKey, clipped);
        _recentMemos = clipped;
      }
    }

    if (isExpense) {
      final ok = await _maybeConfirmPriceRise(
        accountName: widget.accountName,
        description: desc,
        currentUnitPrice: unit,
        excludeTransactionId: _isEditing ? widget.initialTransaction?.id : null,
      );
      if (!mounted) return;
      if (!ok) return;
    }

    final shouldProceed = await _confirmBeforeSaveIfNeeded(
      skipConfirm: skipConfirm,
      desc: desc,
      qty: qty,
      unit: unit,
      amount: amount,
      cardChargedAmount: cardChargedAmount,
      payment: payment,
      memo: memo,
      isExpense: isExpense,
      isSavings: isSavings,
      effectiveMainCategory: effectiveMainCategory,
      effectiveSubCategory: effectiveSubCategory,
    );
    if (!shouldProceed) return;

    // 즐겨찾기 자동 저장 차단 (임시 비활성화)

    final existing = _isEditing ? widget.initialTransaction : null;
    final derivedStore = StoreMemoUtils.extractStoreKey(memo);
    final typedStore = _storeController.text.trim();
    final storeForSave = typedStore.isNotEmpty
        ? typedStore
        : (existing?.store?.trim().isNotEmpty ?? false)
        ? existing!.store!.trim()
        : (derivedStore?.trim().isNotEmpty ?? false)
        ? derivedStore!.trim()
        : null;
    final transaction = Transaction(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      description: desc,
      amount: amount,
      cardChargedAmount: cardChargedAmount,
      date: existing?.date ?? _transactionDate,
      quantity: qty,
      unitPrice: unit,
      paymentMethod: payment,
      memo: memo,
      store: storeForSave,
      savingsAllocation: isSavings ? _savingsAllocation : null,
      mainCategory: effectiveMainCategory,
    );

    final service = TransactionService();
    try {
      if (existing == null) {
        await service.addTransaction(widget.accountName, transaction);

        if (effectiveMainCategory != _defaultCategory) {
          unawaited(
            CategoryUsageService.increment(main: effectiveMainCategory),
          );
          unawaited(
            RecentInputService.saveCategory(
              CategoryUsageService.labelFor(main: effectiveMainCategory),
            ),
          );
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

        if (effectiveMainCategory != _defaultCategory) {
          unawaited(
            CategoryUsageService.increment(main: effectiveMainCategory),
          );
          unawaited(
            RecentInputService.saveCategory(
              CategoryUsageService.labelFor(main: effectiveMainCategory),
            ),
          );
        }
      }

      final baseMessage = existing == null ? '거래가 저장되었습니다' : '거래가 수정되었습니다';
      final detail = isSavings ? ' (${_savingsAllocation.snackBarDetail})' : '';
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '$baseMessage$detail');

      if (widget.learnCategoryHintFromDescription &&
          effectiveMainCategory != _defaultCategory) {
        unawaited(
          UserPrefService.setShoppingCategoryHint(
            accountName: widget.accountName,
            keyword: desc,
            hint: CategoryHint(mainCategory: effectiveMainCategory),
          ),
        );
      }

      // 마지막 입력값 중앙 저장소에 저장 (다른 화면에서 참조용)
      unawaited(
        LastInputService.instance.saveTransaction(
          accountName: widget.accountName,
          description: desc,
          amount: amount,
          unitPrice: unit,
          quantity: qty,
          paymentMethod: _paymentController.text,
          memo: _memoController.text,
          mainCategory: _selectedMainCategory,
          subCategory: _selectedSubCategory,
          date: _transactionDate,
        ),
      );

      // 쇼핑 세션 업데이트 (장바구니→지출입력→포인트 흐름용)
      if (isExpense) {
        unawaited(
          LastInputService.instance.updateShoppingSessionFromTransaction(
            accountName: widget.accountName,
            paymentMethod: _paymentController.text,
            memo: _memoController.text,
            mainCategory: _selectedMainCategory,
            subCategory: _selectedSubCategory,
            amount: amount,
          ),
        );
      }

      if (existing != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            navigator.pop(
              TransactionAddResult(
                saved: true,
                paymentMethod: _paymentController.text,
                memo: _memoController.text,
                mainCategory: _selectedMainCategory,
                subCategory: _selectedSubCategory,
              ),
            );
          }
        });
      } else {
        if (widget.closeAfterSave) {
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              navigator.pop(
                TransactionAddResult(
                  saved: true,
                  paymentMethod: _paymentController.text,
                  memo: _memoController.text,
                  mainCategory: _selectedMainCategory,
                  subCategory: _selectedSubCategory,
                ),
              );
            }
          });
          return;
        }
        if (!mounted) return;
        _didSaveAtLeastOnce = true;
        void resetForNextEntry() {
          setState(() {
            _suppressAmountAutoUpdate = true;

            _userPickedCategory = false;

            _descController.clear();
            // _memoController.clear();

            // 타입/날짜/결제수단/메모/카테고리는 유지(터치 최소화)
            _qtyController.text = '1';
            _unitPriceController.clear();
            _amountController.clear();

            _suppressAmountAutoUpdate = false;

            // 다음 입력을 기준으로 "입력값 되돌리기" 스냅샷을 재설정
            _initialSnapshot = null;
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _captureInitialSnapshotIfNeeded();
            _descFocusNode.requestFocus();
          });
        }

        resetForNextEntry();
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
