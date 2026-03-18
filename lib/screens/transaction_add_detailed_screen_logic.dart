part of 'transaction_add_detailed_screen.dart';

extension TransactionAddDetailedLogic on _TransactionAddDetailedFormState {
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

    // 최근 상품명/결제수단/메모 저장 (빈값/중복 제외)
    final prefs = await SharedPreferences.getInstance();
    if (desc.isNotEmpty) {
      final updated = [desc, ..._recentDescriptions.where((e) => e != desc)];
      final clipped = updated.take(_maxRecentDescriptions).toList();
      await prefs.setStringList(_recentDescriptionsKey, clipped);
      _recentDescriptions = clipped;
    }
    if (payment.isNotEmpty) {
      final updated = [payment, ..._recentPayments.where((e) => e != payment)];
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
        excludeTransactionId: _isEditing ? widget.initialTransaction?.id : null,
      );
      if (!mounted) return;
      if (!ok) return;
    }

    if (widget.confirmBeforeSave && !skipConfirm) {
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

      if (!mounted) return;

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

      if (!mounted) return;
      if (confirmed != true) {
        return;
      }
    }

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

    final service = TransactionService();
    try {
      if (existing == null) {
        await service.addTransaction(widget.accountName, transaction);

        if (_addToShoppingList) {
          final currentItems = await UserPrefService.getShoppingCartItems(
            accountName: widget.accountName,
          );
          final now = DateTime.now();
          final newItem = ShoppingCartItem(
            id: 'sc_${now.microsecondsSinceEpoch}',
            name: desc,
            quantity: qty,
            unitPrice: unit,
            memo: memo,
            createdAt: now,
            updatedAt: now,
          );
          var nextItems = [...currentItems, newItem];
          // 최근 10건만 유지 (재구매 예정 목록 최신순 제한)
          if (nextItems.length > 10) {
            nextItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            nextItems = nextItems.take(10).toList();
          }
          await UserPrefService.setShoppingCartItems(
            accountName: widget.accountName,
            items: nextItems,
          );
        }

        if (effectiveMainCategory !=
            DetailedCategoryDefinitions.defaultCategory) {
          unawaited(
            CategoryUsageService.increment(
              main: effectiveMainCategory,
              sub: effectiveSubCategory,
              detail: effectiveDetailCategory,
            ),
          );
          unawaited(
            RecentInputService.saveCategory(
              CategoryUsageService.labelFor(
                main: effectiveMainCategory,
                sub: effectiveSubCategory,
                detail: effectiveDetailCategory,
              ),
            ),
          );
        }

        // 식비 카테고리이고 유통기한이 입력된 경우 재고 관리(ConsumableInventoryService)에 자동 추가
        final isFood =
            effectiveMainCategory == '식품·음료비' ||
            effectiveMainCategory == '식비' ||
            effectiveMainCategory == 'Food';
        if (isExpense && isFood && _expiryDate != null) {
          unawaited(
            ConsumableInventoryService.instance.addItem(
              name: desc,
              purchaseDate: _transactionDate,
              expiryDate: _expiryDate,
              currentStock: qty.toDouble(),
              unit: unitStr.isNotEmpty ? unitStr : '개',
              price: amount,
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
            CategoryUsageService.increment(
              main: effectiveMainCategory,
              sub: effectiveSubCategory,
            ),
          );
          unawaited(
            RecentInputService.saveCategory(
              CategoryUsageService.labelFor(
                main: effectiveMainCategory,
                sub: effectiveSubCategory,
              ),
            ),
          );
        }
      }

      final baseMessage = existing == null ? '거래가 저장되었습니다' : '거래가 수정되었습니다';
      final detail = isSavings ? ' (${_savingsAllocation.snackBarDetail})' : '';
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, '$baseMessage$detail');
      await _clearDraft();

      if (widget.learnCategoryHintFromDescription &&
          effectiveMainCategory != _defaultCategory) {
        unawaited(
          UserPrefService.setShoppingCategoryHint(
            accountName: widget.accountName,
            keyword: desc,
            hint: CategoryHint(
              mainCategory: effectiveMainCategory,
              subCategory: effectiveSubCategory,
              detailCategory: effectiveDetailCategory,
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

            // 다음 입력을 기준으로 “입력값 되돌리기” 스냅샷을 재설정
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

extension TransactionAddDetailedFormMoreLogic
    on _TransactionAddDetailedFormState {
  Future<void> triggerAutoSubmit() async {
    await _saveTransaction(skipConfirm: true);
  }

  bool _isShoppingCategory(String mainCategory, String? subCategory) {
    if (_TransactionAddDetailedFormState._shoppingMainCategories.contains(
      mainCategory,
    )) {
      return true;
    }
    if (mainCategory == '식비') {
      final sub = subCategory?.trim();
      if (sub == null || sub.isEmpty) {
        // If user didn't pick a subcategory, treat it as shopping to keep the
        // behavior predictable.
        return true;
      }
      return _TransactionAddDetailedFormState._shoppingFoodSubCategories
          .contains(sub);
    }
    return false;
  }

  Future<String?> _buildShoppingSpendComparisonTooltip({
    required String accountName,
  }) async {
    final service = TransactionService();
    await service.loadTransactions();

    final all = service.getTransactions(accountName);
    if (all.isEmpty) return null;

    final now = DateTime.now();
    final today = _dateOnly(now);
    final yesterday = today.subtract(const Duration(days: 1));
    final rangeStart = yesterday.subtract(
      const Duration(
        days: _TransactionAddDetailedFormState._shoppingAvgLookbackDays - 1,
      ),
    );

    final totalsByDay = <DateTime, double>{};

    for (final tx in all) {
      if (tx.type != TransactionType.expense) continue;
      if (!_isShoppingCategory(tx.mainCategory, tx.subCategory)) continue;

      final day = _dateOnly(tx.date);
      if (day.isBefore(rangeStart) || day.isAfter(yesterday)) continue;

      totalsByDay[day] = (totalsByDay[day] ?? 0) + tx.amount;
    }

    double sum = 0;
    for (
      var i = 0;
      i < _TransactionAddDetailedFormState._shoppingAvgLookbackDays;
      i++
    ) {
      final day = rangeStart.add(Duration(days: i));
      sum += totalsByDay[day] ?? 0;
    }

    final yesterdayTotal = totalsByDay[yesterday] ?? 0;
    final avg = sum / _TransactionAddDetailedFormState._shoppingAvgLookbackDays;

    final yText = CurrencyFormatter.format(yesterdayTotal);
    final avgText = CurrencyFormatter.format(avg);

    String deltaText = '';
    if (avg.abs() > 0.000001) {
      final pct = ((yesterdayTotal - avg) / avg) * 100.0;
      final sign = pct >= 0 ? '+' : '';
      deltaText = ' ($sign${pct.toStringAsFixed(0)}%)';
    }

    return '쇼핑 기준(식비/생활용품/의류)\n'
        '어제: $yText\n'
        '최근 ${_TransactionAddDetailedFormState._shoppingAvgLookbackDays}일 일평균: $avgText$deltaText';
  }

  Future<void> _loadShoppingCategoryHints() async {
    if (_isEditing) return;
    try {
      var hints = await UserPrefService.getShoppingCategoryHints(
        accountName: widget.accountName,
      );
      if (hints.isEmpty) {
        await UserPrefService.bootstrapShoppingCategoryHintsFromTransactions(
          accountName: widget.accountName,
        );
        hints = await UserPrefService.getShoppingCategoryHints(
          accountName: widget.accountName,
        );
      }

      final normalized = <String, CategoryHint>{};
      for (final e in hints.entries) {
        final k = _normalizeShoppingHintKey(e.key);
        if (k.isEmpty) continue;
        normalized[k] = e.value;
      }

      if (!mounted) return;
      setState(() {
        _shoppingCategoryHintsNormalized = normalized;
        _shoppingCategoryHintsLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _shoppingCategoryHintsNormalized = const {};
        _shoppingCategoryHintsLoaded = true;
      });
    }
  }

  Future<void> _predictCategoryWithAI() async {
    final text = _descController.text.trim();
    if (text.isEmpty) {
      SnackbarUtils.showInfo(context, '상품명을 먼저 입력해주세요.');
      return;
    }

    setState(() {
      _isAICoreModelLoading = true;
    });

    try {
      final isReady = await _aicore.isAvailable();
      if (!isReady) {
        if (mounted) {
          SnackbarUtils.showWarning(
            context,
            '온디바이스 AI 모델을 불러올 수 없습니다. 모델 파일 설치 확인이 필요합니다.',
          );
        }
        return;
      }

      final candidates = _selectedType == TransactionType.income
          ? IncomeCategoryDefinitions.mainCategories
          : CategoryDefinitions.mainCategories;

      final result = await _aicore.predictCategory(
        text,
        candidateCategories: candidates,
      );

      if (result != null && mounted) {
        setState(() {
          _selectedMainCategory = result;
          _userPickedCategory = true;
        });
        SnackbarUtils.showSuccess(context, 'AI 분류 결과: $result');
      } else {
        if (mounted) {
          SnackbarUtils.showInfo(context, '분류 결과를 찾지 못했습니다.');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAICoreModelLoading = false;
        });
      }
    }
  }

  void _handleDescriptionChanged(String value) {
    if (_isEditing) return;
    if (_selectedType != TransactionType.expense) return;
    if (_userPickedCategory) return;
    if (!_shoppingCategoryHintsLoaded) return;

    _autoCategoryDebounce?.cancel();
    _autoCategoryDebounce = Timer(const Duration(milliseconds: 120), () {
      if (!mounted) return;

      String? main;
      String? nextSub;
      String? nextDetail;

      // 1) Try user history hints first
      final hint = _findBestCategoryHint(value);
      if (hint != null) {
        final hintMain = hint.mainCategory.trim();
        if (hintMain.isNotEmpty &&
            hintMain != _defaultCategory &&
            DetailedCategoryDefinitions.mainCategories.contains(hintMain)) {
          main = hintMain;

          final hintSub = hint.subCategory?.trim() ?? '';
          if (hintSub.isNotEmpty) {
            final allowedSub = DetailedCategoryDefinitions.getSubCategories(
              main,
            );
            if (allowedSub.contains(hintSub)) {
              nextSub = hintSub;

              final hintDetail = hint.detailCategory?.trim() ?? '';
              if (hintDetail.isNotEmpty) {
                final allowedDetail =
                    DetailedCategoryDefinitions.getDetailCategories(
                      main,
                      hintSub,
                    );
                if (allowedDetail.contains(hintDetail)) {
                  nextDetail = hintDetail;
                }
              }
            }
          }
        }
      }

      // 2) Fallback to keyword dictionary
      if (main == null) {
        final kwResult = CategoryKeywordService.instance.classify(value);
        if (kwResult != null) {
          final kwMain = kwResult.$1;
          if (DetailedCategoryDefinitions.mainCategories.contains(kwMain)) {
            main = kwMain;
            final kwSub = kwResult.$2;
            if (kwSub != null) {
              final allowedSub = DetailedCategoryDefinitions.getSubCategories(
                main,
              );
              if (allowedSub.contains(kwSub)) {
                nextSub = kwSub;
              }
            }
          }
        }
      }

      if (main == null) return;

      final unchanged =
          main == _selectedMainCategory &&
          nextSub == _selectedSubCategory &&
          nextDetail == _selectedDetailCategory;
      if (unchanged) return;

      setState(() {
        _selectedMainCategory = main!;
        _selectedSubCategory = nextSub;
        _selectedDetailCategory = nextDetail;
      });
      unawaited(_persistLastCategoryForType(_selectedType, main: main));
    });
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

    // Ensure default category is first if present, or handle as needed.
    // Usually default category is '미분류'.
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

  Future<void> openShoppingCartPicker() async {
    FocusScope.of(context).unfocus();
    await _saveDraft();

    var items = await UserPrefService.getShoppingCartItems(
      accountName: widget.accountName,
    );

    if (!mounted || items.isEmpty) {
      if (mounted) SnackbarUtils.showInfo(context, '장바구니에 저장된 항목이 없습니다.');
      return;
    }

    // Make a local mutable copy so we can toggle isChecked in the picker.
    final local = items.map((e) => e.copyWith()).toList();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        // Grouping items by date for display
        final grouped = <String, List<ShoppingCartItem>>{};
        for (var it in local) {
          final dateStr =
              '${it.createdAt.year}-${it.createdAt.month.toString().padLeft(2, '0')}-${it.createdAt.day.toString().padLeft(2, '0')}';
          grouped.putIfAbsent(dateStr, () => []).add(it);
        }
        final sortedDates = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return SafeArea(
          child: Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 640),
              child: Column(
                children: [
                  ListTile(
                    title: const Text('재구매 예정 항목 선택'),
                    trailing: IconButton(
                      icon: const Icon(IconCatalog.close),
                      onPressed: () => Navigator.of(sheetContext).pop(false),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: StatefulBuilder(
                      builder: (context, setSheetState) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: sortedDates.length,
                          itemBuilder: (context, dateIndex) {
                            final dateStr = sortedDates[dateIndex];
                            final dateItems = grouped[dateStr]!;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Theme(
                                data: Theme.of(
                                  context,
                                ).copyWith(dividerColor: Colors.transparent),
                                child: ExpansionTile(
                                  initiallyExpanded: true,
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              dateStr,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            Text(
                                              '${dateItems.length}개 항목',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: () {
                                          final allChecked = dateItems.every(
                                            (e) => e.isChecked,
                                          );
                                          setSheetState(() {
                                            for (final it in dateItems) {
                                              final originalIdx = local
                                                  .indexWhere(
                                                    (element) =>
                                                        element.id == it.id,
                                                  );
                                              if (originalIdx != -1) {
                                                local[originalIdx] = it
                                                    .copyWith(
                                                      isChecked: !allChecked,
                                                    );
                                                final itemIdx = dateItems
                                                    .indexWhere(
                                                      (e) => e.id == it.id,
                                                    );
                                                if (itemIdx != -1) {
                                                  dateItems[itemIdx] = it
                                                      .copyWith(
                                                        isChecked: !allChecked,
                                                      );
                                                }
                                              }
                                            }
                                          });
                                        },
                                        icon: Icon(
                                          dateItems.every((e) => e.isChecked)
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          size: 20,
                                        ),
                                        label: Text(
                                          dateItems.every((e) => e.isChecked)
                                              ? '선택해제'
                                              : '전체선택',
                                        ),
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: dateItems.map((it) {
                                    final qty = it.quantity <= 0
                                        ? 1
                                        : it.quantity;
                                    final unitPriceText = it.unitPrice <= 0
                                        ? '-'
                                        : CurrencyFormatter.formatWithDecimals(
                                            it.unitPrice,
                                            showUnit: false,
                                          );
                                    return CheckboxListTile(
                                      value: it.isChecked,
                                      title: Text(it.name),
                                      subtitle: Text(
                                        '수량: $qty    단가: $unitPriceText',
                                      ),
                                      dense: true,
                                      onChanged: (v) {
                                        final originalIdx = local.indexWhere(
                                          (element) => element.id == it.id,
                                        );
                                        if (originalIdx != -1) {
                                          local[originalIdx] = it.copyWith(
                                            isChecked: v ?? false,
                                          );
                                          final itemIdx = dateItems.indexWhere(
                                            (e) => e.id == it.id,
                                          );
                                          if (itemIdx != -1) {
                                            dateItems[itemIdx] = it.copyWith(
                                              isChecked: v ?? false,
                                            );
                                          }
                                        }
                                        setSheetState(() {});
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(false),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () =>
                                Navigator.of(sheetContext).pop(true),
                            child: const Text('지출입력 상세 입력하기'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || confirmed != true) return;

    // Replace original items with local (which includes isChecked flags)
    items = local;

    final checkedItems = items.where((i) => i.isChecked).toList();

    // 단일 항목 선택 시: 설명만 채우고 수량/단가 자동 입력은 하지 않는다.
    if (checkedItems.length == 1) {
      final item = checkedItems.first;

      debugPrint(
        '[openShoppingCartPicker] 단일 항목 선택(자동입력 비활성): '
        'name=${item.name}',
      );

      // 현재 화면의 필드: 상품명만 채운다. 수량/단가는 건드리지 않음.
      setState(() {
        _descController.text = item.name;
      });

      // 선택된 항목 제거
      await UserPrefService.setShoppingCartItems(
        accountName: widget.accountName,
        items: items.where((i) => i.id != item.id).toList(),
      );

      // 히스토리 기록
      final at = DateTime.now();
      await UserPrefService.addShoppingCartHistoryEntry(
        accountName: widget.accountName,
        entry: ShoppingCartHistoryEntry(
          id: 'hist_${at.microsecondsSinceEpoch}',
          action: ShoppingCartHistoryAction.addToLedger,
          itemId: item.id,
          name: item.name,
          quantity: item.quantity,
          unitPrice: item.unitPrice,
          isPlanned: item.isPlanned,
          at: at,
        ),
      );

      if (mounted) {
        SnackbarUtils.showInfo(context, '${item.name}을(를) 입력 필드에 추가했습니다.');
      }
      return;
    }

    // 다중 항목 선택 시 기존 로직 (bulk flow)
    // load category hints for suggestions
    final hints = await UserPrefService.getShoppingCategoryHints(
      accountName: widget.accountName,
    );

    // Ensure widget still mounted before using context across async gaps
    if (!mounted) return;

    // Call bulk utility to handle sequential transactionAdd flows.
    await ShoppingCartBulkLedgerUtils.addCheckedItemsToLedgerBulk(
      context: context,
      accountName: widget.accountName,
      items: items,
      categoryHints: hints,
      saveItems: (next) async {
        await UserPrefService.setShoppingCartItems(
          accountName: widget.accountName,
          items: next,
        );
      },
      reload: () async {},
      useDetailedMode: true,
    );
  }

  Future<void> confirmAndOpenShoppingCartPicker() async {
    final items = await ShoppingCartSyncUtils.confirmAndLoadCheckedItems(
      context,
      widget.accountName,
    );
    if (!mounted || items == null) return;

    await _saveDraft();

    // Always open the picker to avoid implicit auto-fill of price/qty.
    await openShoppingCartPicker();
  }

  Future<void> _saveDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = <String, dynamic>{
        'ts': DateTime.now().millisecondsSinceEpoch,
        'desc': _descController.text,
        'qty': _qtyController.text,
        'unitPrice': _unitPriceController.text,
        'amount': _amountController.text,
        'card': _cardChargedAmountController.text,
        'memo': _memoController.text,
        'store': _storeController.text,
        'payment': _paymentController.text,
        'type': _selectedType.name,
        'savingsAllocation': _savingsAllocation.name,
        'date': _transactionDate.toIso8601String(),
        'mainCategory': _selectedMainCategory,
        'subCategory': _selectedSubCategory,
        'detailCategory': _selectedDetailCategory,
        'location': _locationController.text,
        'supplier': _supplierController.text,
        'unit': _unitController.text,
        'expiry': _expiryDate?.toIso8601String(),
        'addToShoppingList': _addToShoppingList,
      };
      await prefs.setString(_draftKey(), jsonEncode(draft));
    } catch (e) {
      debugPrint('Draft save failed: $e');
    }
  }

  Future<void> _clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftKey());
    } catch (e) {
      debugPrint('Draft clear failed: $e');
    }
  }

  Future<void> _loadDraftIfRecent() async {
    try {
      if (!mounted) return;
      // Do not overwrite when editing an existing transaction
      if (widget.initialTransaction != null && !widget.treatAsNew) return;

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey());
      if (raw == null || raw.trim().isEmpty) return;
      final Map<String, dynamic> decoded = jsonDecode(raw);
      final ts = decoded['ts'] as int?;
      if (ts == null) {
        // malformed draft — remove
        await prefs.remove(_draftKey());
        return;
      }
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > _TransactionAddDetailedFormState._draftTtlMs) {
        // expired — delete draft
        await prefs.remove(_draftKey());
        return;
      }

      // Restore fields
      if (!mounted) return;
      setState(() {
        _descController.text = decoded['desc'] ?? '';
        _qtyController.text = decoded['qty'] ?? _qtyController.text;
        _unitPriceController.text =
            decoded['unitPrice'] ?? _unitPriceController.text;
        _amountController.text = decoded['amount'] ?? _amountController.text;
        _cardChargedAmountController.text = decoded['card'] ?? '';
        _memoController.text = decoded['memo'] ?? '';
        _storeController.text = decoded['store'] ?? '';
        _paymentController.text = decoded['payment'] ?? '';
        try {
          _selectedType = TransactionType.values.firstWhere(
            (e) => e.name == (decoded['type'] ?? ''),
            orElse: () => _selectedType,
          );
        } catch (e) {
          debugPrint('TransactionType parse failed: $e');
        }
        try {
          _savingsAllocation = SavingsAllocation.values.firstWhere(
            (e) => e.name == (decoded['savingsAllocation'] ?? ''),
            orElse: () => _savingsAllocation,
          );
        } catch (e) {
          debugPrint('SavingsAllocation parse failed: $e');
        }
        try {
          _transactionDate = DateTime.parse(
            decoded['date'] ?? _transactionDate.toIso8601String(),
          );
        } catch (e) {
          debugPrint('Date parse failed: $e');
        }
        _selectedMainCategory =
            decoded['mainCategory'] ?? _selectedMainCategory;
        _selectedSubCategory = decoded['subCategory'];
        _selectedDetailCategory = decoded['detailCategory'];
        _locationController.text = decoded['location'] ?? '';
        _supplierController.text = decoded['supplier'] ?? '';
        _unitController.text = decoded['unit'] ?? '';
        if (decoded['expiry'] != null) {
          try {
            _expiryDate = DateTime.parse(decoded['expiry']);
          } catch (e) {
            debugPrint('Expiry date parse failed: $e');
          }
        }
        _addToShoppingList = decoded['addToShoppingList'] ?? _addToShoppingList;
      });
      _updateAmount();
    } catch (e) {
      debugPrint('Draft load failed: $e');
    }
  }

  void _captureInitialSnapshotIfNeeded() {
    if (!mounted) return;
    if (_initialSnapshot != null) return;
    _initialSnapshot = _InitialTransactionFormSnapshot(
      descText: _descController.text,
      qtyText: _qtyController.text,
      unitPriceText: _unitPriceController.text,
      amountText: _amountController.text,
      cardChargedAmountText: _cardChargedAmountController.text,
      memoText: _memoController.text,
      storeText: _storeController.text,
      paymentText: _paymentController.text,
      selectedType: _selectedType,
      savingsAllocation: _savingsAllocation,
      transactionDate: _transactionDate,
      selectedMainCategory: _selectedMainCategory,
      selectedSubCategory: _selectedSubCategory,
      selectedDetailCategory: _selectedDetailCategory,
      locationText: _locationController.text,
      supplierText: _supplierController.text,
      unitText: _unitController.text,
      expiryDate: _expiryDate,
      addToShoppingList: _addToShoppingList,
      showIncomeCategoryOptions: _showIncomeCategoryOptions,
    );
  }

  Future<void> promptRevertToInitial() async {
    _captureInitialSnapshotIfNeeded();
    final snapshot = _initialSnapshot;
    if (snapshot == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('입력값 되돌리기'),
          content: const Text('화면을 열었을 때의 입력값으로 되돌릴까요?'),
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
            FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('되돌리기'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      _restoreFromInitialSnapshot(snapshot);
    }
  }

  void _restoreFromInitialSnapshot(_InitialTransactionFormSnapshot snapshot) {
    FocusScope.of(context).unfocus();

    setState(() {
      _suppressAmountAutoUpdate = true;

      _selectedType = snapshot.selectedType;
      _savingsAllocation = snapshot.savingsAllocation;
      _transactionDate = snapshot.transactionDate;
      _selectedMainCategory = snapshot.selectedMainCategory;
      _selectedSubCategory = snapshot.selectedSubCategory;
      _selectedDetailCategory = snapshot.selectedDetailCategory;
      _expiryDate = snapshot.expiryDate;
      _addToShoppingList = snapshot.addToShoppingList;
      _showIncomeCategoryOptions = snapshot.showIncomeCategoryOptions;

      _descController.text = snapshot.descText;
      _qtyController.text = snapshot.qtyText;
      _unitPriceController.text = snapshot.unitPriceText;
      _amountController.text = snapshot.amountText;
      _cardChargedAmountController.text = snapshot.cardChargedAmountText;
      _memoController.text = snapshot.memoText;
      _storeController.text = snapshot.storeText;
      _paymentController.text = snapshot.paymentText;
      _locationController.text = snapshot.locationText;
      _supplierController.text = snapshot.supplierText;
      _unitController.text = snapshot.unitText;

      _suppressAmountAutoUpdate = false;
    });
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
    final recent = candidates
        .take(_TransactionAddDetailedFormState._priceRiseLookbackCount)
        .toList();
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

    if (historyUnitPrices.length <
        _TransactionAddDetailedFormState._priceRiseMinSamples) {
      return true;
    }

    final baseline = _median(historyUnitPrices);
    if (baseline <= 0) return true;

    final delta = currentUnitPrice - baseline;
    final pct = delta / baseline;
    final isRise =
        pct >= _TransactionAddDetailedFormState._priceRisePctThreshold &&
        delta >= _TransactionAddDetailedFormState._priceRiseMinDeltaWon;
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
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('계속 저장'),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  void _updateAmount() {
    if (_suppressAmountAutoUpdate) {
      return;
    }
    if (_selectedType != TransactionType.expense) {
      return;
    }
    final qtyText = _qtyController.text.trim();
    final qty = qtyText.isEmpty ? 1 : int.tryParse(qtyText) ?? 1;
    final unit = TypeConverters.parseCurrency(_unitPriceController.text) ?? 0.0;
    _amountController.text = (qty * unit).toStringAsFixed(0);
  }

  void _applyIncomeDefaultCategory() {
    final defaultMain = IncomeCategoryDefinitions.defaultMainCategory;
    if (defaultMain != null) {
      _selectedMainCategory = defaultMain;
      _selectedSubCategory = null;
    } else {
      _selectedMainCategory = _defaultCategory;
      _selectedSubCategory = null;
    }
  }

  Future<void> _restoreLastCategoryForType(TransactionType type) async {
    if (_isEditing) return;

    final prefs = await SharedPreferences.getInstance();
    final savedMain = prefs.getString(_lastCategoryMainKeyFor(type));
    if (savedMain == null || savedMain.trim().isEmpty) return;

    final categoryOptions = _categoryOptionsFor(type);
    if (!categoryOptions.containsKey(savedMain)) return;

    if (!mounted) return;
    setState(() {
      _selectedMainCategory = savedMain;
      _selectedSubCategory = null;
      if (type == TransactionType.income) {
        _showIncomeCategoryOptions = savedMain != _defaultCategory;
      }
    });
  }

  Future<void> _pickTransactionDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _transactionDate = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _transactionDate.hour,
        _transactionDate.minute,
        _transactionDate.second,
      );
    });
  }

  String? _validatePositiveAmount(String? value, String errorMessage) {
    final raw = value?.trim() ?? '';
    final parsed = double.tryParse(raw.replaceAll(',', ''));
    if (parsed == null || parsed <= 0) {
      return errorMessage;
    }
    return null;
  }

  Future<void> _saveAndContinue() async {
    await _saveTransaction();
  }
}
