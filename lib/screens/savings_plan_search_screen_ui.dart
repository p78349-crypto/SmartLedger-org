// ignore_for_file: invalid_use_of_protected_member
part of savings_plan_search_screen;

extension _SavingsPlanSearchScreenUi on _SavingsPlanSearchScreenState {
  Widget _buildScaffold(BuildContext context) {
    final filteredPlans = _getFilteredPlans();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.accountName} - 예금 목록'),
      ),
      body: Column(
        children: [
          _buildHeader(theme, scheme),
          _buildSearchField(),
          Expanded(child: _buildPlansList(filteredPlans, scheme)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(scheme),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '예금 목록',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          TextButton(
            onPressed: _toggleSelectionMode,
            child: Text(_isSelectionMode ? '취소' : '선택'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: '계획명으로 검색',
          border: const OutlineInputBorder(),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
        ),
        onChanged: (_) {
          _searchDebouncer.run(() {
            if (!mounted) return;
            setState(() {});
          });
        },
      ),
    );
  }

  Widget _buildPlansList(List<SavingsPlan> filteredPlans, ColorScheme scheme) {
    if (filteredPlans.isEmpty) {
      return const Center(
        child: Text('예금 계획이 없습니다.', style: TextStyle()),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredPlans.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final plan = filteredPlans[index];
        return _buildPlanCard(plan, scheme);
      },
    );
  }

  Widget _buildPlanCard(SavingsPlan plan, ColorScheme scheme) {
    final progress = plan.termMonths > 0
        ? plan.paidCount / plan.termMonths
        : 0.0;
    final monthly = _currencyFormat.format(plan.monthlyAmount);
    final totalDeposited = _currencyFormat.format(plan.depositedAmount);
    final maturityStr = _dateFormat.format(plan.maturityDate);
    final isSelected = _selectedIds.contains(plan.id);

    final progressColor = progress >= 1.0 ? scheme.primary : scheme.tertiary;

    return Card(
      child: InkWell(
        onTap: _isSelectionMode ? () => _toggleSelection(plan.id) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlanHeaderRow(plan, isSelected, scheme),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: scheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '월 $monthly원',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  Text(
                    '총 $totalDeposited원',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: scheme.tertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '만기일: $maturityStr',
                style: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (plan.autoDeposit) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '자동이체',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanHeaderRow(
    SavingsPlan plan,
    bool isSelected,
    ColorScheme scheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_isSelectionMode)
          Checkbox(
            value: isSelected,
            onChanged: (_) => _toggleSelection(plan.id),
          ),
        Expanded(
          child: Text(
            plan.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          '${plan.paidCount}/${plan.termMonths}회',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget? _buildBottomBar(ColorScheme scheme) {
    final shouldShow = _isSelectionMode && _selectedIds.isNotEmpty;
    if (!shouldShow) return null;

    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _deleteSelected,
                icon: const Icon(Icons.delete),
                label: Text('삭제 (${_selectedIds.length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _selectedIds.length == 1 ? _editSelected : null,
                icon: const Icon(Icons.edit),
                label: const Text('수정'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
