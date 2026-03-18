part of 'account_stats_screen.dart';

/// 마트/쇼핑몰별 제품 인라인 위젯.
extension AccountStatsStoreProducts on _AccountStatsScreenState {
  Widget _buildStoreProductsInline(ThemeData theme, List<Transaction> txs) {
    final store = _defaultStore;
    if (store == null || store.trim().isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '마트/쇼핑몰명이 기록된 거래가 없습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    final start = _monthStart(_currentMonth);
    final endEx = _monthEndExclusive(_currentMonth);
    var thisMonthTotal = 0.0;
    var thisMonthCount = 0;
    final byKey = <String, StoreProductAcc>{};
    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      if (t.isRefund) continue;
      final raw = _storeKeyOf(t);
      if (raw == null) continue;
      final canonical = StoreAliasService.resolve(raw, _storeAliasMap);
      if (canonical != store) continue;
      if (t.date.isBefore(start) || !t.date.isBefore(endEx)) continue;
      thisMonthCount += 1;
      thisMonthTotal += t.amount;
      final key = ProductNameUtils.normalizeKey(t.description);
      if (key.isEmpty) continue;
      final acc = byKey.putIfAbsent(
        key,
        () => StoreProductAcc(name: t.description.trim()),
      );
      acc.count += 1;
      acc.total += t.amount;
      final name = t.description.trim();
      if (name.isNotEmpty && acc.name.length < name.length) acc.name = name;
    }
    final items =
        byKey.values
            .map(
              (a) => StoreProductStat(
                name: a.name,
                count: a.count,
                total: a.total,
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.total.compareTo(a.total));
    final top = items.take(20).toList(growable: false);
    final maxAmount = top.fold<double>(0, (m, e) => e.total > m ? e.total : m);
    final denom = maxAmount <= 0 ? 1.0 : maxAmount;

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
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: theme.colorScheme.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '기본 마트/쇼핑몰: $store',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatWon(thisMonthTotal),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$thisMonthCount건의 거래',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            if (top.isEmpty)
              Text(
                '이번달 제품 데이터가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...top.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final item = entry.value;
                final pct = (item.total / denom).clamp(0.0, 1.0);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '$rank. ${item.name}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: rank <= 20
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatWon(item.total),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: pct,
                          color: theme.colorScheme.primary,
                          backgroundColor: theme.colorScheme.primary.withValues(
                            alpha: 0.12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.count}건',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
