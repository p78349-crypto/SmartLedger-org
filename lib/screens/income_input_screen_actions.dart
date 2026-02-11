part of 'income_input_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Actions & logic for [_IncomeInputScreenState].
extension IncomeInputActions on _IncomeInputScreenState {
  Future<void> _loadRecentInputs() async {
    final payments = await RecentInputService.loadValues(_paymentPrefsKey);
    final memos = await RecentInputService.loadValues(_memoPrefsKey);
    if (!mounted) return;
    setState(() {
      _recentPaymentMethods = payments;
      _recentMemos = memos;
      final preferredPayment = payments.firstWhere(
        (value) => _paymentOptions.contains(value),
        orElse: () => _paymentMethod,
      );
      _paymentMethod = preferredPayment;
      if (_memoController.text.isEmpty && memos.isNotEmpty) {
        _memoController.text = memos.first;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureInitialSnapshotIfNeeded();
    });
  }

  void _captureInitialSnapshotIfNeeded() {
    if (!mounted) return;
    if (_initialSnapshot != null) return;
    _initialSnapshot = _InitialIncomeFormSnapshot(
      nameText: _nameController.text,
      amountText: _amountController.text,
      incomeDate: _incomeDate,
      category: _category,
      sourceText: _sourceController.text,
      paymentMethod: _paymentMethod,
      memoText: _memoController.text,
      tagInputText: _tagInputController.text,
      tags: List<String>.from(_tags),
      isRecurring: _isRecurring,
      alarmEnabled: _alarmEnabled,
      alarmTime: _alarmTime,
      taxStatus: _taxStatus,
    );
  }

  Future<void> _promptRevertToInitial() async {
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
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('되돌리기'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      FocusScope.of(context).unfocus();
      setState(() {
        _nameController.text = snapshot.nameText;
        _amountController.text = snapshot.amountText;
        _incomeDate = snapshot.incomeDate;
        _category = snapshot.category;
        _sourceController.text = snapshot.sourceText;
        _paymentMethod = snapshot.paymentMethod;
        _memoController.text = snapshot.memoText;
        _tagInputController.text = snapshot.tagInputText;
        _tags
          ..clear()
          ..addAll(snapshot.tags);
        _isRecurring = snapshot.isRecurring;
        _alarmEnabled = snapshot.alarmEnabled;
        _alarmTime = snapshot.alarmTime;
        _taxStatus = snapshot.taxStatus;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incomeDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _incomeDate = picked);
    }
  }

  Future<void> _pickAlarmTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime ?? TimeOfDay.now(),
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() => _alarmTime = picked);
    }
  }

  void _addTag(String tag) {
    if (tag.trim().isEmpty) return;
    setState(() {
      _tags.add(tag.trim());
      _tagInputController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
  }

  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;

    // 금액 검증
    final amount = double.tryParse(_amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      if (mounted) {
        SnackbarUtils.showWarning(context, '유효한 금액을 입력하세요');
      }
      return;
    }

    try {
      final sourceValue = _sourceController.text.trim();
      final memoValue = _memoController.text.trim();

      final memoLines = <String>[];
      if (memoValue.isNotEmpty) {
        memoLines.add(memoValue);
      }
      if (sourceValue.isNotEmpty) {
        memoLines.add('수입처: $sourceValue');
      }
      if (_taxStatus != '과세') {
        memoLines.add('세금: $_taxStatus');
      }
      if (_isRecurring) {
        memoLines.add('반복: 예');
      }
      if (_alarmEnabled && _alarmTime != null) {
        final alarmLabel =
            '${_alarmTime!.hour.toString().padLeft(2, '0')}:'
            '${_alarmTime!.minute.toString().padLeft(2, '0')}';
        memoLines.add('알림: $alarmLabel');
      }
      if (_tags.isNotEmpty) {
        memoLines.add('태그: ${_tags.join(', ')}');
      }

      final mergedMemo = memoLines.join('\n');

      // 거래 객체 생성
      final transaction = Transaction(
        id: const Uuid().v4(),
        type: TransactionType.income,
        amount: amount,
        date: _incomeDate ?? DateTime.now(),
        description: _nameController.text.trim(),
        paymentMethod: _paymentMethod,
        mainCategory: _category,
        subCategory: sourceValue.isEmpty ? null : sourceValue,
        memo: mergedMemo,
      );

      // 거래 저장
      await TransactionService().addTransaction(
        widget.accountName,
        transaction,
      );

      // 최근 입력값 저장
      await RecentInputService.saveValue(_paymentPrefsKey, _paymentMethod);
      if (memoValue.isNotEmpty) {
        await RecentInputService.saveValue(_memoPrefsKey, memoValue);
      }
      await _loadRecentInputs();

      if (mounted) {
        SnackbarUtils.showSuccess(context, '수입이 저장되었습니다');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, '저장 실패: $e');
      }
    }
  }
}
