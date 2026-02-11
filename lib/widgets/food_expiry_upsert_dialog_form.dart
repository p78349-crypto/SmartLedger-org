part of 'food_expiry_upsert_dialog.dart';
// ignore_for_file: invalid_use_of_protected_member

extension FoodExpiryUpsertForm on _FoodExpiryUpsertDialogState {
  String _expiryButtonLabel(DateTime? suggestedDate) {
    if (_pickedExpiryDate == null) {
      if (suggestedDate == null) return '날짜 선택';
      final predicted = DateFormat('yyyy-MM-dd').format(suggestedDate);
      return '예측: $predicted';
    }

    final manual = DateFormat('yyyy-MM-dd').format(_pickedExpiryDate!);
    return '수동: $manual';
  }

  List<Widget> _buildFormFields(ThemeData theme) {
    return [
      // Item Name
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
                _isVoiceListening
                    ? IconCatalog.stopCircle
                    : IconCatalog.mic,
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

      // Category
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

      // Health Tags
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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

      // Location
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

      // Expiration Date
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

      // Price
      _buildFieldLabel('가격', theme),
      TextField(
        controller: _priceController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: _formInputDecoration(hintText: '0'),
      ),

      // Supplier
      _buildFieldLabel('구입처', theme),
      TextField(
        controller: _supplierController,
        decoration: _formInputDecoration(
          hintText: '구입처를 입력하세요',
          suffixIcon: const Icon(Icons.keyboard_arrow_down),
        ),
      ),

      const SizedBox(height: 16),
      // Add to shopping list checkbox
      Row(
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
    ];
  }
}
