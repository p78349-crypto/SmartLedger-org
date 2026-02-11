part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Income and refund form field builders.
extension TxDetailUiIncome on _TransactionAddDetailedFormState {
  List<Widget> _buildIncomeFields() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final spacing = isLandscape ? 8.0 : 12.0;

    return [
      _buildDescriptionInput(
        labelText: '수입명',
        emptyMessage: '수입명을 입력하세요.',
        enableHistory: true,
        onFieldSubmitted: (_) => _amountFocusNode.requestFocus(),
      ),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: KeyedSubtree(
              key: const Key('tx_amount'),
              child: TextFormField(
                focusNode: _amountFocusNode,
                controller: _amountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _paymentFocusNode.requestFocus(),
                validator: (value) =>
                    _validatePositiveAmount(value, '수입 금액을 입력하세요.'),
                decoration: _standardInputDecoration(labelText: '수입 금액'),
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
              labelText: '입금수단/계좌',
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

  List<Widget> _buildRefundFields() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final spacing = isLandscape ? 8.0 : 12.0;

    return [
      _buildDescriptionInput(
        labelText: '반품 내역',
        emptyMessage: '반품 내역을 입력하세요.',
        enableHistory: true,
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
              child: TextFormField(
                focusNode: _amountFocusNode,
                controller: _amountController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _paymentFocusNode.requestFocus(),
                validator: (value) =>
                    _validatePositiveAmount(value, '금액을 입력하세요.'),
                decoration: _standardInputDecoration(labelText: '반품 금액'),
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
}
