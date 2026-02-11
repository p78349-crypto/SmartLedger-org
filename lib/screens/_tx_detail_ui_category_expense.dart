part of 'transaction_add_detailed_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// 3-tier expense category chip section (대/중/소분류).
extension TxDetailUiCategoryExpense on _TransactionAddDetailedFormState {
  Widget _buildExpenseCategoryChips(ThemeData theme) {
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
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selectedColor: theme.colorScheme.secondary,
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  letterSpacing: -0.2,
                  color: isSelected
                      ? theme.colorScheme.onSecondary
                      : theme.colorScheme.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
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
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
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
}
