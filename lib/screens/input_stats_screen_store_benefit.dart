part of 'input_stats_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

extension InputStatsScreenStoreBenefit on _InputStatsScreenState {
  Widget _buildStoreBenefitStats(ThemeData theme) {
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

    final lookbackByStore = <String, _AggAcc>{};
    final thisMonthByStore = <String, _AggAcc>{};

    for (final t in txs) {
      if (t.type != TransactionType.expense) continue;
      if (t.isRefund) continue;

      final store = _resolvedStoreKeyOf(t);
      if (store == null) continue;

      var benefit = 0.0;

      final structured = BenefitMemoUtils.decodeBenefitJson(t.benefitJson);
      if (structured.isNotEmpty) {
        benefit = structured.values.fold<double>(0, (s, v) => s + v);
      } else {
        final memo = BenefitMemoUtils.parseBenefitByType(t.memo);
        if (memo.isNotEmpty) {
          benefit = memo.values.fold<double>(0, (s, v) => s + v);
        } else {
          final charged = t.cardChargedAmount;
          if (charged != null && charged > 0) {
            final diff = t.amount - charged;
            if (diff > 0) benefit = diff;
          }
        }
      }

      if (benefit <= 0) continue;

      final accLook = lookbackByStore.putIfAbsent(
        store,
        () => _AggAcc(name: store),
      );
      accLook.total += benefit;
      accLook.count += 1;

      if (!t.date.isBefore(monthStart)) {
        final accMonth = thisMonthByStore.putIfAbsent(
          store,
          () => _AggAcc(name: store),
        );
        accMonth.total += benefit;
        accMonth.count += 1;
      }
    }

    if (lookbackByStore.isEmpty) {
      return Text(
        '표시할 마트/쇼핑몰별 혜택 데이터가 없습니다.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final lookbackItems =
        lookbackByStore.values
            .map(
              (a) =>
                  _AggStat(name: a.name, count: a.count, totalAmount: a.total),
            )
            .toList(growable: false)
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final monthItems =
        thisMonthByStore.values
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

    final maxAmount = lookbackItems.isEmpty
        ? 0.0
        : lookbackItems.first.totalAmount;
    final denom = maxAmount <= 0 ? 1.0 : maxAmount;

    final top = lookbackItems.take(10).toList(growable: false);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('마트/쇼핑몰별 혜택 합계 상위10', style: theme.textTheme.bodySmall),
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
              '${lookbackItems.length}개 마트',
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

  Widget _buildRankRow(
    ThemeData theme, {
    required int rank,
    required String title,
    required double amount,
    required int count,
    required double denom,
  }) {
    final scheme = theme.colorScheme;
    final emphasized = rank <= _topEmphasisRank;
    final pct = (amount / denom).clamp(0.0, 1.0);

    final textColor = emphasized ? null : scheme.onSurfaceVariant;
    final barColor = emphasized
        ? scheme.primary
        : scheme.onSurfaceVariant.withValues(alpha: 0.22);
    final trackColor = emphasized
        ? scheme.primary.withValues(alpha: 0.12)
        : scheme.onSurfaceVariant.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$rank. $title',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatWon(amount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: textColor ?? scheme.onSurfaceVariant,
                  fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
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
              color: barColor,
              backgroundColor: trackColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count건',
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor ?? scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
