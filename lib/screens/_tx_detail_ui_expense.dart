part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Expense-type form field builder.
extension TxDetailUiExpense on _TransactionAddDetailedFormState {
  List<Widget> _buildExpenseFields() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final spacing = isLandscape ? 8.0 : 12.0;

    return [
      _buildDescriptionInput(
        labelText: '상품명',
        emptyMessage: '상품명을 입력하세요.',
        enableHistory: true,
        onFieldSubmitted: (_) => _expenseUnitPriceFocusNode.requestFocus(),
      ),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              key: const Key('tx_unit_price'),
              controller: _unitPriceController,
              focusNode: _expenseUnitPriceFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '단가 입력' : null,
              decoration: _standardInputDecoration(labelText: '단가'),
              onFieldSubmitted: (_) => _expenseQtyFocusNode.requestFocus(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              key: const Key('tx_qty'),
              controller: _qtyController,
              focusNode: _expenseQtyFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  value == null || value.trim().isEmpty ? '수량 입력' : null,
              decoration: _standardInputDecoration(labelText: '수량'),
              onFieldSubmitted: (_) => _unitFocusNode.requestFocus(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              key: const Key('tx_unit'),
              controller: _unitController,
              focusNode: _unitFocusNode,
              textInputAction: TextInputAction.next,
              decoration: _standardInputDecoration(
                labelText: '단위',
                hintText: 'kg, 개 등',
              ),
              onFieldSubmitted: (_) => _locationFocusNode.requestFocus(),
            ),
          ),
        ],
      ),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _locationController,
              focusNode: _locationFocusNode,
              textInputAction: TextInputAction.next,
              decoration: _standardInputDecoration(
                labelText: '보관장소',
                hintText: '냉장고, 팬트리 등',
              ),
              onFieldSubmitted: (_) => _supplierFocusNode.requestFocus(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _supplierController,
              focusNode: _supplierFocusNode,
              textInputAction: TextInputAction.next,
              decoration: _standardInputDecoration(
                labelText: '마트/쇼핑몰',
                hintText: '마트, 온라인 쇼핑몰 등',
              ),
              onFieldSubmitted: (_) => _paymentFocusNode.requestFocus(),
            ),
          ),
        ],
      ),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _expiryDate ??
                      DateTime.now().add(const Duration(days: 7)),
                  firstDate:
                      DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) {
                  setState(() => _expiryDate = picked);
                }
              },
              child: InputDecorator(
                decoration: _standardInputDecoration(
                  labelText: '유통기한',
                  suffixIcon: _expiryDate != null
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () {
                            setState(() => _expiryDate = null);
                          },
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _expiryDate == null
                          ? '선택 안함'
                          : DateFormat('yyyy-MM-dd').format(_expiryDate!),
                    ),
                    if (_expiryDate == null)
                      const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CheckboxListTile(
              title: const Text('재구매 예정', style: TextStyle(fontSize: 14)),
              value: _addToShoppingList,
              onChanged: (v) =>
                  setState(() => _addToShoppingList = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        ],
      ),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _amountController,
              focusNode: _calculatedAmountFocusNode,
              readOnly: true,
              decoration: _standardInputDecoration(labelText: '금액(자동계산)'),
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
      SizedBox(height: spacing),
      _buildMemoField(onSubmitted: _saveTransaction),
      SizedBox(height: isLandscape ? 12 : 24),
      _buildCategorySection(),
    ];
  }
}
