// ignore_for_file: invalid_use_of_protected_member
part of 'account_stats_screen.dart';

/// 고정비용 섹션 + 월/년/차트 네비게이터.
extension AccountStatsFixedCostNav on _AccountStatsScreenState {
  double _fixedCostTotalForMonth(DateTime _) {
    if (_fixedCosts.isEmpty) return 0.0;
    return _fixedCosts.fold<double>(
        0.0, (prev, cost) => prev + cost.amount);
  }

  List<FixedCost> _sortedFixedCosts() {
    final list = List<FixedCost>.from(_fixedCosts);
    list.sort((a, b) {
      final dayA = a.dueDay ?? 0;
      final dayB = b.dueDay ?? 0;
      if (dayA != dayB) return dayA.compareTo(dayB);
      return a.name.compareTo(b.name);
    });
    return list;
  }

  Widget _buildFixedCostSection(ThemeData theme,
      {bool annual = false}) {
    final costs = _sortedFixedCosts();
    final ref = annual ? DateTime(_currentYear) : _currentMonth;
    final monthlyTotal = _fixedCostTotalForMonth(ref);
    final total = annual ? monthlyTotal * 12 : monthlyTotal;
    final titlePrefix = annual ? '연간' : '등록된';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$titlePrefix 고정비용 '
          '(${_formatAmountByType(total, TransactionType.expense)})',
          style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: costs
                .map((cost) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.receipt_long),
                      title: Text(cost.name),
                      subtitle: Text(_fixedCostSubtitle(cost)),
                      trailing: Text(_formatAmountByType(
                          cost.amount, TransactionType.expense)),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  String _fixedCostSubtitle(FixedCost cost) {
    final parts = <String>[];
    if (cost.paymentMethod.isNotEmpty) parts.add(cost.paymentMethod);
    if (cost.vendor != null && cost.vendor!.trim().isNotEmpty) {
      parts.add(cost.vendor!.trim());
    }
    if (cost.dueDay != null) parts.add('매월 ${cost.dueDay}일');
    if (cost.memo != null && cost.memo!.trim().isNotEmpty) {
      parts.add(cost.memo!.trim());
    }
    return parts.isEmpty ? '추가 정보 없음' : parts.join(' · ');
  }

  Widget _buildMonthNavigator(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _currentMonth = DateTime(
                  _currentMonth.year, _currentMonth.month - 1);
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_monthLabelFormat.format(_currentMonth),
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _currentMonth = DateTime(
                  _currentMonth.year, _currentMonth.month + 1);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildYearNavigator(ThemeData theme, {String? label}) {
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _currentYear -= 1;
              if (_selectedView == StatsView.decade) {
                _currentMonth =
                    DateTime(_currentYear, _currentMonth.month);
              }
            }),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(label ?? '$_currentYear년',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary)),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _currentYear += 1;
              if (_selectedView == StatsView.decade) {
                _currentMonth =
                    DateTime(_currentYear, _currentMonth.month);
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildChartNavigator(
      ThemeData theme, DateTime start, DateTime end) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() {
            _chartAnchorMonth = DateTime(
                _chartAnchorMonth.year,
                _chartAnchorMonth.month - 12);
          }),
        ),
        Text(
          '${_rangeMonthFormat.format(start)} ~ '
          '${_rangeMonthFormat.format(end)}',
          style: theme.textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(() {
            _chartAnchorMonth = DateTime(
                _chartAnchorMonth.year,
                _chartAnchorMonth.month + 12);
          }),
        ),
      ],
    );
  }
}
