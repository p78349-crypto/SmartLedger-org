// ignore_for_file: invalid_use_of_protected_member
part of 'account_stats_screen.dart';

/// 유형별 상세 뷰 (헤더 + 네비게이션 + 총액 카드).
extension AccountStatsTypeDetail on _AccountStatsScreenState {
  Widget _buildTypeDetailView(
    List<Transaction> transactions,
    ThemeData theme,
    TransactionType type,
  ) {
    final startOfMonth = DateTime(_currentMonth.year, _currentMonth.month);
    final endOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final filtered = transactions.where((tx) {
      bool inRange;
      if (_selectedDate != null) {
        inRange =
            tx.date.year == _selectedDate!.year &&
            tx.date.month == _selectedDate!.month &&
            tx.date.day == _selectedDate!.day;
      } else {
        inRange =
            tx.date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            tx.date.isBefore(endOfMonth.add(const Duration(days: 1)));
      }
      return inRange && _shouldAggregateForType(tx, type);
    }).toList();

    final Map<String, double> categoryTotals = {};
    final Map<String, List<Transaction>> categoryTransactions = {};
    for (final tx in filtered) {
      final cat = tx.mainCategory;
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + tx.amount.abs();
      categoryTransactions.putIfAbsent(cat, () => []).add(tx);
    }
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = filtered.fold<double>(0, (sum, tx) => sum + tx.amount.abs());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => _selectedView = StatsView.month),
            ),
            Text(
              '${_typeLabel(type)} 상세',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTypeDetailMonthNav(theme),
        const SizedBox(height: 8),
        _buildTypeDetailDatePicker(theme, type),
        const SizedBox(height: 16),
        _buildTypeDetailTotalCard(theme, type, total, filtered, endOfMonth),
        const SizedBox(height: 24),
        ..._buildTypeDetailCategoryList(
          sortedCategories,
          categoryTransactions,
          total,
          type,
          theme,
        ),
      ],
    );
  }

  Widget _buildTypeDetailMonthNav(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() {
            _currentMonth = DateTime(
              _currentMonth.year,
              _currentMonth.month - 1,
            );
            _selectedDate = null;
          }),
        ),
        Text(
          _monthLabelFormat.format(_currentMonth),
          style: theme.textTheme.titleMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(() {
            _currentMonth = DateTime(
              _currentMonth.year,
              _currentMonth.month + 1,
            );
            _selectedDate = null;
          }),
        ),
      ],
    );
  }

  Widget _buildTypeDetailDatePicker(ThemeData theme, TransactionType type) {
    return Center(
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? _currentMonth,
              firstDate: DateTime(_currentMonth.year, _currentMonth.month),
              lastDate: DateTime(
                _currentMonth.year,
                _currentMonth.month + 1,
                0,
              ),
              locale: const Locale('ko', 'KR'),
              builder: (ctx, child) => Theme(
                data: theme.copyWith(
                  colorScheme: theme.colorScheme.copyWith(
                    primary: _typeColorFor(type, theme),
                  ),
                ),
                child: child!,
              ),
            );
            if (!mounted) return;
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _selectedDate != null ? Icons.event : Icons.calendar_today,
                  size: 20,
                  color: _typeColorFor(type, theme),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedDate != null
                      ? _dayLabelFormat.format(_selectedDate!)
                      : '날짜 선택',
                  style: TextStyle(
                    color: _typeColorFor(type, theme),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (_selectedDate != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 16,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(64),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: '전체 보기',
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _selectedDate = null),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeDetailTotalCard(
    ThemeData theme,
    TransactionType type,
    double total,
    List<Transaction> filtered,
    DateTime endOfMonth,
  ) {
    return Card(
      color: _typeColorFor(type, theme).withAlpha(25),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              _selectedDate != null
                  ? '${_dayLabelFormat.format(_selectedDate!)} '
                        '${_typeLabel(type)}'
                  : '총 ${_typeLabel(type)}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(total),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: _typeColorFor(type, theme),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${filtered.length}건의 거래',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (filtered.isNotEmpty && _selectedDate == null) ...[
              const Divider(height: 24),
              Text(
                '일일 평균',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatDailyAverage(total, endOfMonth.day),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: _typeColorFor(type, theme),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
