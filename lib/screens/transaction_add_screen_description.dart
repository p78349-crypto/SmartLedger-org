part of 'transaction_add_screen.dart';

extension TransactionAddScreenDescription on _NO1FormState {
  Widget _buildDescriptionInput({
    required String labelText,
    required String emptyMessage,
    required bool enableHistory,
    ValueChanged<String>? onFieldSubmitted,
    VoidCallback? customHistoryAction,
  }) {
    return KeyedSubtree(
      key: const Key('tx_desc'),
      child: SmartInputField(
        controller: _descController,
        focusNode: _descFocusNode,
        textInputAction: TextInputAction.next,
        validator: (value) =>
            value == null || value.trim().isEmpty ? emptyMessage : null,
        onFieldSubmitted: onFieldSubmitted,
        onChanged: (v) {
          _handleDescriptionChanged(v);
          setState(() {});
        },
        label: labelText,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (enableHistory || customHistoryAction != null)
              IconButton(
                tooltip: '입력내용 불러오기',
                icon: Icon(
                  Icons.list_alt,
                  size: 20,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed:
                    customHistoryAction ??
                    () => _showRecentInputPicker(
                      context: context,
                      items: _recentDescriptions,
                      onSelected: (v) {
                        _descController.text = v;
                        _descController.selection = TextSelection.fromPosition(
                          TextPosition(offset: v.length),
                        );
                        _handleDescriptionChanged(v);
                        setState(() {});
                      },
                      title: '$labelText 입력내용 불러오기',
                    ),
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ),
    );
  }

  void _showExpenseHistoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return _ExpenseHistoryPicker(
          accountName: widget.accountName,
          onSelected: (tx) {
            Navigator.pop(context);
            _fillRefundFromTransaction(tx);
          },
        );
      },
    );
  }

  void _fillRefundFromTransaction(Transaction tx) {
    setState(() {
      _descController.text = tx.description;
      _storeController.text = tx.store ?? '';
      _paymentController.text = tx.paymentMethod;

      final amt = CurrencyFormatter.format(
        tx.amount,
        showUnit: false,
      ).replaceAll(',', '');
      _amountController.text = amt;

      if (CategoryDefinitions.mainCategories.contains(tx.mainCategory)) {
        _selectedMainCategory = tx.mainCategory;
      }

      _handleDescriptionChanged(tx.description);

      // 반품 내역 메모 자동 완성 (구매 시점 정보 포함)
      final originalDate = DateFormatter.defaultDate.format(tx.date);
      _memoController.text = '원구매일: $originalDate | 지출예산 복구';
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus();
    });
  }
}
