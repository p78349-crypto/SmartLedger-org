part of 'spending_analysis_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension SpendingAnalysisTopSpending on _SpendingAnalysisScreenState {
  // === TAB 1: TOP 지출 ===
  Widget buildTopSpendingTab(ThemeData theme) {
    final range = period.PeriodUtils.getPeriodRange(
      _periodType,
      baseDate: _anchorDate,
    );

    // TOP 5 품목
    final topItems = SpendingAnalysisUtils.getTopSpendingItems(
      transactions: _allTransactions,
      startDate: range.start,
      endDate: range.end,
    );

    // TOP 5 카테고리
    final topCategories = SpendingAnalysisUtils.getTopSpendingCategories(
      transactions: _allTransactions,
      currentMonth: _anchorDate,
    );

    // TOP 5 상점
    final topStores = SpendingAnalysisUtils.getTopSpendingStores(
      transactions: _allTransactions,
      startDate: range.start,
      endDate: range.end,
    );

    if (topItems.isEmpty && topCategories.isEmpty) {
      return buildEmptyState(theme, '해당 기간 지출 내역이 없습니다');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP 5 품목 차트
          buildSectionTitle(theme, 'TOP 5 품목', Icons.shopping_bag),
          const SizedBox(height: 12),
          if (topItems.isNotEmpty) ...[
            _buildBarChart(topItems, theme),
            const SizedBox(height: 16),
            _buildTopItemsList(topItems, theme),
          ] else
            buildEmptyCard(theme, '품목 데이터가 없습니다'),

          const SizedBox(height: 24),

          // TOP 5 카테고리
          buildSectionTitle(theme, 'TOP 5 카테고리', Icons.category),
          const SizedBox(height: 12),
          if (topCategories.isNotEmpty)
            _buildCategorySummaryList(topCategories, theme)
          else
            buildEmptyCard(theme, '카테고리 데이터가 없습니다'),

          const SizedBox(height: 24),

          // TOP 5 상점
          buildSectionTitle(theme, 'TOP 5 상점', Icons.store),
          const SizedBox(height: 12),
          if (topStores.isNotEmpty)
            _buildStoreList(topStores, theme)
          else
            buildEmptyCard(theme, '상점 데이터가 없습니다'),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<ItemSpendingAnalysis> items, ThemeData theme) {
    if (items.isEmpty) return const SizedBox.shrink();

    final maxValue = items.first.totalAmount;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final item = items[group.x];
                return BarTooltipItem(
                  '${item.name}\n${_currencyFormat.format(item.totalAmount)}',
                  TextStyle(color: theme.colorScheme.onSurface, fontSize: 12),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= items.length) {
                    return const SizedBox.shrink();
                  }
                  final name = items[idx].name;
                  final displayName = name.length > 6
                      ? '${name.substring(0, 6)}...'
                      : name;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      displayName,
                      style: theme.textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    NumberFormat.compact(locale: 'ko').format(value),
                    style: theme.textTheme.labelSmall,
                  );
                },
                reservedSize: 50,
              ),
            ),
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
          ),
          borderData: FlBorderData(),
          barGroups: List.generate(items.length, (index) {
            final item = items[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: item.totalAmount,
                  color: ChartColors.getColorForIndex(index, theme),
                  width: 24,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTopItemsList(List<ItemSpendingAnalysis> items, ThemeData theme) {
    return Card(
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final avgAmountText = _currencyFormat.format(item.avgAmount);
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: ChartColors.getColorForIndex(index, theme),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(item.name),
            subtitle: Text('${item.count}회 구매 · 평균 $avgAmountText'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(item.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${item.percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategorySummaryList(
    List<CategorySpendingSummary> categories,
    ThemeData theme,
  ) {
    return Card(
      child: Column(
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final cat = entry.value;
          final changePrefix = cat.monthOverMonthChange >= 0 ? '+' : '';
          final changeText =
              '$changePrefix${cat.monthOverMonthChange.toStringAsFixed(0)}%';

          // 전월 대비 변동 표시
          final changeIcon = cat.monthOverMonthChange > 0
              ? Icons.trending_up
              : (cat.monthOverMonthChange < 0
                    ? Icons.trending_down
                    : Icons.trending_flat);
          final changeColor = cat.monthOverMonthChange > 10
              ? theme.colorScheme.error
              : (cat.monthOverMonthChange < -10
                    ? Colors.green
                    : theme.colorScheme.onSurfaceVariant);

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: ChartColors.getColorForIndex(index, theme),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(cat.category),
            subtitle: Row(
              children: [
                Text('${cat.transactionCount}건'),
                const SizedBox(width: 8),
                Icon(changeIcon, size: 16, color: changeColor),
                Text(
                  changeText,
                  style: TextStyle(color: changeColor, fontSize: 12),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _currencyFormat.format(cat.totalAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${cat.percentage.toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStoreList(List<ItemSpendingAnalysis> stores, ThemeData theme) {
    return Card(
      child: Column(
        children: stores.asMap().entries.map((entry) {
          final index = entry.key;
          final store = entry.value;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: ChartColors.getColorForIndex(index, theme),
              child: const Icon(Icons.store, color: Colors.white, size: 18),
            ),
            title: Text(store.name),
            subtitle: Text('${store.count}회 방문'),
            trailing: Text(
              _currencyFormat.format(store.totalAmount),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
