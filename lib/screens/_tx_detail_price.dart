part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Price-rise detection, amount calculation, date picker, and store field.
extension TxDetailPrice on _TransactionAddDetailedFormState {
  Widget _buildStoreOrBuyerField() {
    return KeyedSubtree(
      key: const Key('tx_store'),
      child: TextFormField(
        controller: _storeController,
        focusNode: _storeFocusNode,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _amountFocusNode.requestFocus(),
        onChanged: (_) => setState(() {}),
        decoration: _standardInputDecoration(
          labelText: '구매자/거래처(판매자용)',
          hintText: '선택: 판매자인 경우 구매자 이름',
          suffixIcon: _storeController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(IconCatalog.clear),
                  onPressed: () => setState(_storeController.clear),
                )
              : null,
        ),
      ),
    );
  }

  String _normalizeItemKey(String raw) {
    final trimmed = raw.trim().toLowerCase();
    return trimmed.replaceAll(RegExp(r'\s+'), ' ');
  }

  double _median(List<double> values) {
    final sorted = List<double>.from(values)..sort();
    final n = sorted.length;
    if (n == 0) return 0;
    final mid = n ~/ 2;
    if (n.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  String _formatWon(double value) {
    final v = value.isFinite ? value : 0;
    final decimals = v == v.roundToDouble() ? 0 : 2;
    return v.toStringAsFixed(decimals);
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
    final unit = double.tryParse(_unitPriceController.text) ?? 0.0;
    final total = qty * unit;
    if (total == total.roundToDouble()) {
      _amountController.text = total.toStringAsFixed(0);
    } else {
      _amountController.text = total.toStringAsFixed(2);
    }
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
}
