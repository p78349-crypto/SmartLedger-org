part of monthly_stats_screen;

extension MonthlyStatsScreenBuilders on _MonthlyStatsScreenState {
  Widget _buildMonthSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
          ),
          Text(
            DateFormats.yMLabel.format(_currentMonth),
            style: theme.textTheme.titleLarge,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('지출'),
                  icon: Icon(Icons.trending_down),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('수입'),
                  icon: Icon(Icons.trending_up),
                ),
                ButtonSegment(
                  value: TransactionType.savings,
                  label: Text('예금'),
                  icon: Icon(Icons.savings),
                ),
                ButtonSegment(
                  value: TransactionType.refund,
                  label: Text('환급'),
                  icon: Icon(RefundUtils.icon),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<TransactionType> selected) {
                if (selected.isNotEmpty) {
                  _changeType(selected.first);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(ThemeData theme, double total, int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            CurrencyFormatter.format(total),
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: _getTypeColor(_selectedType, theme),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count건의 거래',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '거래 내역이 없습니다',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyList(List<DailyStats> dailyStats, ThemeData theme) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final typeColor = _getTypeColor(_selectedType, theme);

    if (!isLandscape) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: dailyStats.length,
        itemBuilder: (context, index) {
          final stats = dailyStats[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: typeColor.withValues(alpha: 0.2),
                child: Text(
                  '${stats.date.day}',
                  style: TextStyle(
                    color: typeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                DateFormatter.formatMonthDay(stats.date),
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Text('${stats.transactions.length}건'),
              trailing: Text(
                CurrencyFormatter.format(stats.total),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
            ),
          );
        },
      );
    }

    Widget headerCell(String text, {required int flex, TextAlign? align}) {
      return Expanded(
        flex: flex,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    Widget rowCell(
      String text, {
      required int flex,
      TextAlign? align,
      TextStyle? style,
    }) {
      return Expanded(
        flex: flex,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: style,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              headerCell('일자', flex: 4),
              headerCell('건수', flex: 2, align: TextAlign.end),
              headerCell('합계', flex: 4, align: TextAlign.end),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            itemCount: dailyStats.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final stats = dailyStats[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    rowCell(
                      DateFormatter.formatMonthDay(stats.date),
                      flex: 4,
                      style: theme.textTheme.bodyMedium,
                    ),
                    rowCell(
                      '${stats.transactions.length}건',
                      flex: 2,
                      align: TextAlign.end,
                      style: theme.textTheme.bodyMedium,
                    ),
                    rowCell(
                      CurrencyFormatter.format(stats.total),
                      flex: 4,
                      align: TextAlign.end,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getTypeColor(TransactionType type, ThemeData theme) {
    switch (type) {
      case TransactionType.expense:
        return theme.colorScheme.error;
      case TransactionType.income:
        return Colors.green;
      case TransactionType.savings:
        return Colors.blue;
      case TransactionType.refund:
        return RefundUtils.color;
    }
  }
}
