part of 'transaction_add_screen.dart';

extension TransactionAddScreenWidgets on _NO1FormState {
  /// 저장 + 저장후계속 버튼
  Widget _buildSaveButtons({bool compact = false}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Transform.scale(
          scale: compact ? 0.75 : 0.85,
          child: FloatingActionButton.extended(
            heroTag: 'save',
            onPressed: _saveTransaction,
            tooltip: '저장',
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            icon: const Icon(IconCatalog.check, size: 20),
            label: const Text(
              'ENT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  /// 메모 입력 필드 (공통)
  Widget _buildMemoField({required VoidCallback onSubmitted}) {
    return KeyedSubtree(
      key: const Key('tx_memo'),
      child: SmartInputField(
        controller: _memoController,
        focusNode: _memoFocusNode,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => onSubmitted(),
        onChanged: (_) => setState(() {}),
        label: '메모',
        hint: _selectedType == TransactionType.income
            ? null
            : '예: 마트 이름 + 간단 메모',
        suffixIcon: IconButton(
          tooltip: '입력내용 불러오기',
          icon: Icon(
            Icons.list_alt,
            size: 20,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => _showRecentInputPicker(
            context: context,
            items: _recentMemos,
            onSelected: (v) {
              _memoController.text = v;
              _memoController.selection = TextSelection.fromPosition(
                TextPosition(offset: v.length),
              );
              setState(() {});
            },
            title: '메모 입력내용 불러오기',
          ),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildPaymentField({
    required Key fieldKey,
    required FocusNode focusNode,
    required TextEditingController controller,
    required VoidCallback onSubmitted,
    required String labelText,
    String? hintText,
    String? emptyErrorText,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return SmartInputField(
      key: fieldKey,
      focusNode: focusNode,
      controller: controller,
      textInputAction: textInputAction,
      onFieldSubmitted: (_) => onSubmitted(),
      label: labelText,
      hint: hintText,
      suffixIcon: IconButton(
        tooltip: '입력내용 불러오기',
        icon: Icon(
          Icons.list_alt,
          size: 20,
          color: Theme.of(context).iconTheme.color,
        ),
        onPressed: () => _showRecentInputPicker(
          context: context,
          items: _recentPayments,
          onSelected: (v) {
            controller.text = v;
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: v.length),
            );
            setState(() {});
          },
          title: '결제수단 입력내용 불러오기',
        ),
        padding: EdgeInsets.zero,
      ),
      validator: (value) {
        if (emptyErrorText == null) return null;
        return value == null || value.trim().isEmpty ? emptyErrorText : null;
      },
    );
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
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: const InputDecoration(labelText: '예금일'),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formatted, style: theme.textTheme.bodyLarge),
            Icon(
              IconCatalog.calendarTodayOutlined,
              color: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreOrBuyerField() {
    return KeyedSubtree(
      key: const Key('tx_store'),
      child: SmartInputField(
        controller: _storeController,
        focusNode: _storeFocusNode,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _amountFocusNode.requestFocus(),
        onChanged: (_) => setState(() {}),
        label: '구매자/거래처(판매자용)',
        hint: '선택: 판매자인 경우 구매자 이름',
        suffixIcon: _storeController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(IconCatalog.clear),
                onPressed: () => setState(_storeController.clear),
              )
            : null,
      ),
    );
  }
}
