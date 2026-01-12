// ignore_for_file: invalid_use_of_protected_member
part of savings_plan_form_screen;

extension _SavingsPlanFormScreenUi on _SavingsPlanFormScreenState {
  Widget _buildScaffold(BuildContext context) {
    final isEditing = widget.initialPlan != null;

    return Scaffold(
      appBar: AppBar(
        title: _buildTitle(isEditing),
        actions: [
          IconButton(
            tooltip: '입력값 되돌리기',
            icon: const Icon(Icons.restart_alt),
            onPressed: _promptRevertToInitial,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildNameField(),
              const SizedBox(height: 12),
              _buildAmountField(),
              const SizedBox(height: 12),
              _buildTermField(),
              const SizedBox(height: 12),
              _buildInterestField(),
              const SizedBox(height: 12),
              _buildDatesRow(),
              const SizedBox(height: 12),
              _buildAutoDepositSwitch(),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                child: Text(isEditing ? '저장' : '추가'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) {
                        return SavingsPlanSearchScreen(
                          accountName: widget.accountName,
                        );
                      },
                    ),
                  );
                },
                child: const Text('예금 리스트'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(bool isEditing) {
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(
            text: '예금',
            style: TextStyle(
              color: AppColors.savingsText,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(text: isEditing ? ' 수정' : ' 추가'),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: '상품명',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        return Validators.required(value, fieldName: '상품명');
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: '월 납입액 (원)',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        return Validators.positiveNumber(value, fieldName: '월 납입액');
      },
    );
  }

  Widget _buildTermField() {
    return TextFormField(
      controller: _termController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: '만기 개월 수',
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        return Validators.positiveInteger(value, fieldName: '개월 수');
      },
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildInterestField() {
    return TextFormField(
      controller: _interestController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _save(),
      decoration: const InputDecoration(
        labelText: '연 이자율 (%)',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildDatesRow() {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('시작일'),
            subtitle: Text(DateFormats.yMd.format(_startDate)),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _pickStartDate,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('만기일'),
            subtitle: Text(_calculateMaturityDate()),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoDepositSwitch() {
    final subtitle = _autoDeposit
        ? '매월 납입일에 자동으로 입력됩니다'
        : '납입일에 알림으로 확인 후 입력됩니다';

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('자동이체'),
      subtitle: Text(subtitle),
      value: _autoDeposit,
      onChanged: (value) {
        setState(() {
          _autoDeposit = value;
        });
      },
    );
  }
}

class _InitialSavingsPlanFormSnapshot {
  const _InitialSavingsPlanFormSnapshot({
    required this.nameText,
    required this.amountText,
    required this.termText,
    required this.interestText,
    required this.startDate,
    required this.autoDeposit,
  });

  final String nameText;
  final String amountText;
  final String termText;
  final String interestText;
  final DateTime startDate;
  final bool autoDeposit;
}
