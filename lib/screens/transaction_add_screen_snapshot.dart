part of 'transaction_add_screen.dart';

class _InitialTransactionFormSnapshot {
  const _InitialTransactionFormSnapshot({
    required this.descText,
    required this.qtyText,
    required this.unitPriceText,
    required this.amountText,
    required this.cardChargedAmountText,
    required this.memoText,
    required this.storeText,
    required this.paymentText,
    required this.selectedType,
    required this.savingsAllocation,
    required this.transactionDate,
    required this.selectedMainCategory,
    required this.selectedSubCategory,
    required this.showIncomeCategoryOptions,
  });

  final String descText;
  final String qtyText;
  final String unitPriceText;
  final String amountText;
  final String cardChargedAmountText;
  final String memoText;
  final String storeText;
  final String paymentText;
  final TransactionType selectedType;
  final SavingsAllocation savingsAllocation;
  final DateTime transactionDate;
  final String selectedMainCategory;
  final String? selectedSubCategory;
  final bool showIncomeCategoryOptions;
}

extension TransactionAddScreenSnapshot on _NO1FormState {
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
      _selectedSubCategory = null;
      _showIncomeCategoryOptions = snapshot.showIncomeCategoryOptions;

      _descController.text = snapshot.descText;
      _qtyController.text = snapshot.qtyText;
      _unitPriceController.text = snapshot.unitPriceText;
      _amountController.text = snapshot.amountText;
      _cardChargedAmountController.text = snapshot.cardChargedAmountText;
      _memoController.text = snapshot.memoText;
      _storeController.text = snapshot.storeText;
      _paymentController.text = snapshot.paymentText;

      _suppressAmountAutoUpdate = false;
    });
  }
}
