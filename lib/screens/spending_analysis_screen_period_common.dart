part of 'spending_analysis_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension SpendingAnalysisPeriodCommon on _SpendingAnalysisScreenState {
  Widget buildPeriodSelector(ThemeData theme) {
    final range = period.PeriodUtils.getPeriodRange(
      _periodType,
      baseDate: _anchorDate,
    );
    String label = DateFormat('yyyy년 M월').format(_anchorDate);
    if (_periodType == period.PeriodType.week) {
      final df = DateFormat('M/d');
      label = '${df.format(range.start)} ~ ${df.format(range.end)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changePeriod(-1),
          ),
          GestureDetector(
            onTap: () => _showPeriodTypeSelector(theme),
            child: Row(
              children: [
                Text(label, style: theme.textTheme.titleLarge),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changePeriod(1),
          ),
        ],
      ),
    );
  }

  void _showPeriodTypeSelector(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('주간'),
            selected: _periodType == period.PeriodType.week,
            onTap: () {
              setState(() => _periodType = period.PeriodType.week);
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('월간'),
            selected: _periodType == period.PeriodType.month,
            onTap: () {
              setState(() => _periodType = period.PeriodType.month);
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  Widget buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildEmptyCard(ThemeData theme, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
