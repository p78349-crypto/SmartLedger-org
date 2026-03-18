part of 'account_stats_screen.dart';

/// 월별 뷰 및 간편 지출 인라인.
extension AccountStatsMonthlyView on _AccountStatsScreenState {
  Widget _buildMonthlyView(List<Transaction> transactions, ThemeData theme) {
    final summary = _calculateMonthlySummary(transactions, _currentMonth);
    final monthlyTx = _transactionsForMonth(transactions, _currentMonth);
    final typeTx =
        monthlyTx
            .where((tx) => _shouldAggregateForType(tx, _currentType))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final dayGroups = <DateTime, List<Transaction>>{};
    for (final tx in typeTx) {
      final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      dayGroups.putIfAbsent(day, () => <Transaction>[]).add(tx);
    }
    final orderedDays = dayGroups.keys.toList()..sort((a, b) => b.compareTo(a));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [_buildMonthNavigator(theme), _buildWeeklyCheckIcon(theme)],
        ),
        const SizedBox(height: 16),
        StatsSummaryGrid(children: _buildSummaryCards(summary, theme)),
        const SizedBox(height: 24),
        Text('일별 ${_typeLabel()}', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (orderedDays.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('이 달에 ${_typeLabel()} 거래가 없습니다.'),
            ),
          )
        else
          Column(
            children: orderedDays
                .map((day) => _buildDailyTile(day, dayGroups[day]!, theme))
                .toList(),
          ),
        if (_fixedCosts.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildFixedCostSection(theme),
        ],
        const SizedBox(height: 24),
        Text('간편 지출(1줄)', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _buildQuickInputInline(theme),
        const SizedBox(height: 24),
        Text('마트/쇼핑몰별 제품', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _buildStoreProductsInline(theme, transactions),
      ],
    );
  }

  Widget _buildQuickInputInline(ThemeData theme) {
    if (_quickEntries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '저장된 1줄 입력이 없습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final start = _monthStart(_currentMonth);
    final endEx = _monthEndExclusive(_currentMonth);
    final inMonth = _quickEntries
        .where(
          (e) => !e.createdAt.isBefore(start) && e.createdAt.isBefore(endEx),
        )
        .toList(growable: false);
    var total = 0.0;
    for (final e in inMonth) {
      total += e.amount;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bolt_outlined,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '이번 달 간편 지출 합계',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatWon(total),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${inMonth.length}건의 거래',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
