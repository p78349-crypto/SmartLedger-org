part of 'transaction_add_screen.dart';

extension TransactionAddScreenBuildFields on _NO1FormState {
  Widget _buildInlineHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${widget.titlePrefix} - ${widget.accountName}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '입력값 되돌리기',
              icon: const Icon(IconCatalog.restartAlt, size: 20),
              onPressed: promptRevertToInitial,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            // 가로모드 전용: 헤더에 저장 버튼 배치
            _buildSaveButtons(compact: true),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFieldsForSelectedType() {
    switch (_selectedType) {
      case TransactionType.savings:
        return _buildSavingsFields();
      case TransactionType.income:
        return _buildIncomeFields();
      case TransactionType.expense:
        return _buildExpenseFields();
      case TransactionType.refund:
        return _buildRefundFields();
    }
  }

  List<Widget> _buildSavingsFields() {
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final spacing = isLandscape ? 8.0 : 12.0;

    return [
      _buildDescriptionInput(
        labelText: '상품명',
        emptyMessage: '상품명을 입력하세요.',
        enableHistory: true,
      ),
      SizedBox(height: spacing),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SmartInputField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              label: '예금 금액 (원)',
              validator: (value) =>
                  _validatePositiveAmount(value, '예금 금액을 입력하세요.'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: _buildSavingsDateField()),
        ],
      ),
      SizedBox(height: spacing),
      _buildSavingsAllocationSelector(theme),
      const SizedBox(height: 4),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          _savingsAllocation.helperText,
          key: ValueKey(_savingsAllocation),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
      SizedBox(height: spacing),
      _buildMemoField(onSubmitted: _saveTransaction),
      SizedBox(height: isLandscape ? 12 : 24),
      _buildCategorySection(),
    ];
  }

  List<Widget> _buildIncomeFields() {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final spacing = isLandscape ? 8.0 : 12.0;

    return [
      _buildDescriptionInput(
        labelText: '수입',
        emptyMessage: '수입을 입력하세요.',
        enableHistory: true,
        onFieldSubmitted: (_) => _amountFocusNode.requestFocus(),
      ),
      SizedBox(height: spacing),
      // Amount full-width
      KeyedSubtree(
        key: const Key('tx_amount'),
        child: SmartInputField(
          focusNode: _amountFocusNode,
          controller: _amountController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _paymentFocusNode.requestFocus(),
          validator: (value) => _validatePositiveAmount(value, '수입 금액을 입력하세요.'),
          label: '수입 금액',
        ),
      ),
      SizedBox(height: spacing),
      // Payment field below amount
      _buildPaymentField(
        fieldKey: const Key('tx_payment'),
        focusNode: _paymentFocusNode,
        controller: _paymentController,
        onSubmitted: () => FocusScope.of(context).requestFocus(_memoFocusNode),
        labelText: '입금수단/계좌',
      ),
      SizedBox(height: spacing),
      _buildMemoField(onSubmitted: _saveTransaction),
      SizedBox(height: isLandscape ? 12 : 24),
      _buildCategorySection(),
    ];
  }
}
