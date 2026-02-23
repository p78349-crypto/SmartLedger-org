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
        hint: '예: 시중은행 입출금통장',
      ),
      const SizedBox(height: 12),
      SmartInputField(
        controller: _amountController,
        label: '금액',
        prefixIcon: const Icon(Icons.attach_money),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [CurrencyInputFormatter()],
      ),

      _buildSectionHeader('자산 상세 정보'),
      SmartInputField(
        controller: _institutionController,
        label: '금융사/거래소/보관처 (선택)',
        prefixIcon: const Icon(Icons.account_balance),
        hint: '예: 국민은행, 업비트, 키움증권',
      ),
      if (_selectedCategory != AssetCategory.cash) ...[
        const SizedBox(height: 12),
        SmartInputField(
          controller: _currencyController,
          label: '통화 코드 (선택)',
          prefixIcon: const Icon(Icons.currency_exchange),
          hint: '예: KRW, USD, JPY',
        ),
      ],
      if (_selectedCategory == AssetCategory.stock ||
          _selectedCategory == AssetCategory.crypto ||
          _selectedCategory == AssetCategory.company) ...[
        const SizedBox(height: 12),
        SmartInputField(
          controller: _tickerController,
          label: '종목/심볼 (선택)',
          prefixIcon: const Icon(Icons.tag),
          hint: '예: 005930, AAPL, BTC',
        ),
        const SizedBox(height: 12),
        SmartInputField(
          controller: _unitsController,
          label: '보유 수량 (선택)',
          prefixIcon: const Icon(Icons.calculate),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        SmartInputField(
          controller: _unitPriceController,
          label: '현재 단가 (선택)',
          prefixIcon: const Icon(Icons.sell),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
        ),
      ],
      if (_selectedCategory == AssetCategory.realEstate ||
          _selectedCategory == AssetCategory.company) ...[
        const SizedBox(height: 12),
        SmartInputField(
          controller: _appraisalValueController,
          label: '평가액 (선택)',
          prefixIcon: const Icon(Icons.apartment),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [CurrencyInputFormatter()],
        ),
      ],
      const SizedBox(height: 12),
      SmartInputField(
        controller: _monthlyIncomeController,
        label: '월 수익 (선택)',
        prefixIcon: const Icon(Icons.savings),
        hint: '예: 배당/이자/임대 수익',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [CurrencyInputFormatter()],
      ),
      _buildSectionHeader('위험 관리'),
      SmartInputField(
        controller: _debtAmountController,
        label: '부채/대출 잔액 (선택)',
        prefixIcon: const Icon(Icons.credit_card),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [CurrencyInputFormatter()],
      ),
      const SizedBox(height: 12),
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _maturityDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() => _maturityDate = picked);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: InputDecorator(
          decoration: const InputDecoration(
            labelText: '만기일 (선택)',
            prefixIcon: Icon(Icons.event_available),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _maturityDate == null
                    ? '선택 안 함'
                    : DateFormats.yMd.format(_maturityDate!),
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
      _buildSectionHeader('알림/인사이트'),
      SmartInputField(
        controller: _alertThresholdController,
        label: '경고 임계값 (선택)',
        prefixIcon: const Icon(Icons.notifications_active),
        hint: '현재 금액이 이 값보다 낮으면 경고합니다',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [CurrencyInputFormatter()],
      ),
      const SizedBox(height: 12),
      InputDecorator(
        decoration: const InputDecoration(
          labelText: '리스크 등급 (선택)',
          prefixIcon: Icon(Icons.warning_amber),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<AssetRiskLevel>(
            value: _riskLevel,
            hint: const Text('선택 안 함'),
            isExpanded: true,
            items: AssetRiskLevel.values.map((level) {
              return DropdownMenuItem(
                value: level,
                child: Text(level.label),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _riskLevel = value);
            },
          ),
        ),
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
