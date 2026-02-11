part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Savings-type form fields: amount, date, allocation selector.
extension TxDetailUiSavings on _TransactionAddDetailedFormState {
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
      TextFormField(
        controller: _amountController,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: '예금 금액 (원)',
          border: OutlineInputBorder(),
        ),
        validator: (value) => _validatePositiveAmount(value, '예금 금액을 입력하세요.'),
      ),
      SizedBox(height: spacing),
      _buildSavingsDateField(),
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

  Widget _buildSavingsAllocationSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('예금 반영 방식', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<SavingsAllocation>(
            segments: const [
              ButtonSegment<SavingsAllocation>(
                value: SavingsAllocation.assetIncrease,
                icon: Icon(IconCatalog.savings, size: 18),
                label: Text('자산으로 저장'),
              ),
              ButtonSegment<SavingsAllocation>(
                value: SavingsAllocation.expense,
                icon: Icon(IconCatalog.payments, size: 18),
                label: Text('지출로 저장'),
              ),
            ],
            selected: {_savingsAllocation},
            onSelectionChanged: (Set<SavingsAllocation> newSelection) {
              setState(() {
                _savingsAllocation = newSelection.first;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSavingsDateField() {
    final formatted = DateFormatter.defaultDate.format(_transactionDate);
    final theme = Theme.of(context);
    return InkWell(
      onTap: _pickTransactionDate,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: '예금일',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatted),
            Icon(
              IconCatalog.calendarTodayOutlined,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
