part of 'input_stats_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension InputStatsScreenQuickCategory on _InputStatsScreenState {
  Widget _buildQuickInputSummary(ThemeData theme) {
    if (_entries.isEmpty) {
      return Text(
        '최근 6개월 내 저장된 1줄 입력이 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final monthStart = _startOfThisMonth();
    final thisMonthEntries = _entries
        .where((e) => !e.createdAt.isBefore(monthStart))
        .toList(growable: false);

    var thisMonthTotal = 0.0;
    for (final e in thisMonthEntries) {
      thisMonthTotal += e.amount;
    }

    final byKey = <String, _QuickAgg>{};
    for (final e in thisMonthEntries) {
      final key = ProductNameUtils.normalizeKey(e.description);
      if (key.isEmpty) continue;

      final acc = byKey.putIfAbsent(
        key,
        () => _QuickAgg(name: e.description.trim()),
      );
      acc.count += 1;
      acc.totalAmount += e.amount;

      final name = e.description.trim();
      if (name.isNotEmpty && acc.name.length < name.length) {
        acc.name = name;
      }
    }

    final top20 =
        byKey.values
            .map(
              (a) => _QuickAggView(
                name: a.name,
                count: a.count,
                total: a.totalAmount,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.total.compareTo(a.total));
    final topList = top20.take(_topEmphasisRank).toList(growable: false);
    final restList = top20.length > _topEmphasisRank
        ? top20.sublist(_topEmphasisRank)
        : const <_QuickAggView>[];

    final maxAmount = top20
        .map((e) => e.total)
        .fold<double>(0, (m, v) => v > m ? v : m);
    final denom = maxAmount <= 0 ? 1.0 : maxAmount;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('간편지출 상위20', style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            Text(
              '이번달 총액: ${_formatWon(thisMonthTotal)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '(1달) · 이번달 ${thisMonthEntries.length}건 · '
              '전체(6개월) ${_entries.length}건',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            if (topList.isEmpty)
              Text(
                '이번달 저장된 1줄 입력이 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else ...[
              ...top20.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final item = entry.value;
                return _buildRankRow(
                  theme,
                  rank: rank,
                  title: item.name,
                  amount: item.total,
                  count: item.count,
                  denom: denom,
                );
              }),
              if (restList.isNotEmpty)
                Text(
                  '(21위부터는 중요도 낮음)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategory3TierStats(ThemeData theme) {
    final stats = _memoLookback;
    if (stats == null || stats.topCategories3Tier.isEmpty) {
      return const Card(
        child: Padding(padding: EdgeInsets.all(16), child: Text('데이터가 없습니다.')),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '최근 6개월 지출 기준 (상위 10개)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in stats.topCategories3Tier) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${entry.count}건',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatWon(entry.totalAmount),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (entry != stats.topCategories3Tier.last)
                const Divider(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Data Classes
// ============================================================

class _QuickAgg {
  String name;
  int count = 0;
  double totalAmount = 0;

  _QuickAgg({required this.name});
}

class _QuickAggView {
  final String name;
  final int count;
  final double total;

  const _QuickAggView({
    required this.name,
    required this.count,
    required this.total,
  });
}

class _AggStat {
  final String name;
  final int count;
  final double totalAmount;

  const _AggStat({
    required this.name,
    required this.count,
    required this.totalAmount,
  });
}

class _AggAcc {
  String name;
  int count = 0;
  double total = 0;

  _AggAcc({required this.name});
}
