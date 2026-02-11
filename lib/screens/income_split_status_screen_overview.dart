part of 'income_split_status_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension IncomeSplitOverview on _IncomeSplitStatusScreenState {
  Widget buildIncomeSplitOverview(IncomeSplit split, double totalExpense) {
    final scheme = Theme.of(context).colorScheme;
    final data = _splitAllocations(
      split,
      totalExpense,
    ).where((entry) => entry.planned > 0).toList();

    // Append expense main categories
    final transactions = TransactionService().getTransactions(
      widget.accountName,
    );
    final Map<String, double> expenseActuals = {};
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        expenseActuals[tx.mainCategory] =
            (expenseActuals[tx.mainCategory] ?? 0) + tx.amount.abs();
      }
    }

    for (final category in CategoryDefinitions.mainCategories) {
      final planned = split.categoryBudgets[category] ?? 0;
      final actual = expenseActuals[category] ?? 0;
      if (planned > 0 || actual > 0) {
        data.add(
          _SplitAllocationData(
            label: category,
            planned: planned,
            actual: actual,
            color: scheme.onSurfaceVariant,
            description: '지출 카테고리',
          ),
        );
      }
    }

    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('수입 배분 데이터가 없습니다.'),
        ),
      );
    }

    final totalPlanned = data.fold<double>(0, (sum, e) => sum + e.planned);
    final totalActual = data.fold<double>(0, (sum, e) => sum + e.actual);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet, size: 18),
                const SizedBox(width: 8),
                const Text(
                  '수입 배분 현황',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => openIncomeSplitChart(split, totalExpense),
                  icon: const Icon(Icons.pie_chart_outline),
                  label: const Text('그래프로 보기'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...data.map((entry) {
              final percentOfPlan = totalPlanned > 0
                  ? (entry.planned / totalPlanned) * 100
                  : 0;
              final usageRatio = entry.planned > 0
                  ? (entry.actual / entry.planned)
                  : 0;
              final usagePercent = entry.planned > 0
                  ? (usageRatio.clamp(0, 1) * 100)
                  : 0;
              final difference = entry.actual - entry.planned;
              final isOver = difference > 0.01;
              final plannedValue = CurrencyFormatter.format(entry.planned);
              final actualValue = CurrencyFormatter.format(entry.actual);
              final diffValue = CurrencyFormatter.format(difference.abs());
              final diffLabel = difference >= 0 ? '초과' : '잔여';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: entry.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.label,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${percentOfPlan.toStringAsFixed(0)}% 배분',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '계획 $plannedValue',
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          '집행 $actualValue',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isOver ? scheme.error : scheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (entry.label == '예산')
                          Text(
                            '$diffLabel $diffValue',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: difference > 0
                                  ? scheme.error
                                  : scheme.primary,
                            ),
                          )
                        else
                          Text(
                            entry.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    // 소분류 배분 표시
                    if (_subcategoryAllocations[entry.label]?.isNotEmpty ==
                        true) ...[
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _subcategoryAllocations[entry.label]!
                              .entries
                              .map((e) {
                                final info = e.value as Map<String, dynamic>?;
                                final amt =
                                    info != null && info['amount'] != null
                                    ? (info['amount'] as num).toDouble()
                                    : 0.0;
                                return Row(
                                  children: [
                                    const Icon(
                                      Icons.subdirectory_arrow_right,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        e.key,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                    Text(
                                      '${amt.toStringAsFixed(0)}원',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                );
                              })
                              .toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => openSubcategoryModal(entry.label),
                          icon: const Icon(Icons.list),
                          label: const Text('소분류 관리'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: entry.planned > 0
                            ? (entry.actual / entry.planned).clamp(0, 1)
                            : 0,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(entry.color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${usagePercent.toStringAsFixed(0)}% 집행',
                      style: TextStyle(
                        fontSize: 11,
                        color: isOver ? scheme.error : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 배분 ${CurrencyFormatter.format(totalPlanned)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '총 집행 ${CurrencyFormatter.format(totalActual)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
