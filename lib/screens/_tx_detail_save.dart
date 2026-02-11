part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Transaction save – validation, recent-input persistence, confirm dialog,
/// and construction of the [Transaction] object. Delegates execution to
/// [_commitAndPostProcess].
extension TxDetailSave on _TransactionAddDetailedFormState {
  Future<void> _saveTransaction({bool skipConfirm = false}) async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);

    final desc = _descController.text.trim();
    final isSavings = _selectedType == TransactionType.savings;
    final isExpense = _selectedType == TransactionType.expense;
    final qty = isExpense
        ? int.tryParse(
            _qtyController.text.isEmpty ? '1' : _qtyController.text,
          )
        : 1;
    final parsedAmountText =
        _amountController.text.trim().replaceAll(',', '');
    final unit = isExpense
        ? double.tryParse(_unitPriceController.text)
        : double.tryParse(parsedAmountText);
    final amount = isExpense ? double.tryParse(_amountController.text) : unit;

    final cardChargedRaw =
        _cardChargedAmountController.text.trim().replaceAll(',', '');
    final cardChargedAmount = (!isExpense || cardChargedRaw.isEmpty)
        ? null
        : double.tryParse(cardChargedRaw);
    final paymentRaw = _paymentController.text.trim();
    final payment = isSavings
        ? (paymentRaw.isEmpty ? '자동이체' : paymentRaw)
        : paymentRaw;
    final memo = _memoController.text.trim();
    final location = _locationController.text.trim();
    final supplier = _supplierController.text.trim();
    final unitStr = _unitController.text.trim();
    final effectiveMainCategory = _selectedMainCategory;
    final effectiveSubCategory = _selectedSubCategory;
    final effectiveDetailCategory = _selectedDetailCategory;

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

    // 최근 상품명/결제수단/메모 저장
    final prefs = await SharedPreferences.getInstance();
    if (desc.isNotEmpty) {
      final updated = [
        desc,
        ..._recentDescriptions.where((e) => e != desc),
      ];
      final clipped = updated.take(_maxRecentDescriptions).toList();
      await prefs.setStringList(_recentDescriptionsKey, clipped);
      _recentDescriptions = clipped;
    }
    if (payment.isNotEmpty) {
      final updated = [
        payment,
        ..._recentPayments.where((e) => e != payment),
      ];
      await prefs.setStringList(
        _recentPaymentsKey,
        updated.take(_maxRecentPayments).toList(),
      );
      _recentPayments = updated.take(_maxRecentPayments).toList();
    }
    if (memo.isNotEmpty) {
      final updated = [memo, ..._recentMemos.where((e) => e != memo)];
      await prefs.setStringList(
        _recentMemosKey,
        updated.take(_maxRecentMemos).toList(),
      );
      _recentMemos = updated.take(_maxRecentMemos).toList();
    }

    if (isExpense) {
      final ok = await _maybeConfirmPriceRise(
        accountName: widget.accountName,
        description: desc,
        currentUnitPrice: unit,
        excludeTransactionId:
            _isEditing ? widget.initialTransaction?.id : null,
      );
      if (!mounted) return;
      if (!ok) return;
    }

    if (widget.confirmBeforeSave && !skipConfirm) {
      final confirmed = await _showSaveConfirmDialog(
        desc: desc,
        qty: qty,
        unit: unit,
        amount: amount,
        cardChargedAmount: cardChargedAmount,
        effectiveMainCategory: effectiveMainCategory,
        payment: payment,
        memo: memo,
        isExpense: isExpense,
        isSavings: isSavings,
      );
      if (!mounted) return;
      if (confirmed != true) return;
    }

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
      unit: unitStr.isNotEmpty ? unitStr : null,
      unitPrice: unit,
      paymentMethod: payment,
      memo: memo,
      store: storeForSave,
      savingsAllocation: isSavings ? _savingsAllocation : null,
      mainCategory: effectiveMainCategory,
      subCategory: effectiveSubCategory,
      detailCategory: effectiveDetailCategory,
      location: location.isNotEmpty ? location : null,
      supplier: supplier.isNotEmpty ? supplier : null,
      expiryDate: _expiryDate,
    );

    await _commitAndPostProcess(transaction, navigator);
  }

  String? _validatePositiveAmount(String? value, String errorMessage) {
    final raw = value?.trim() ?? '';
    final parsed = double.tryParse(raw.replaceAll(',', ''));
    if (parsed == null || parsed <= 0) {
      return errorMessage;
    }
    return null;
  }

  /// 거래 저장 후 계속 입력 (Shift+Enter)
  Future<void> _saveAndContinue() async {
    await _saveTransaction();
  }

  Future<void> _addToShoppingCart(Transaction transaction) async {
    final currentItems = await UserPrefService.getShoppingCartItems(
      accountName: widget.accountName,
    );
    final now = DateTime.now();
    final newItem = ShoppingCartItem(
      id: 'sc_${now.microsecondsSinceEpoch}',
      name: transaction.description,
      quantity: transaction.quantity,
      unitPrice: transaction.unitPrice,
      memo: transaction.memo,
      createdAt: now,
      updatedAt: now,
    );
    var nextItems = [...currentItems, newItem];
    if (nextItems.length > 10) {
      nextItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      nextItems = nextItems.take(10).toList();
    }
    await UserPrefService.setShoppingCartItems(
      accountName: widget.accountName,
      items: nextItems,
    );
  }

  void _resetForNextEntry() {
    setState(() {
      _suppressAmountAutoUpdate = true;
      _userPickedCategory = false;
      _descController.clear();
      _qtyController.text = '1';
      _unitPriceController.clear();
      _amountController.clear();
      _suppressAmountAutoUpdate = false;
      _initialSnapshot = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureInitialSnapshotIfNeeded();
      _descFocusNode.requestFocus();
    });
  }
}
