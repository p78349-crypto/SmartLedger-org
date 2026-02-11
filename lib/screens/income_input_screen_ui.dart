part of 'income_input_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

/// UI builders for [_IncomeInputScreenState].
extension IncomeInputUI on _IncomeInputScreenState {
  Widget _buildBody() {
    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            _buildSectionHeader('기본 정보'),
            SmartInputField(
              label: '수입명',
              controller: _nameController,
              prefixIcon: const Icon(Icons.label),
              validator: (v) =>
                  v == null || v.isEmpty ? '수입명을 입력하세요' : null,
            ),
            const SizedBox(height: 12),
            SmartInputField(
              label: '금액',
              controller: _amountController,
              prefixIcon: const Icon(Icons.attach_money),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return '금액을 입력하세요';
                final n = double.tryParse(v.replaceAll(',', ''));
                if (n == null || n < 0) return '유효한 금액을 입력하세요';
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
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
                      _incomeDate != null
                          ? DateFormatter.formatDate(_incomeDate!)
                          : '',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Icon(
                      Icons.edit_calendar,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),

            _buildSectionHeader('수입 상세'),
            DropdownButtonFormField<String>(
              initialValue: _category,
              items: const [
                DropdownMenuItem(value: '급여', child: Text('급여')),
                DropdownMenuItem(value: '용돈', child: Text('용돈')),
                DropdownMenuItem(value: '투자', child: Text('투자')),
                DropdownMenuItem(value: '환급', child: Text('환급')),
                DropdownMenuItem(value: '기타', child: Text('기타')),
              ],
              onChanged: (v) => setState(() => _category = v ?? '급여'),
              decoration: const InputDecoration(
                labelText: '카테고리',
                prefixIcon: Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 12),
            SmartInputField(
              label: '수입처',
              controller: _sourceController,
              prefixIcon: const Icon(Icons.business),
            ),
            const SizedBox(height: 12),
            SmartInputField(
              label: '메모',
              controller: _memoController,
              prefixIcon: const Icon(Icons.note),
              maxLines: 3,
              suffixIcon: _recentMemos.isEmpty
                  ? null
                  : PopupMenuButton<String>(
                      icon: const Icon(Icons.history),
                      tooltip: '최근 메모 선택',
                      onSelected: (value) =>
                          setState(() => _memoController.text = value),
                      itemBuilder: (context) => _recentMemos
                          .map(
                            (memo) => PopupMenuItem(
                              value: memo,
                              child: Text(memo),
                            ),
                          )
                          .toList(),
                    ),
            ),

            _buildSectionHeader('추가 옵션'),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: Text(
                  '고급 설정',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    items: _paymentOptions
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _paymentMethod = v ?? '계좌이체'),
                    decoration: const InputDecoration(
                      labelText: '결제 수단',
                      prefixIcon: Icon(Icons.payment),
                    ),
                  ),
                  if (_recentPaymentMethods.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        children: _recentPaymentMethods
                            .map(
                              (method) => ChoiceChip(
                                label: Text(method),
                                selected: _paymentMethod == method,
                                onSelected: (_) {
                                  if (_paymentOptions.contains(method)) {
                                    setState(() => _paymentMethod = method);
                                  }
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _taxStatus,
                    items: _taxStatusOptions
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _taxStatus = v ?? '과세'),
                    decoration: const InputDecoration(
                      labelText: '세금 처리',
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('반복 여부'),
                    value: _isRecurring,
                    onChanged: (v) => setState(() => _isRecurring = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    title: const Text('알림 설정'),
                    value: _alarmEnabled,
                    onChanged: (v) => setState(() => _alarmEnabled = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_alarmEnabled)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: _pickAlarmTime,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text('알림 시간'),
                              const Spacer(),
                              Text(
                                _alarmTime != null
                                    ? _alarmTime!.format(context)
                                    : '시간 선택',
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 6,
                        children: _tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                onDeleted: () => _removeTag(tag),
                                deleteIcon:
                                    const Icon(Icons.close, size: 16),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  SmartInputField(
                    controller: _tagInputController,
                    label: '태그 추가',
                    prefixIcon: const Icon(Icons.tag),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: _addTag,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saveIncome,
              icon: const Icon(Icons.save),
              label: const Text('수입 저장'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
