// ignore_for_file: invalid_use_of_protected_member
part of income_add_form;

extension _IncomeAddFormOptions on _IncomeAddFormState {
  Widget _buildExtraOptions(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12),
      title: const Text('추가 옵션'),
      children: [
        _buildPaymentMethodField(),
        if (_recentPaymentMethods.length > 1) _buildRecentPaymentsChips(),
        const SizedBox(height: 12),
        _buildTaxStatusField(),
        const SizedBox(height: 12),
        _buildRepeatSwitch(),
        _buildAlarmSwitch(),
        if (_alarm) _buildNextIncomeDateTile(context),
        const SizedBox(height: 12),
        _buildTagInput(),
        if (_tags.isNotEmpty) _buildTagsChips(),
      ],
    );
  }

  Widget _buildPaymentMethodField() {
    return DropdownButtonFormField<String>(
      initialValue: _paymentMethod,
      decoration: const InputDecoration(
        labelText: '결제 수단',
        border: OutlineInputBorder(),
      ),
      items: _IncomeAddFormState._paymentOptions
          .map(
            (value) => DropdownMenuItem(value: value, child: Text(value)),
          )
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() => _paymentMethod = v);
      },
    );
  }

  Widget _buildRecentPaymentsChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        children: _recentPaymentMethods
            .map(
              (method) => ChoiceChip(
                label: Text(method),
                selected: _paymentMethod == method,
                onSelected: (_) {
                  if (_IncomeAddFormState._paymentOptions.contains(method)) {
                    setState(() => _paymentMethod = method);
                  }
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTaxStatusField() {
    return DropdownButtonFormField<String>(
      initialValue: _taxStatus,
      decoration: const InputDecoration(
        labelText: '세금 처리',
        border: OutlineInputBorder(),
      ),
      items: _IncomeAddFormState._taxStatusOptions
          .map(
            (value) => DropdownMenuItem(value: value, child: Text(value)),
          )
          .toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() => _taxStatus = v);
      },
    );
  }

  Widget _buildRepeatSwitch() {
    return SwitchListTile(
      title: const Text('반복 여부'),
      subtitle: const Text('월급처럼 정기적으로 발생하는 수입 자동 등록'),
      value: _repeat,
      onChanged: (v) => setState(() => _repeat = v),
      contentPadding: EdgeInsets.zero,
      secondary: const Icon(Icons.repeat),
    );
  }

  Widget _buildAlarmSwitch() {
    return SwitchListTile(
      title: const Text('알림 설정'),
      subtitle: const Text('다음 수입 예정일 알림'),
      value: _alarm,
      onChanged: (v) => setState(() => _alarm = v),
      contentPadding: EdgeInsets.zero,
      secondary: const Icon(Icons.notifications_active),
    );
  }

  Widget _buildNextIncomeDateTile(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('다음 수입 예정일'),
      subtitle: Text(
        _nextIncomeDate == null
            ? '선택 안됨'
            : DateFormatter.formatDate(_nextIncomeDate!),
      ),
      trailing: OutlinedButton.icon(
        icon: const Icon(Icons.edit_calendar),
        label: const Text('선택'),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() => _nextIncomeDate = picked);
          }
        },
      ),
    );
  }

  Widget _buildTagInput() {
    return TextFormField(
      controller: _tagController,
      decoration: InputDecoration(
        labelText: '태그 (쉼표로 구분)',
        hintText: '예) #프리랜스, #부수입, #연말정산',
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.add),
          onPressed: _addTagsFromInput,
        ),
      ),
      onFieldSubmitted: (v) {
        if (v.trim().isEmpty) return;
        setState(() {
          _tags.addAll(
            v
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty),
          );
          _tagController.clear();
        });
      },
    );
  }

  void _addTagsFromInput() {
    final input = _tagController.text.trim();
    if (input.isEmpty) return;
    setState(() {
      _tags.addAll(
        input
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty),
      );
      _tagController.clear();
    });
  }

  Widget _buildTagsChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 6,
        children: _tags
            .map(
              (t) => Chip(
                label: Text(t),
                onDeleted: () => setState(() => _tags.remove(t)),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.check_circle),
      label: const Text('저장'),
      onPressed: () => _onSavePressed(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _onSavePressed(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    final memoValue = _memoController.text.trim();

    final payments = await RecentInputService.saveValue(
      _IncomeAddFormState._paymentPrefsKey,
      _paymentMethod,
    );

    var memos = _recentMemos;
    if (memoValue.isNotEmpty) {
      memos = await RecentInputService.saveValue(
        _IncomeAddFormState._memoPrefsKey,
        memoValue,
      );
    }

    if (!mounted) return;
    setState(() {
      _recentPaymentMethods = payments;
      _recentMemos = memos;
    });

    widget.onSave?.call({
      'name': _nameController.text.trim(),
      'amount': double.tryParse(_amountController.text) ?? 0,
      'date': _date,
      'category': _category,
      'source': _sourceController.text.trim(),
      'paymentMethod': _paymentMethod,
      'taxStatus': _taxStatus,
      'memo': memoValue,
      'tags': _tags,
      'repeat': _repeat,
      'alarm': _alarm,
      'nextIncomeDate': _nextIncomeDate,
    });

    navigator.pop();
  }
}
