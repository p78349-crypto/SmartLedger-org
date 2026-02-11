part of 'input_stats_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension InputStatsScreenBenefitType on _InputStatsScreenState {
  Widget _buildBenefitTypeStats(ThemeData theme) {
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

    final lookbackByType = <String, _AggAcc>{};
    final thisMonthByType = <String, _AggAcc>{};

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

    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      if (t.isRefund) continue;

      final byType = mapFor(t);
      if (byType.isEmpty) continue;

      for (final e in byType.entries) {
        final key = e.key.trim();
        final value = e.value;
        if (key.isEmpty) continue;
        if (value <= 0) continue;

        final acc = lookbackByType.putIfAbsent(key, () => _AggAcc(name: key));
        acc.total += value;
        acc.count += 1;

        if (!t.date.isBefore(monthStart)) {
          final accMonth = thisMonthByType.putIfAbsent(
            key,
            () => _AggAcc(name: key),
          );
          accMonth.total += value;
          accMonth.count += 1;
        }
      }
    }

    if (lookbackByType.isEmpty) {
      return Text(
        '표시할 혜택 데이터가 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final lookbackItems =
        lookbackByType.values
            .map(
              (a) =>
                  _AggStat(name: a.name, count: a.count, totalAmount: a.total),
            )
            .toList(growable: false)
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final monthItems =
        thisMonthByType.values
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
    final lookbackTotal = lookbackItems.fold<double>(
      0,
      (sum, e) => sum + e.totalAmount,
    );

    final denom =
        (lookbackItems.isEmpty ? 1.0 : lookbackItems.first.totalAmount).clamp(
          1.0,
          double.infinity,
        );

    final top = lookbackItems.take(10).toList(growable: false);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('혜택 종류별 상위10', style: theme.textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(
              '이번달 합계: ${_formatWon(thisMonthTotal)}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '최근 6개월: ${_formatWon(lookbackTotal)} · '
              '${lookbackItems.length}종류',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
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
