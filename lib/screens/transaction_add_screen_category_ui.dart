part of 'transaction_add_screen.dart';

extension TransactionAddScreenCategoryUI on _NO1FormState {
  Widget _buildCategorySection() {
    final isIncome = _selectedType == TransactionType.income;
    final showOptions = !isIncome || _showIncomeCategoryOptions;

    if (!showOptions) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() {
              if (_selectedType == TransactionType.income &&
                  _selectedMainCategory == _defaultCategory) {
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

    final categoryMap = _categoryOptionsFor(_selectedType);
    final mainCategories = _sortedMainCategories.isNotEmpty
        ? _sortedMainCategories
        : categoryMap.keys.toList();
    final subCategories =
        categoryMap[_selectedMainCategory] ?? const <String>[];
    final showSubOptions =
        _selectedMainCategory != _defaultCategory && subCategories.isNotEmpty;
    final theme = Theme.of(context);

    // 선택된 카테고리 표시 문자열
    final selectedCategoryText = _selectedSubCategory != null
        ? '$_selectedMainCategory > $_selectedSubCategory'
        : _selectedMainCategory != _defaultCategory
        ? _selectedMainCategory
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text('카테고리', style: theme.textTheme.labelMedium),
                  if (selectedCategoryText != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          selectedCategoryText,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _buildSaveButtons(compact: true),
          ],
        ),
        if (isIncome)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _showIncomeCategoryOptions = false;
                  _selectedMainCategory = _defaultCategory;
                  _selectedSubCategory = null;
                });
              },
              icon: const Icon(IconCatalog.visibilityOffOutlined, size: 16),
              label: const Text('숨기기'),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final width3 = (constraints.maxWidth - 16) / 3;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: mainCategories.map((cat) {
                final isSelected = _selectedMainCategory == cat;
                return SizedBox(
                  width: width3,
                  child: ChoiceChip(
                    label: Center(
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 12.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (!selected) return;
                      setState(() {
                        _userPickedCategory = true;
                        _selectedMainCategory = cat;
                        _selectedSubCategory = null;
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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
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
                  ),
                );
              }).toList(),
            );
          },
        ),
        if (showSubOptions) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: subCategories.map((sub) {
              final isSelected = _selectedSubCategory == sub;
              return ChoiceChip(
                label: Text(sub),
                selected: isSelected,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    _userPickedCategory = true;
                    _selectedSubCategory = sub;
                  });
                  unawaited(
                    _persistLastCategoryForType(
                      _selectedType,
                      main: _selectedMainCategory,
                    ),
                  );
                },
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selectedColor: theme.colorScheme.secondary,
                labelStyle: TextStyle(
                  fontSize: 12,
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
      ],
    );
  }
}
