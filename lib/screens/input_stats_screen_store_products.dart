part of 'input_stats_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension InputStatsScreenStoreProducts on _InputStatsScreenState {
  Widget _buildStoreProductStats(ThemeData theme) {
    final txs = _txs;
    if (txs.isEmpty) {
      return Text(
        '최근 6개월 내 거래가 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final stores = <String>{};
    for (final t in txs) {
      final store = _resolvedStoreKeyOf(t);
      if (store == null) continue;
      stores.add(store);
    }
    final storeList = stores.toList(growable: false)..sort();

    if (storeList.isEmpty) {
      return Text(
        '마트/쇼핑몰명이 메모에 기록된 거래가 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final selected = (_selectedStore != null && stores.contains(_selectedStore))
        ? _selectedStore!
        : storeList.first;

    final monthStart = _startOfThisMonth();

    var thisMonthTotal = 0.0;
    var thisMonthCount = 0;
    var lookbackTotal = 0.0;
    var lookbackCount = 0;

    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      if (t.isRefund) continue;

      final storeKey = _resolvedStoreKeyOf(t);
      if (storeKey == null || storeKey != selected) continue;

      lookbackCount += 1;
      lookbackTotal += t.amount;

      if (t.date.isBefore(monthStart)) continue;

      thisMonthCount += 1;
      thisMonthTotal += t.amount;
    }

    final stats = _buildStoreProductAgg(txs, selected, monthStart);
    final maxAmount = stats
        .map((e) => e.totalAmount)
        .fold<double>(0, (m, v) => v > m ? v : m);
    final denom = maxAmount <= 0 ? 1.0 : maxAmount;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('마트/쇼핑몰별 제품 상위20', style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            Text(
              '이번달 총액: ${_formatWon(thisMonthTotal)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '(1달) · 이번달 $thisMonthCount건',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '최근 6개월: ${_formatWon(lookbackTotal)} · $lookbackCount건',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: ValueKey(selected),
              initialValue: selected,
              decoration: const InputDecoration(
                labelText: '마트/쇼핑몰 선택',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final s in storeList)
                  DropdownMenuItem<String>(
                    value: s,
                    child: Text(s, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _selectedStore = v;
                });
              },
            ),
            const SizedBox(height: 12),
            if (stats.isEmpty)
              Text(
                '이번달 제품 데이터가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...stats.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final item = entry.value;
                return _buildRankRow(
                  theme,
                  rank: rank,
                  title: item.name,
                  amount: item.totalAmount,
                  count: item.count,
                  denom: denom,
                );
              }),
          ],
        ),
      ),
    );
  }

  List<_AggStat> _buildStoreProductAgg(
    List<Transaction> txs,
    String store,
    DateTime start,
  ) {
    final byKey = <String, _AggAcc>{};
    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      if (t.isRefund) continue;
      if (t.date.isBefore(start)) continue;

      final storeKey = _resolvedStoreKeyOf(t);
      if (storeKey == null || storeKey != store) continue;

      final key = ProductNameUtils.normalizeKey(t.description);
      if (key.isEmpty) continue;

      final acc = byKey.putIfAbsent(
        key,
        () => _AggAcc(name: t.description.trim()),
      );
      acc.count += 1;
      acc.total += t.amount;

      final name = t.description.trim();
      if (name.isNotEmpty && acc.name.length < name.length) {
        acc.name = name;
      }
    }

    final items =
        byKey.values
            .map(
              (a) =>
                  _AggStat(name: a.name, count: a.count, totalAmount: a.total),
            )
            .toList(growable: false)
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return items;
  }
}
