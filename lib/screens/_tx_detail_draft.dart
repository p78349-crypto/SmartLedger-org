part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Draft persistence and initial-snapshot revert helpers.
extension TxDetailDraft on _TransactionAddDetailedFormState {
  String _draftKey() => PrefKeys.accountKey(widget.accountName, 'tx_draft_v1');

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
      if (widget.initialTransaction != null && !widget.treatAsNew) return;

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_draftKey());
      if (raw == null || raw.trim().isEmpty) return;
      final Map<String, dynamic> decoded = jsonDecode(raw);
      final ts = decoded['ts'] as int?;
      if (ts == null) {
        await prefs.remove(_draftKey());
        return;
      }
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > _draftTtlMs) {
        await prefs.remove(_draftKey());
        return;
      }

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
}
