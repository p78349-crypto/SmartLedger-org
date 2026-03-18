part of 'food_expiry_upsert_dialog.dart';
// ignore_for_file: invalid_use_of_protected_member

/// Form-field builder helpers for [_FoodExpiryUpsertDialogState].
extension FoodExpiryUpsertForm on _FoodExpiryUpsertDialogState {
  Widget _buildFieldLabel(String label, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 12),
      child: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  InputDecoration _formInputDecoration({
    String? hintText,
    Widget? suffixIcon,
    EdgeInsets? contentPadding,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2),
      ),
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      isDense: true,
    );
  }

  // ── Name section ──────────────────────────────────────────────────

  Widget _buildNameSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('품목명', theme),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                decoration: _formInputDecoration(
                  hintText: '품목명을 입력하세요',
                  suffixIcon: const Icon(Icons.edit_note, size: 20),
                ),
                textInputAction: TextInputAction.next,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            if (AppConstants.voiceInputEnabled) ...[
              IconButton.outlined(
                onPressed: _toggleVoiceInput,
                icon: Icon(
                  _isVoiceListening ? IconCatalog.stopCircle : IconCatalog.mic,
                ),
                tooltip: _isVoiceListening ? '음성 입력 중지' : '음성 입력',
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            IconButton.outlined(
              onPressed: _showHistoryPicker,
              icon: const Icon(IconCatalog.history),
              tooltip: '쇼핑 기록 불러오기',
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Category dropdown ─────────────────────────────────────────────

  Widget _buildCategorySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('카테고리', theme),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: _formInputDecoration(),
          items: _categories.map((c) {
            return DropdownMenuItem(value: c, child: Text(c));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _category = val);
          },
        ),
      ],
    );
  }

  // ── Health tags ───────────────────────────────────────────────────

  Widget _buildHealthTagsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('건강 태그 (선택)', theme),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: HealthGuardrailService.defaultTags.map((tag) {
            final isSelected = _healthTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (v) {
                setState(() {
                  final next = <String>{..._healthTags};
                  if (v) {
                    next.add(tag);
                  } else {
                    next.remove(tag);
                  }
                  _healthTags = next.toList();
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Quantity section (box calc + total + unit) ────────────────────

  Widget _buildQuantitySection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Box Calculator
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('BOX 수량', theme),
                    TextField(
                      controller: _boxQtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _formInputDecoration(hintText: 'Box 수'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Text(
                  'x',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('입수량(Pcs)', theme),
                    TextField(
                      controller: _pcsPerBoxController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _formInputDecoration(hintText: '개/Box'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Total Quantity & Unit
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('총 수량 (Total)', theme),
                  TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _formInputDecoration(hintText: '0'),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFieldLabel('단위', theme),
                  TextField(
                    controller: _unitController,
                    decoration: _formInputDecoration(
                      hintText: '단위 (예: 개, g, kg)',
                    ),
                  ),
                  const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Location dropdown ─────────────────────────────────────────────

  Widget _buildLocationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('보관 위치', theme),
        DropdownButtonFormField<String>(
          initialValue: _location,
          decoration: _formInputDecoration(),
          items: _locations.map((l) {
            return DropdownMenuItem(value: l, child: Text(l));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _location = val);
          },
        ),
      ],
    );
  }
}
