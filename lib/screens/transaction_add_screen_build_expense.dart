part of 'transaction_add_screen.dart';

extension TransactionAddScreenBuildExpense on _NO1FormState {
  List<Widget> _buildRefundFields() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final spacing = isLandscape ? 8.0 : 12.0;

    return [
      _buildDescriptionInput(
        labelText: '반품 내역 (지출 내역에서 선택)',
        emptyMessage: '반품 내역을 입력하세요.',
        enableHistory: true,
        customHistoryAction: _showExpenseHistoryPicker,
        onFieldSubmitted: (_) => _storeFocusNode.requestFocus(),
      ),
      SizedBox(height: spacing),
      _buildStoreOrBuyerField(),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: KeyedSubtree(
              key: const Key('tx_amount'),
              child: SmartInputField(
                focusNode: _amountFocusNode,
                controller: _amountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _paymentFocusNode.requestFocus(),
                validator: (value) =>
                    _validatePositiveAmount(value, '금액을 입력하세요.'),
                label: '반품 금액',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: _buildPaymentField(
              fieldKey: const Key('tx_payment'),
              focusNode: _paymentFocusNode,
              controller: _paymentController,
              onSubmitted: () =>
                  FocusScope.of(context).requestFocus(_memoFocusNode),
              labelText: '환불 계좌/수단',
              emptyErrorText: '환불 수단 입력',
            ),
          ),
        ],
      ),
      SizedBox(height: spacing),
      _buildMemoField(onSubmitted: _saveTransaction),
      SizedBox(height: isLandscape ? 12 : 24),
      _buildCategorySection(),
    ];
  }

  List<Widget> _buildExpenseFields() {
    return [
      _buildDescriptionInput(
        labelText: '상품명',
        emptyMessage: '상품명을 입력하세요.',
        enableHistory: true,
        onFieldSubmitted: (_) => _expenseUnitPriceFocusNode.requestFocus(),
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SmartInputField(
              key: const Key('tx_unit'),
              controller: _unitPriceController,
              focusNode: _expenseUnitPriceFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '단가 입력' : null,
              label: '단가',
              onFieldSubmitted: (_) {
                final raw = _unitPriceController.text.trim();
                final unit = TypeConverters.parseCurrency(raw) ?? 0.0;
                if (unit <= 0) {
                  _expenseUnitPriceFocusNode.requestFocus();
                  _unitPriceController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _unitPriceController.text.length,
                  );
                  return;
                }

                _expenseQtyFocusNode.requestFocus();
                _qtyController.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _qtyController.text.length,
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SmartInputField(
              key: const Key('tx_qty'),
              controller: _qtyController,
              focusNode: _expenseQtyFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '수량 입력' : null,
              label: '수량',
              onFieldSubmitted: (_) {
                final raw = _qtyController.text.trim();
                final qty = int.tryParse(raw) ?? 0;
                if (qty <= 0) {
                  _expenseQtyFocusNode.requestFocus();
                  _qtyController.selection = TextSelection(
                    baseOffset: 0,
                    extentOffset: _qtyController.text.length,
                  );
                  return;
                }

                FocusScope.of(context).requestFocus(_paymentFocusNode);
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SmartInputField(
              key: const Key('tx_amount'),
              controller: _amountController,
              focusNode: _calculatedAmountFocusNode,
              readOnly: true,
              label: '금액(자동계산)',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: _buildPaymentField(
              fieldKey: const Key('tx_payment'),
              focusNode: _paymentFocusNode,
              controller: _paymentController,
              onSubmitted: () =>
                  FocusScope.of(context).requestFocus(_memoFocusNode),
              labelText: '결제수단',
              emptyErrorText: '결제수단 입력',
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildMemoField(onSubmitted: _saveTransaction),
      const SizedBox(height: 12),
      _buildCategorySection(),
    ];
  }

  // 결제수단 기능(히스토리/선택) 비활성화: 사용 중단 상태
}
