// ignore_for_file: invalid_use_of_protected_member
part of income_add_form;

extension _IncomeAddFormUi on _IncomeAddFormState {
  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNameField(),
          const SizedBox(height: 12),
          _buildAmountField(),
          const SizedBox(height: 12),
          _buildIncomeDateTile(context),
          const SizedBox(height: 12),
          _buildCategoryField(),
          const SizedBox(height: 12),
          _buildSourceField(),
          const SizedBox(height: 12),
          _buildMemoField(context),
          const SizedBox(height: 12),
          _buildExtraOptions(context),
          const SizedBox(height: 16),
          _buildSaveButton(context),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: '수입명',
        hintText: '예) 월급, 프리랜스 수입, 이자 수익',
        border: OutlineInputBorder(),
      ),
      validator: (v) {
        return v == null || v.trim().isEmpty ? '수입명을 입력하세요.' : null;
      },
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: '금액',
        hintText: '실제 입금된 금액',
        border: OutlineInputBorder(),
        prefixText: '₩ ',
      ),
      validator: (v) {
        return v == null || v.trim().isEmpty ? '금액을 입력하세요.' : null;
      },
    );
  }

  Widget _buildIncomeDateTile(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('수입 발생일'),
      subtitle: Text(DateFormatter.formatDate(_date)),
      trailing: OutlinedButton.icon(
        icon: const Icon(Icons.calendar_today),
        label: const Text('날짜 선택'),
        onPressed: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _date,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (!mounted) return;
          if (picked != null) {
            setState(() => _date = picked);
          }
        },
      ),
    );
  }

  Widget _buildCategoryField() {
    return DropdownButtonFormField<String>(
      initialValue: _category,
      decoration: const InputDecoration(
        labelText: '카테고리',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: '급여', child: Text('급여')),
        DropdownMenuItem(value: '용돈', child: Text('용돈')),
        DropdownMenuItem(value: '투자', child: Text('투자')),
        DropdownMenuItem(value: '환급', child: Text('환급')),
        DropdownMenuItem(value: '기타', child: Text('기타')),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() => _category = v);
      },
    );
  }

  Widget _buildSourceField() {
    return TextFormField(
      controller: _sourceController,
      decoration: const InputDecoration(
        labelText: '수입처',
        hintText: '회사명, 은행명, 개인 등',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildMemoField(BuildContext context) {
    return TextFormField(
      controller: _memoController,
      decoration: InputDecoration(
        labelText: '메모',
        hintText: '상세 설명 (예: 11월 프로젝트 완료 수익)',
        border: const OutlineInputBorder(),
        suffixIcon: _recentMemos.isEmpty
            ? null
            : PopupMenuButton<String>(
                icon: const Icon(Icons.history),
                tooltip: '최근 메모 선택',
                onSelected: (value) {
                  setState(() => _memoController.text = value);
                },
                itemBuilder: (context) {
                  return _recentMemos
                      .map(
                        (memo) {
                          return PopupMenuItem(
                            value: memo,
                            child: Text(memo),
                          );
                        },
                      )
                      .toList();
                },
              ),
      ),
      maxLines: 2,
    );
  }
}
