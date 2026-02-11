part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Initialization, disposal, and recent-input helpers.
extension TxDetailInit on _TransactionAddDetailedFormState {
  /// Body of [initState] – extracted so the override stays thin.
  void performInit() {
    final initial = widget.initialTransaction;
    _transactionDate = initial?.date ?? DateTime.now();
    if (initial != null) {
      debugPrint(
        '[TransactionAddDetailedForm.initState] '
        '초기값 바인딩: desc=${initial.description}, '
        'qty=${initial.quantity}, unitPrice=${initial.unitPrice}',
      );
      _selectedType = initial.type;
      _descController.text = initial.description;
      _qtyController.text = initial.quantity.toString();
      final unitPrice = initial.unitPrice != 0
          ? initial.unitPrice
          : (initial.quantity > 0
                ? initial.amount / initial.quantity
                : initial.amount);
      if (unitPrice > 0) {
        _unitPriceController.text = unitPrice.toStringAsFixed(
          unitPrice == unitPrice.roundToDouble() ? 0 : 2,
        );
      }
      _amountController.text = initial.amount.toStringAsFixed(
        initial.amount == initial.amount.roundToDouble() ? 0 : 2,
      );
      if (initial.cardChargedAmount != null) {
        final card = initial.cardChargedAmount!;
        _cardChargedAmountController.text = card.toStringAsFixed(
          card == card.roundToDouble() ? 0 : 2,
        );
      }
      _paymentController.text = initial.paymentMethod;
      if (_paymentController.text.isEmpty &&
          widget.initialPaymentMethod != null) {
        _paymentController.text = widget.initialPaymentMethod!;
      }
      _memoController.text = initial.memo;
      if (_memoController.text.isEmpty && widget.initialMemo != null) {
        _memoController.text = widget.initialMemo!;
      }
      _storeController.text = initial.store?.trim() ?? '';
      if (initial.type == TransactionType.savings) {
        _savingsAllocation =
            initial.savingsAllocation ?? SavingsAllocation.assetIncrease;
      }
      _selectedMainCategory = initial.mainCategory;
      _selectedSubCategory = initial.subCategory;
      _selectedDetailCategory = initial.detailCategory;
      _locationController.text = initial.location ?? '';
      _supplierController.text = initial.supplier ?? '';
      _unitController.text = initial.unit ?? '';
      _expiryDate = initial.expiryDate;
    } else {
      _qtyController.text = '1';
      if (widget.initialPaymentMethod != null) {
        _paymentController.text = widget.initialPaymentMethod!;
      }
      if (widget.initialMemo != null) {
        _memoController.text = widget.initialMemo!;
      }
    }
    if (_selectedType == TransactionType.income) {
      if (_isEditing) {
        _showIncomeCategoryOptions =
            _selectedMainCategory !=
            DetailedCategoryDefinitions.defaultCategory;
      } else {
        _applyIncomeDefaultCategory();
        _showIncomeCategoryOptions = true;
      }
    } else {
      _showIncomeCategoryOptions = true;
    }

    if (initial == null) {
      unawaited(_restoreLastCategoryForType(_selectedType));
    }

    unawaited(_loadShoppingCategoryHints());
    unawaited(_loadRecentInputs());
    unawaited(_loadDraftIfRecent());
    unawaited(_loadSortedCategories());
    _qtyController.addListener(_updateAmount);
    _unitPriceController.addListener(_updateAmount);
    if (initial == null) {
      _updateAmount();
    }

    _paymentFocusNode.addListener(() {
      if (_paymentFocusNode.hasFocus) {
        final text = _paymentController.text;
        _paymentController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: text.length,
        );
      }
    });
    _memoFocusNode.addListener(() {
      if (_memoFocusNode.hasFocus) {
        final text = _memoController.text;
        _memoController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: text.length,
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureInitialSnapshotIfNeeded();
    });
  }

  /// Body of [dispose] – extracted so the override stays thin.
  void disposeAll() {
    unawaited(_saveDraft());
    _autoCategoryDebounce?.cancel();
    _descController.dispose();
    _qtyController.dispose();
    _unitPriceController.dispose();
    _amountController.dispose();
    _cardChargedAmountController.dispose();
    _memoController.dispose();
    _storeController.dispose();
    _paymentController.dispose();
    _locationController.dispose();
    _supplierController.dispose();
    _unitController.dispose();

    _expenseUnitPriceFocusNode.dispose();
    _expenseQtyFocusNode.dispose();
    _paymentFocusNode.dispose();
    _amountFocusNode.dispose();
    _storeFocusNode.dispose();
    _memoFocusNode.dispose();
    _locationFocusNode.dispose();
    _supplierFocusNode.dispose();
    _unitFocusNode.dispose();
    _calculatedAmountFocusNode.dispose();
  }

  Future<void> _loadSortedCategories() async {
    final categoryOptions = _categoryOptionsFor(_selectedType);
    final usageCounts = await CategoryUsageService.loadCounts();
    if (!mounted) return;

    final sorted = categoryOptions.keys.toList()
      ..sort((a, b) {
        final ac = CategoryUsageService.countForMain(usageCounts, a);
        final bc = CategoryUsageService.countForMain(usageCounts, b);
        if (ac != bc) return bc.compareTo(ac);
        return a.compareTo(b);
      });

    if (sorted.remove(_defaultCategory)) {
      sorted.insert(0, _defaultCategory);
    }
  }

  Future<void> _loadRecentInputs() async {
    final prefs = await SharedPreferences.getInstance();
    final descriptions =
        prefs.getStringList(_recentDescriptionsKey) ?? const <String>[];
    final payments = prefs.getStringList(_recentPaymentsKey) ?? [];
    final memos = prefs.getStringList(_recentMemosKey) ?? [];

    if (!mounted) return;
    setState(() {
      _recentDescriptions = descriptions
          .take(_maxRecentDescriptions)
          .toList(growable: false);
      _recentPayments = payments
          .take(_maxRecentPayments)
          .toList(growable: false);
      _recentMemos = memos.take(_maxRecentMemos).toList(growable: false);
    });

    if (_paymentController.text.isEmpty && payments.isNotEmpty) {
      _paymentController.text = payments.first;
    }
    if (_memoController.text.isEmpty && memos.isNotEmpty) {
      _memoController.text = memos.first;
    }
  }

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
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(16),
            ),
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
}
