part of 'food_expiry_upsert_dialog.dart';
// ignore_for_file: invalid_use_of_protected_member

/// Build method & remaining form sections for [_FoodExpiryUpsertDialogState].
extension FoodExpiryUpsertBuild on _FoodExpiryUpsertDialogState {
  // ── Expiry date picker ────────────────────────────────────────────

  Widget _buildExpirySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('유통기한', theme),
        InkWell(
          onTap: () async {
            final initial = _pickedExpiryDate ?? DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
            );
            if (picked != null) {
              setState(() => _pickedExpiryDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _expiryButtonLabel(_pickedExpiryDate),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const Icon(Icons.calendar_today_outlined, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Price & Supplier ──────────────────────────────────────────────

  Widget _buildPriceAndSupplierSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('가격', theme),
        TextField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _formInputDecoration(hintText: '0'),
        ),
        _buildFieldLabel('구입처', theme),
        TextField(
          controller: _supplierController,
          decoration: _formInputDecoration(
            hintText: '구입처를 입력하세요',
            suffixIcon: const Icon(Icons.keyboard_arrow_down),
          ),
        ),
      ],
    );
  }

  // ── Shopping-list checkbox ────────────────────────────────────────

  Widget _buildShoppingListCheckbox(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: _addToShoppingList,
              onChanged: (val) =>
                  setState(() => _addToShoppingList = val ?? false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '장바구니에 추가',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────

  Widget _buildActionButtons(ThemeData theme) {
    final isImporting = _importQueue.isNotEmpty || _importTotal > 0;

    return Column(
      children: [
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '취소',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.existing == null ? '등록하기' : '수정하기',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        if (isImporting) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _skipCurrentImport,
                  child: const Text('Skip This Item'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: _stopImport,
                  child: const Text(
                    'Stop Import',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Main build ────────────────────────────────────────────────────

  Widget _buildDialog(BuildContext context) {
    final theme = Theme.of(context);

    final isImporting = _importQueue.isNotEmpty || _importTotal > 0;
    final remaining = _importQueue.length;
    final currentImportIndex = _importTotal - remaining;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      widget.existing == null
                          ? '식료품/생활용품 등록'
                          : '식료품/생활용품 정보 수정',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 3,
                      width: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (isImporting)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Chip(
                    label: Text(
                      '가져오기 중 ${currentImportIndex + 1} / $_importTotal',
                    ),
                    backgroundColor: theme.colorScheme.secondaryContainer,
                  ),
                ),
              _buildNameSection(theme),
              _buildCategorySection(theme),
              _buildHealthTagsSection(theme),
              _buildQuantitySection(theme),
              _buildLocationSection(theme),
              _buildExpirySection(theme),
              _buildPriceAndSupplierSection(theme),
              _buildShoppingListCheckbox(theme),
              _buildActionButtons(theme),
            ],
          ),
        ),
      ),
    );
  }
}
