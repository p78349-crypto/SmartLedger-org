// ignore_for_file: invalid_use_of_protected_member
part of 'fixed_cost_tab_screen.dart';

/// 고정비용 탭 Form UI + 목록 빌더
extension FixedCostTabBuildUI on _FixedCostTabScreenState {
  Widget _buildFormSection() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildSectionHeader('기본 정보'),
          SmartInputField(
            controller: _nameController,
            label: '정기지출 이름',
            prefixIcon: const Icon(Icons.label),
            textInputAction: TextInputAction.next,
            validator: (value) =>
                Validators.required(value, fieldName: '정기지출 이름'),
          ),
          const SizedBox(height: 12),
          SmartInputField(
            controller: _amountController,
            label: '금액',
            prefixIcon: const Icon(Icons.attach_money),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                Validators.positiveNumber(value, fieldName: '금액'),
          ),
          const SizedBox(height: 12),
          SmartInputField(
            controller: _vendorController,
            label: '납부처 (선택)',
            prefixIcon: const Icon(Icons.business),
            textInputAction: TextInputAction.next,
          ),
          _buildSectionHeader('결제 및 일정'),
          SmartInputField(
            controller: _paymentController,
            label: '결제 수단',
            prefixIcon: const Icon(Icons.payment),
            hint: '결제 수단 입력',
            textInputAction: TextInputAction.next,
            validator: (value) =>
                Validators.required(value, fieldName: '결제 수단'),
          ),
          if (_recentPaymentMethods.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Wrap(
                spacing: 8,
                children: _recentPaymentMethods
                    .take(5)
                    .map(
                      (method) => ChoiceChip(
                        label: Text(method),
                        selected: _paymentController.text == method,
                        onSelected: (_) => setState(
                          () => _paymentController.text = method,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            initialValue: _dueDay,
            decoration: const InputDecoration(
              labelText: '납부일 (선택)',
              prefixIcon: Icon(Icons.calendar_today),
              helperText: '입력 시 알림 등 일정 관리에 활용할 수 있어요.',
            ),
            items: [
              const DropdownMenuItem<int?>(child: Text('선택 안 함')),
              ..._FixedCostTabScreenState._dayOptions.map(
                (day) => DropdownMenuItem<int?>(
                  value: day,
                  child: Text('매월 $day일'),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _dueDay = value),
          ),
          _buildSectionHeader('메모'),
          SmartInputField(
            controller: _memoController,
            label: '메모 (선택)',
            prefixIcon: const Icon(Icons.note),
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
            maxLines: 3,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submitCost(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitCost,
              icon: Icon(_isEditing ? Icons.save : Icons.add_task),
              label: Text(_isEditing ? '수정 완료' : '정기지출 저장'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancelEditing,
                  child: const Text('편집 취소'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCostListHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            '고정비용 목록',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          tooltip: '편집 안내',
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('편집 방법'),
                content: const Text(
                  '목록 항목 오른쪽 ⋮ 메뉴에서 고정비용을 수정하거나 삭제할 수 있습니다.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('확인'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCostListItem(FixedCost cost, int index) {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            Icons.calendar_month,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(cost.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  if (cost.vendor != null && cost.vendor!.isNotEmpty)
                    '납부처: ${cost.vendor}',
                  '결제: ${cost.paymentMethod}',
                  if (cost.dueDay != null) '납부일: 매월 ${cost.dueDay}일',
                ].join(' · '),
              ),
              if (cost.memo != null && cost.memo!.isNotEmpty)
                Text('메모: ${cost.memo}'),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                CurrencyFormatter.format(cost.amount),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              PopupMenuButton<_FixedCostAction>(
                onSelected: (action) {
                  switch (action) {
                    case _FixedCostAction.record:
                      _recordCostAsTransaction(cost);
                      break;
                    case _FixedCostAction.edit:
                      _startEditing(cost, index);
                      break;
                    case _FixedCostAction.delete:
                      _deleteCost(index);
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _FixedCostAction.record,
                    child: Text('이번 달 지출로 기록'),
                  ),
                  PopupMenuItem(
                    value: _FixedCostAction.edit,
                    child: Text('수정'),
                  ),
                  PopupMenuItem(
                    value: _FixedCostAction.delete,
                    child: Text('삭제'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (index < _costs.length - 1) const Divider(height: 1),
      ],
    );
  }
}
