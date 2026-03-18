// ignore_for_file: invalid_use_of_protected_member
part of 'income_split_screen.dart';

/// Extension: main build widget tree.
extension IncomeSplitBuild on _IncomeSplitScreenState {
  Widget _buildMain(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('수입 배분'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'usage') {
                      _showUsageGuide();
                    } else if (value == 'category_edit') {
                      _openCategoryBudgetSheet();
                    } else if (value == 'income_edit') {
                      _openIncomeAllocationSheet();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'usage',
                      child: Row(
                        children: [
                          Icon(Icons.help_outline, size: 20),
                          SizedBox(width: 8),
                          Text('사용법'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'category_edit',
                      child: Row(
                        children: [
                          Icon(Icons.tune, size: 20),
                          SizedBox(width: 8),
                          Text('카테고리 배분'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'income_edit',
                      child: Row(
                        children: [
                          Icon(Icons.segment, size: 20),
                          SizedBox(width: 8),
                          Text('수입을 자산으로'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isValid ? _save : null,
        backgroundColor: _isValid
            ? scheme.primary
            : scheme.surfaceContainerHighest,
        foregroundColor: _isValid ? scheme.onPrimary : scheme.onSurfaceVariant,
        elevation: 2,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        icon: const Icon(Icons.save_outlined, size: 20),
        label: const Text(
          '저장',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTotalSummaryCard(scheme),
            const SizedBox(height: 12),
            if (_availableAccounts.length > 1) ...[
              const Text(
                '어느 계정에 배분하시겠어요?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _targetAccount,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
                items: _availableAccounts
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _targetAccount = v;
                      _loadExisting();
                    });
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
            // Total income field
            SmartInputField(
              label: '💰 총 수입',
              hint: '이번 달 총 수입을 입력하세요',
              controller: _incomeController,
              focusNode: _incomeFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CurrencyInputFormatter(),
              ],
              suffixText: '원',
              prefixIcon: const Icon(Icons.attach_money),
              onFieldSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_savingsFocusNode),
            ),
            if (_totalIncome == 0 && _total > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '총 수입을 비워두면 입력하신 합계가 총 수입으로 자동 설정됩니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildSplitField(
              label: '🌱 예금 (예금)',
              hint: '은행 예금할 금액',
              controller: _savingsController,
              focusNode: _savingsFocusNode,
              icon: Icons.savings,
              nextFocus: _budgetFocusNode,
            ),
            const SizedBox(height: 10),
            _buildSplitField(
              label: '💳 지출 예산',
              hint: '생활비로 쓸 금액',
              controller: _budgetController,
              focusNode: _budgetFocusNode,
              icon: Icons.shopping_cart,
              nextFocus: _emergencyFocusNode,
            ),
            const SizedBox(height: 10),
            _buildSplitField(
              label: '🚨 비상금',
              hint: '비상시를 위한 금액',
              controller: _emergencyController,
              focusNode: _emergencyFocusNode,
              icon: Icons.warning_amber,
              nextFocus: _assetFocusNode,
            ),
            const SizedBox(height: 10),
            SmartInputField(
              label: '🏦 자산 이동',
              hint: '자산으로 옮길 금액',
              controller: _assetController,
              focusNode: _assetFocusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _CurrencyInputFormatter(),
              ],
              suffixText: '원',
              prefixIcon: const Icon(Icons.account_balance_wallet),
              onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),

            const SizedBox(height: 12),
            _buildSectionWithSheet(
              isEmpty: _categoryBudgets.isEmpty,
              card: _categoryBudgets.isEmpty
                  ? null
                  : _buildCategoryBudgetCard(),
              scheme: scheme,
            ),
            const SizedBox(height: 16),
            _buildSectionWithSheet(
              isEmpty: _incomeAllocations.isEmpty,
              card: _incomeAllocations.isEmpty
                  ? null
                  : _buildIncomeAllocationCard(),
              scheme: scheme,
            ),
            const SizedBox(height: 16),
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
      label: label,
      hint: hint,
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _CurrencyInputFormatter(),
      ],
      suffixText: '원',
      prefixIcon: Icon(icon),
      onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(nextFocus),
    );
  }

  Widget _buildTotalSummaryCard(ColorScheme scheme) {
    return Card(
      color: _isValid
          ? scheme.primaryContainer
          : (_totalIncome > 0
                ? scheme.errorContainer
                : scheme.surfaceContainerLow),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '총 수입',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  CurrencyFormatter.format(_totalIncome),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 8),
            _buildSummaryInline(_savings, _budget, _emergency, _assetTransfer),
            const Divider(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '배분 합계',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  CurrencyFormatter.format(_total),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isValid ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _remaining >= 0 ? '남은 금액' : '초과 금액',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _remaining >= 0 ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  CurrencyFormatter.formatSigned(_remaining),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _remaining >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionWithSheet({
    required bool isEmpty,
    required Widget? card,
    required ColorScheme scheme,
  }) {
    if (isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [card!],
    );
  }
}
