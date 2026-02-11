// ignore_for_file: invalid_use_of_protected_member
part of 'income_split_screen.dart';

/// Extension: main build widget tree.
extension IncomeSplitBuild on _IncomeSplitScreenState {
  Widget _buildMain(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('수입 배분 설정'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(alignment: Alignment.center, children: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'detail') {
                    Navigator.of(context).pushNamed(
                      AppRoutes.incomeSplitStatus,
                      arguments: {'accountName': _targetAccount});
                  } else if (value == 'asset') {
                    Navigator.of(context).pushNamed('/asset/dashboard');
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'detail', child: Row(children: [
                    Icon(Icons.payments_outlined, size: 20),
                    SizedBox(width: 8), Text('수입배분 상세')])),
                  const PopupMenuItem(value: 'asset', child: Row(children: [
                    Icon(Icons.account_balance_wallet, size: 20),
                    SizedBox(width: 8), Text('자산')])),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'save', enabled: _isValid,
                    onTap: _isValid ? _save : null,
                    child: Row(children: [
                      Icon(Icons.save_outlined, size: 20,
                        color: _isValid ? null : Colors.grey),
                      const SizedBox(width: 8),
                      Text('저장', style: TextStyle(
                        color: _isValid ? null : Colors.grey)),
                    ])),
                ],
              ),
            ]),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_totalIncome == 0 && _total == 0 && _incomeAllocations.isEmpty) ...[
                Card(
                  color: scheme.surfaceContainerLow,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('💡 이번 달 수입을 어떻게 배분하시겠어요?',
                          style: TextStyle(fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface)),
                        const SizedBox(height: 8),
                        Text('총 수입을 예금, 지출예산, 비상금으로 나누어 관리하세요.\n예산이 자동으로 설정됩니다.',
                          style: TextStyle(fontSize: 13,
                            color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            if (_availableAccounts.length > 1) ...[
              const Text('어느 계정에 배분하시겠어요?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _targetAccount,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance)),
                items: _availableAccounts.map((a) =>
                  DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() {
                    _targetAccount = v;
                    _loadExisting();
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
            // Total income field
            SmartInputField(
              label: '💰 총 수입', hint: '이번 달 총 수입을 입력하세요',
              controller: _incomeController, focusNode: _incomeFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CurrencyInputFormatter(),
              ],
              suffixText: '원', prefixIcon: const Icon(Icons.attach_money),
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_savingsFocusNode)),
            if (_totalIncome == 0 && _total > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('총 수입을 비워두면 입력하신 합계가 총 수입으로 자동 설정됩니다',
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('배분 계획',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSplitField(
              label: '🌱 예금 (예금)', hint: '은행 예금할 금액',
              controller: _savingsController, focusNode: _savingsFocusNode,
              icon: Icons.savings,
              nextFocus: _budgetFocusNode),
            const SizedBox(height: 12),
            _buildSplitField(
              label: '💳 지출 예산', hint: '생활비로 쓸 금액',
              controller: _budgetController, focusNode: _budgetFocusNode,
              icon: Icons.shopping_cart,
              nextFocus: _emergencyFocusNode),
            const SizedBox(height: 12),
            const SizedBox(height: 12),
            _buildSplitField(
              label: '🚨 비상금', hint: '비상시를 위한 금액',
              controller: _emergencyController, focusNode: _emergencyFocusNode,
              icon: Icons.warning_amber,
              nextFocus: _assetFocusNode),
            const SizedBox(height: 12),
            SmartInputField(
              label: '🏦 자산 이동', hint: '자산으로 옮길 금액',
              controller: _assetController, focusNode: _assetFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CurrencyInputFormatter(),
              ],
              suffixText: '원',
              prefixIcon: const Icon(Icons.account_balance_wallet),
              onFieldSubmitted: (_) => FocusScope.of(context).unfocus()),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text('저장 시 입력한 금액만큼 자산 탭으로 자동 이동합니다',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
            const SizedBox(height: 18),
            _buildTotalSummaryCard(scheme),
            const SizedBox(height: 16),
            _buildSectionWithSheet(
              title: '지출 카테고리 배분',
              buttonLabel: '카테고리 편집',
              buttonIcon: Icons.tune,
              onPressed: _openCategoryBudgetSheet,
              emptyText: '지출 예산을 카테고리별로 나누면 수입 배분 상세 화면에서 계획 대비 사용량을 바로 확인할 수 있어요.',
              isEmpty: _categoryBudgets.isEmpty,
              card: _categoryBudgets.isEmpty ? null : _buildCategoryBudgetCard(),
              scheme: scheme),
            const SizedBox(height: 24),
            _buildSectionWithSheet(
              title: '수입 항목 배분',
              buttonLabel: '수입 항목 편집',
              buttonIcon: Icons.segment,
              onPressed: _openIncomeAllocationSheet,
              emptyText: '급여, 부수입 등을 나누어 입력하면 수입 배분 현황에서 항목별 기여도를 확인할 수 있습니다.',
              isEmpty: _incomeAllocations.isEmpty,
              card: _incomeAllocations.isEmpty
                  ? null : _buildIncomeAllocationCard(),
              scheme: scheme),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required FocusNode nextFocus,
  }) {
    return SmartInputField(
      label: label, hint: hint,
      controller: controller, focusNode: focusNode,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _CurrencyInputFormatter(),
      ],
      suffixText: '원', prefixIcon: Icon(icon),
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(nextFocus));
  }

  Widget _buildTotalSummaryCard(ColorScheme scheme) {
    return Card(
      color: _isValid
          ? scheme.primaryContainer
          : (_totalIncome > 0
              ? scheme.errorContainer
              : scheme.surfaceContainerLow),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('총 수입',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Text(CurrencyFormatter.format(_totalIncome),
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            _buildSummaryInline(_savings, _budget, _emergency, _assetTransfer),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('배분 합계',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Text(CurrencyFormatter.format(_total),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                    color: _isValid ? Colors.green : Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_remaining >= 0 ? '남은 금액' : '초과 금액',
                  style: TextStyle(fontWeight: FontWeight.bold,
                    color: _remaining >= 0 ? Colors.green : Colors.red)),
                Text(CurrencyFormatter.formatSigned(_remaining),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                    color: _remaining >= 0 ? Colors.green : Colors.red)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionWithSheet({
    required String title,
    required String buttonLabel,
    required IconData buttonIcon,
    required VoidCallback onPressed,
    required String emptyText,
    required bool isEmpty,
    required Widget? card,
    required ColorScheme scheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
              style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
            OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(buttonIcon),
              label: Text(buttonLabel)),
          ],
        ),
        const SizedBox(height: 8),
        if (isEmpty)
          Text(emptyText,
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))
        else
          card!,
      ],
    );
  }
}
