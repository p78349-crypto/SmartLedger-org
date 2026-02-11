part of 'input_stats_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension InputStatsScreenBenefitByStore on _InputStatsScreenState {
  Widget _buildBenefitTypeByStoreStats(ThemeData theme) {
    final txs = _txs;
    if (txs.isEmpty) {
      return Text(
        '최근 6개월 내 거래가 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final monthStart = _startOfThisMonth();

    Map<String, double> mapFor(Transaction t) {
      final structured = BenefitMemoUtils.decodeBenefitJson(t.benefitJson);
      if (structured.isNotEmpty) return structured;

      final memo = BenefitMemoUtils.parseBenefitByType(t.memo);
      if (memo.isNotEmpty) return memo;

      final charged = t.cardChargedAmount;
      if (charged != null && charged > 0) {
        final diff = t.amount - charged;
        if (diff > 0) {
          return <String, double>{'제시-실결제': diff};
        }
      }

      return const <String, double>{};
    }

    final storeSet = <String>{};
    final lookback = <String, Map<String, _AggAcc>>{};
    final thisMonth = <String, Map<String, _AggAcc>>{};

    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      if (t.isRefund) continue;

      final store = _resolvedStoreKeyOf(t);
      if (store == null || store.trim().isEmpty) continue;

      final byType = mapFor(t);
      if (byType.isEmpty) continue;

      storeSet.add(store);

      final storeLook = lookback.putIfAbsent(store, () => <String, _AggAcc>{});
      final storeMonth = thisMonth.putIfAbsent(
        store,
        () => <String, _AggAcc>{},
      );

      for (final e in byType.entries) {
        final key = e.key.trim();
        final value = e.value;
        if (key.isEmpty) continue;
        if (value <= 0) continue;

        final acc = storeLook.putIfAbsent(key, () => _AggAcc(name: key));
        acc.total += value;
        acc.count += 1;

        if (!t.date.isBefore(monthStart)) {
          final accM = storeMonth.putIfAbsent(key, () => _AggAcc(name: key));
          accM.total += value;
          accM.count += 1;
        }
      }
    }

    if (storeSet.isEmpty) {
      return Text(
        '표시할 혜택 데이터가 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final storeList = storeSet.toList(growable: false)..sort();
    final selected =
        (_selectedBenefitStore != null &&
            storeSet.contains(_selectedBenefitStore))
        ? _selectedBenefitStore!
        : storeList.first;

    final lookMap = lookback[selected] ?? const <String, _AggAcc>{};
    final monthMap = thisMonth[selected] ?? const <String, _AggAcc>{};

    final lookItems =
        lookMap.values
            .map(
              (a) =>
                  _AggStat(name: a.name, count: a.count, totalAmount: a.total),
            )
            .toList(growable: false)
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final monthItems =
        monthMap.values
            .map(
              (a) =>
                  _AggStat(name: a.name, count: a.count, totalAmount: a.total),
            )
            .toList(growable: false)
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final thisMonthTotal = monthItems.fold<double>(
      0,
      (sum, e) => sum + e.totalAmount,
    );
    final lookbackTotal = lookItems.fold<double>(
      0,
      (sum, e) => sum + e.totalAmount,
    );

    final maxAmount = lookItems.isEmpty ? 0.0 : lookItems.first.totalAmount;
    final denom = (maxAmount <= 0 ? 1.0 : maxAmount);

    final top = lookItems.take(10).toList(growable: false);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('마트/쇼핑몰별 혜택 종류', style: theme.textTheme.bodySmall),
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
                  _selectedBenefitStore = v;
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              '이번달 합계: ${_formatWon(thisMonthTotal)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '최근 6개월: ${_formatWon(lookbackTotal)} · ${lookItems.length}종류',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (top.isEmpty)
              Text(
                '선택한 마트/쇼핑몰의 혜택 데이터가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...top.asMap().entries.map((entry) {
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
}
