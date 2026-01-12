part of category_stats_screen;

extension CategoryStatsScreenBuilders on _CategoryStatsScreenState {
  Widget _buildPeriodSelector(ThemeData theme, period.DateTimeRange range) {
    String label = '';
    final df = DateFormats.monthDayLabel;
    final mf = DateFormats.yMLabel;

    switch (widget.periodType) {
      case period.PeriodType.week:
        label = '${df.format(range.start)} ~ ${df.format(range.end)}';
        break;
      case period.PeriodType.month:
        label = mf.format(_anchorDate);
        break;
      case period.PeriodType.quarter:
        final quarter = ((_anchorDate.month - 1) ~/ 3) + 1;
        label = '${_anchorDate.year}년 $quarter분기';
        break;
      case period.PeriodType.halfYear:
        final half = _anchorDate.month <= 6 ? '상반기' : '하반기';
        label = '${_anchorDate.year}년 $half';
        break;
      case period.PeriodType.year:
        label = '${_anchorDate.year}년';
        break;
      case period.PeriodType.decade:
        final startYear = (_anchorDate.year ~/ 10) * 10;
        label = '$startYear ~ ${startYear + 9}';
        break;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changePeriod(-1),
          ),
          Text(label, style: theme.textTheme.titleLarge),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changePeriod(1),
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '카테고리가 없습니다',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    List<CategoryStats> categoryStats,
    ThemeData theme,
  ) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categoryStats.length,
      itemBuilder: (context, index) {
        final stats = categoryStats[index];
        final color = ChartColors.getColorForIndex(index, theme);

        if (isLandscape) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: color.withValues(alpha: 0.2),
                    child: Icon(
                      _getIconForCategory(stats.category),
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: Text(
                      stats.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${stats.count}건',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      CurrencyFormatter.format(stats.total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${stats.percentage.toStringAsFixed(1)}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(
                    _getIconForCategory(stats.category),
                    color: color,
                    size: 20,
                  ),
                ),
                title: Text(
                  stats.category,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text('${stats.count}건'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(stats.total),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      '${stats.percentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.percentage / 100,
                    minHeight: 8,
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForCategory(String category) {
    final iconMap = {
      '식비': Icons.restaurant,
      '교통': Icons.directions_car,
      '쇼핑': Icons.shopping_cart,
      '문화': Icons.movie,
      '의료': Icons.local_hospital,
      '교육': Icons.school,
      '주거': Icons.home,
      '통신': Icons.phone,
      '기타': Icons.more_horiz,
    };
    return iconMap[category] ?? Icons.category;
  }
}
