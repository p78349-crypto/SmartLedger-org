// ignore_for_file: invalid_use_of_protected_member
part of 'asset_input_screen.dart';

extension _FormExt on _AssetInputScreenState {
  List<Widget> _buildFormFields(ThemeData theme) {
    return [
      _buildSectionHeader('자산 카테고리'),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: AssetCategory.values.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                selected: isSelected,
                label: Text(
                  '${category.emoji} ${category.label}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onSelected: (selected) {
                  setState(() => _selectedCategory = category);
                },
              ),
            );
          }).toList(),
        ),
      ),

      _buildSectionHeader('기본 정보'),
      SmartInputField(
        controller: _nameController,
        label: '자산명',
        prefixIcon: const Icon(Icons.label),
        validator: (v) => Validators.required(v, fieldName: '자산명'),
      ),
      const SizedBox(height: 12),
      SmartInputField(
        controller: _amountController,
        label: '금액',
        prefixIcon: const Icon(Icons.attach_money),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [CurrencyInputFormatter()],
        validator: (v) => Validators.positiveNumber(v, fieldName: '금액'),
      ),

      _buildSectionHeader('수익 및 목표'),
      SmartInputField(
        controller: _expectedAnnualRateController,
        label: '기대수익률(연 % · 선택)',
        prefixIcon: const Icon(Icons.percent),
        hint: '예: 예금 3, 주식 7, 코인 0~',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (v) {
          final raw = v?.trim() ?? '';
          if (raw.isEmpty) return null;
          final num? n = num.tryParse(raw);
          if (n == null || n < 0 || n > 100) {
            return '0~100 사이의 숫자를 입력하세요';
          }
          return null;
        },
      ),
      const SizedBox(height: 12),
      SmartInputField(
        controller: _costBasisController,
        label: '원가 (선택사항)',
        prefixIcon: const Icon(Icons.history),
        hint: '손익 추적을 위해 원래 투입한 금액을 입력하세요',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [CurrencyInputFormatter()],
      ),
      const SizedBox(height: 12),
      SmartInputField(
        controller: _ratioController,
        label: '목표 배분 비율 (%)',
        prefixIcon: const Icon(Icons.percent),
        hint: '예: 30 (선택사항)',
        keyboardType: TextInputType.number,
        validator: (v) {
          if (v == null || v.isEmpty) return null;
          final num? n = num.tryParse(v);
          if (n == null || n < 0 || n > 100) {
            return '0~100 사이의 숫자를 입력하세요';
          }
          return null;
        },
      ),

      if (_selectedCategory == AssetCategory.crypto)
        ..._buildCryptoInvestmentSection(theme),

      _buildSectionHeader('메모 및 날짜'),
      SmartInputField(
        controller: _memoController,
        label: '메모 (선택사항)',
        prefixIcon: const Icon(Icons.note),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _submit(),
        maxLines: 3,
      ),
      const SizedBox(height: 12),
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _assetDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) setState(() => _assetDate = picked);
        },
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: '날짜',
            prefixIcon: Icon(Icons.calendar_today),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormats.yMd.format(_assetDate),
                style: theme.textTheme.bodyLarge,
              ),
              Icon(
                Icons.edit_calendar,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 32),
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _submit,
              icon: Icon(_isEdit ? Icons.save : Icons.add_task),
              label: Text(_isEdit ? '수정 완료' : '자산 저장'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildCryptoInvestmentSection(ThemeData theme) {
    return [
      const SizedBox(height: 12),
      Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color:
                theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        color: theme.colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '투자 목표 설정',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isInvestment,
                    onChanged: (value) {
                      setState(() => _isInvestment = value);
                    },
                  ),
                ],
              ),
              if (_isInvestment) ...[
                const SizedBox(height: 8),
                SmartInputField(
                  controller: _targetAmountController,
                  label: '목표액 (도달 시 자동 전환)',
                  prefixIcon: const Icon(Icons.flag),
                  hint: '목표액에 도달하면 자동으로 자산으로 전환됩니다',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [CurrencyInputFormatter()],
                  validator: (v) {
                    if (!_isInvestment) return null;
                    if (v == null || v.isEmpty) {
                      return '투자 시 목표액은 필수입니다';
                    }
                    return Validators.positiveNumber(v, fieldName: '목표액');
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    ];
  }
}
