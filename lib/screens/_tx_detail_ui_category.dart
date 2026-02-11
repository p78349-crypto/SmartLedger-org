part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// Category chip section (income path) and description input.
extension TxDetailUiCategory on _TransactionAddDetailedFormState {
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
      return _buildIncomeCategoryChips(theme);
    }

    return _buildExpenseCategoryChips(theme);
  }

  Widget _buildIncomeCategoryChips(ThemeData theme) {
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
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.w500,
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
}
