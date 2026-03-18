part of 'transaction_add_detailed_screen.dart';

extension TransactionAddDetailedUI on _TransactionAddDetailedFormState {
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
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
              onChanged: (v) => setState(() => _addToShoppingList = v ?? false),
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
              key: const Key('tx_amount'),
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
        child: TextFormField(
          focusNode: _amountFocusNode,
          controller: _amountController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) => _paymentFocusNode.requestFocus(),
          validator: (value) => _validatePositiveAmount(value, '수입 금액을 입력하세요.'),
          decoration: _standardInputDecoration(labelText: '수입 금액'),
        ),
      ),
      SizedBox(height: spacing),
      // Payment field moved to its own row below amount
      _buildPaymentField(
        fieldKey: const Key('tx_payment'),
        focusNode: _paymentFocusNode,
        controller: _paymentController,
        onSubmitted: () => FocusScope.of(context).requestFocus(_memoFocusNode),
        labelText: '입금수단/계좌',
      ),
      SizedBox(height: spacing),
      // Memo below payment
      _buildMemoField(onSubmitted: _saveTransaction),
      SizedBox(height: isLandscape ? 12 : 24),
      _buildCategorySection(),
    ];
  }

  Widget _buildCategorySection() {
    final isIncome = _selectedType == TransactionType.income;
    final showOptions = !isIncome || _showIncomeCategoryOptions;

    if (!showOptions) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            setState(() {
              if (_selectedType == TransactionType.income &&
                  _selectedMainCategory ==
                      DetailedCategoryDefinitions.defaultCategory) {
                _applyIncomeDefaultCategory();
              }
              _showIncomeCategoryOptions = true;
            });
          },
          icon: const Icon(IconCatalog.categoryOutlined),
          label: const Text('카테고리 옵션 표시'),
        ),
      );
    }

    final theme = Theme.of(context);

    if (isIncome) {
      const categoryMap = IncomeCategoryDefinitions.categoryOptions;
      final mainCategories = categoryMap.keys.toList();
      final subCategories =
          categoryMap[_selectedMainCategory] ?? const <String>[];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('카테고리', style: theme.textTheme.labelLarge),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showIncomeCategoryOptions = false;
                    _selectedMainCategory =
                        DetailedCategoryDefinitions.defaultCategory;
                    _selectedSubCategory = null;
                    _selectedDetailCategory = null;
                  });
                },
                icon: const Icon(IconCatalog.visibilityOffOutlined, size: 16),
                label: const Text('숨기기'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: mainCategories.map((cat) {
              final isSelected = _selectedMainCategory == cat;
              return ChoiceChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12.5,
                    letterSpacing: -0.2,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    _userPickedCategory = true;
                    _selectedMainCategory = cat;
                    _selectedSubCategory = null;
                    _selectedDetailCategory = null;
                  });
                  unawaited(
                    _persistLastCategoryForType(_selectedType, main: cat),
                  );
                },
              );
            }).toList(),
          ),
          if (subCategories.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: subCategories.map((cat) {
                final isSelected = _selectedSubCategory == cat;
                return ChoiceChip(
                  label: Text(
                    cat,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 12.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (!selected) return;
                    setState(() {
                      _userPickedCategory = true;
                      _selectedSubCategory = cat;
                      _selectedDetailCategory = null;
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ],
      );
    }

    // Detailed 3-tier logic for expenses
    final mainCategories = DetailedCategoryDefinitions.mainCategories;
    final subCategories = DetailedCategoryDefinitions.getSubCategories(
      _selectedMainCategory,
    );
    final detailCategories = _selectedSubCategory != null
        ? DetailedCategoryDefinitions.getDetailCategories(
            _selectedMainCategory,
            _selectedSubCategory!,
          )
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('대분류', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: mainCategories.map((cat) {
            final isSelected = _selectedMainCategory == cat;
            return ChoiceChip(
              label: Text(
                cat,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12.5,
                  letterSpacing: -0.2,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (!selected) return;
                setState(() {
                  _userPickedCategory = true;
                  _selectedMainCategory = cat;
                  _selectedSubCategory = null;
                  _selectedDetailCategory = null;
                });
                unawaited(
                  _persistLastCategoryForType(_selectedType, main: cat),
                );
              },
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              selectedColor: theme.colorScheme.primary,
              labelStyle: TextStyle(
                fontSize: 12.5,
                letterSpacing: -0.2,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
            );
          }).toList(),
        ),
        if (subCategories.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('중분류', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subCategories.map((cat) {
              final isSelected = _selectedSubCategory == cat;
              return ChoiceChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12.5,
                    letterSpacing: -0.2,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    _userPickedCategory = true;
                    _selectedSubCategory = cat;
                    _selectedDetailCategory = null;
                  });
                },
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selectedColor: theme.colorScheme.secondary,
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  letterSpacing: -0.2,
                  color: isSelected
                      ? theme.colorScheme.onSecondary
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.outlineVariant,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        if (detailCategories.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('소분류(상세)', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: detailCategories.map((cat) {
              final isSelected = _selectedDetailCategory == cat;
              return ChoiceChip(
                label: Text(
                  cat,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12.5,
                    letterSpacing: -0.2,
                  ),
                ),
                selected: isSelected,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    _userPickedCategory = true;
                    _selectedDetailCategory = cat;
                  });
                },
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selectedColor: theme.colorScheme.tertiary,
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  letterSpacing: -0.2,
                  color: isSelected
                      ? theme.colorScheme.onTertiary
                      : theme.colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.outlineVariant,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildMemoField({required VoidCallback onSubmitted}) {
    return KeyedSubtree(
      key: const Key('tx_memo'),
      child: TextFormField(
        controller: _memoController,
        focusNode: _memoFocusNode,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => onSubmitted(),
        onChanged: (_) => setState(() {}),
        decoration: _standardInputDecoration(
          labelText: '메모',
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
      ),
    );
  }

  Widget _buildStoreOrBuyerField() {
    return KeyedSubtree(
      key: const Key('tx_store'),
      child: TextFormField(
        controller: _storeController,
        focusNode: _storeFocusNode,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _amountFocusNode.requestFocus(),
        onChanged: (_) => setState(() {}),
        decoration: _standardInputDecoration(
          labelText: '구매자/거래처(판매자용)',
          hintText: '선택: 판매자인 경우 구매자 이름',
          suffixIcon: _storeController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(IconCatalog.clear),
                  onPressed: () => setState(_storeController.clear),
                )
              : null,
        ),
      ),
    );
  }

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
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${widget.titlePrefix} - ${widget.accountName}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: '장바구니 동기화',
              icon: const Icon(IconCatalog.shoppingCart),
              onPressed: confirmAndOpenShoppingCartPicker,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: '입력값 되돌리기',
              icon: const Icon(IconCatalog.restartAlt),
              onPressed: promptRevertToInitial,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            _buildSaveButtons(compact: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButtons({bool compact = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: compact ? 0.7 : 0.8,
          child: FloatingActionButton.small(
            heroTag: 'save_continue',
            onPressed: _saveAndContinue,
            tooltip: '저장 후 계속',
            child: const Icon(IconCatalog.arrowForward),
          ),
        ),
        const SizedBox(width: 4), // 간격 축소
        Transform.scale(
          scale: compact ? 0.6 : 0.7,
          child: FloatingActionButton(
            heroTag: 'save',
            onPressed: _saveTransaction,
            tooltip: '저장',
            child: Text(
              compact ? '저장' : 'ENT',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ),
      ],
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
    return TextFormField(
      key: fieldKey,
      focusNode: focusNode,
      controller: controller,
      textInputAction: textInputAction,
      onFieldSubmitted: (_) => onSubmitted(),
      decoration: _standardInputDecoration(
        labelText: labelText,
        hintText: hintText,
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

  Widget _buildDescriptionInput({
    required String labelText,
    required String emptyMessage,
    required bool enableHistory,
    ValueChanged<String>? onFieldSubmitted,
  }) {
    return KeyedSubtree(
      key: const Key('tx_desc'),
      child: TextFormField(
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
        decoration: _standardInputDecoration(
          labelText: labelText,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isAICoreModelLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: 'AI 카테고리 분류',
                  icon: Icon(
                    Icons.auto_awesome,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _predictCategoryWithAI,
                  padding: EdgeInsets.zero,
                ),
              IconButton(
                tooltip: '입력내용 불러오기',
                icon: Icon(
                  Icons.list_alt,
                  size: 20,
                  color: Theme.of(context).iconTheme.color,
                ),
                onPressed: () => _showRecentInputPicker(
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
