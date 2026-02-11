// ignore_for_file: invalid_use_of_protected_member
part of 'period_stats_screen.dart';

/// 기간별 통계 카테고리 집계 + 잡다한 지출 분석
extension PeriodStatsScreenWidgets on _PeriodStatsScreenState {
  Color _colorForCategoryRank(ThemeData theme, int index) {
    final scheme = theme.colorScheme;

    if (index < 10) {
      final colors = [
        scheme.primary,
        Colors.blue,
        Colors.indigo,
        Colors.cyan,
        Colors.teal,
        Colors.green,
        Colors.lightGreen,
        Colors.lime,
        Colors.yellow,
        Colors.amber,
      ];
      return colors[index % colors.length];
    } else if (index < 20) {
      final colors = [
        scheme.secondary,
        Colors.orange,
        Colors.deepOrange,
        Colors.red,
        Colors.pink,
        Colors.purple,
        Colors.deepPurple,
        Colors.brown,
        Colors.blueGrey,
        Colors.grey,
      ];
      return colors[(index - 10) % colors.length];
    } else {
      final colors = [scheme.tertiary, scheme.outline, scheme.onSurfaceVariant];
      return colors[(index - 20) % colors.length];
    }
  }

  Widget _buildExpenseCategoryAggregation(
    ThemeData theme,
    List<Transaction> filtered,
  ) {
    final expenseTxs = filtered
        .where((tx) => tx.type == TransactionType.expense)
        .toList(growable: false);

    if (expenseTxs.isEmpty) {
      return Center(
        child: Text('해당 기간에 표시할 지출이 없습니다.', style: theme.textTheme.bodyMedium),
      );
    }

    final Map<String, double> totals = <String, double>{};
    final Map<String, int> counts = <String, int>{};
    for (final tx in expenseTxs) {
      final key = tx.mainCategory;
      totals[key] = (totals[key] ?? 0) + tx.amount.abs();
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.take(20).toList(growable: false);
    final totalExpense = expenseTxs.fold<double>(
      0,
      (sum, tx) => sum + tx.amount.abs(),
    );

    return ListView.separated(
      itemCount: top.length + 1,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i == 0) {
          return ListTile(
            title: const Text('카테고리별 지출 (상위 20)'),
            trailing: Text(
              '총 ${_currencyFormat.format(totalExpense)}원',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }

        final index = i - 1;
        final entry = top[index];
        final category = entry.key;
        final amount = entry.value;
        final count = counts[category] ?? 0;
        final color = _colorForCategoryRank(theme, index);

        return ListTile(
          leading: CircleAvatar(radius: 10, backgroundColor: color),
          title: Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text(
            '$count건',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Text(
            '${_currencyFormat.format(amount)}원',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiscSpendingSummary(ThemeData theme, List<Transaction> all) {
    final stats = MiscSpendingUtils.analyze(all, anchor: _anchorDay);
    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    final top = stats.take(3).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '절약 포인트: 잡다한 지출',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: top.map((s) {
                    final label = s.subCategory.isEmpty
                        ? s.mainCategory
                        : '${s.mainCategory}·${s.subCategory}';
                    final monthly = s.monthlyAmount;
                    final annual = s.annualProjection;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              s.icon,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 100,
                            child: Column(
                              children: [
                                Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Builder(
                                  builder: (context) {
                                    final monthlyStr = NumberFormats.currency
                                        .format(monthly);
                                    final annualStr = NumberFormats.currency
                                        .format(annual);
                                    return Column(
                                      children: [
                                        Text(
                                          '$monthlyStr원',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                        Text(
                                          '연환산 $annualStr원',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                fontSize: 11,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMiscPolicyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('절약 포인트 정책'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• 기준: 최근 1개월 기준으로 거래 평균이 10,000원 미만이거나 거래 건수가 5건 이상인 카테고리를 '
                '"잡다한 지출"로 간주합니다.',
              ),
              SizedBox(height: 8),
              Text('• 목적: 자주 발생하는 소액 지출을 시각화하여 사용자에게 절약 포인트로 인지시키기 위함입니다.'),
              SizedBox(height: 8),
              Text('• 설정: 임계값(평균 금액·건수)은 향후 사용자 설정으로 조정 가능합니다.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
