// ignore_for_file: invalid_use_of_protected_member

part of 'savings_statistics_screen.dart';

/// 월별 식비 지출 변화 그래프 탭
extension SavingsStatisticsExpenseGraph on _SavingsStatisticsScreenState {
  Widget buildExpenseGraphTab(
    BuildContext context,
    ThemeData theme,
  ) {
    return FutureBuilder<Result<Map<String, double>>>(
      future: SavingsStatisticsService.instance
          .calculateMonthlyFoodExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData) {
          return _buildEmptyGraph(theme);
        }

        final result = snapshot.data!;
        if (result.isFailure) {
          return Center(
            child: Text(
              '데이터 로드 실패:\n'
              '${result.errorOrNull?.message}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final monthlyData = result.dataOrNull!;
        if (monthlyData.isEmpty) {
          return _buildEmptyGraph(theme);
        }
        final months = monthlyData.keys.toList()..sort();
        final maxExpense = months
            .map((m) => monthlyData[m]!)
            .reduce((a, b) => a > b ? a : b);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 간단한 막대 그래프
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '월별 식비 지출 변화',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: months
                            .map(
                              (month) => _buildBarChart(
                                context,
                                theme,
                                month,
                                monthlyData[month]!,
                                maxExpense,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 상세 데이터
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '월별 상세',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (int i = 0; i < months.length; i++)
                      Column(
                        children: [
                          _buildMonthlyDetail(
                            theme,
                            months[i],
                            monthlyData[months[i]]!,
                            i == months.length - 1,
                          ),
                          if (i < months.length - 1) const Divider(),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<
              Result<
                ({
                  double beforePrice,
                  double afterPrice,
                  double savingsAmount,
                  double savingsPercent,
                })
              >
            >(
              future: SavingsStatisticsService
                  .instance
                  .calculateSavingsCompare(),
              builder: (
                context,
                compareSnapshot,
              ) {
                if (!compareSnapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final compareResult =
                    compareSnapshot.data!;
                if (compareResult.isFailure) {
                  return const SizedBox.shrink();
                }
                final compare =
                    compareResult.dataOrNull!;

                return Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.trending_down,
                              color: Colors.green.shade600,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '절약 효과',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final beforePriceText = CurrencyFormatter.format(
                              compare.beforePrice.toInt(),
                            );
                            final afterPriceText = CurrencyFormatter.format(
                              compare.afterPrice.toInt(),
                            );
                            final savingsAmountText = CurrencyFormatter.format(
                              compare.savingsAmount.toInt(),
                            );
                            final savingsPercentText = compare.savingsPercent
                                .toStringAsFixed(1);

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '지난달',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: Colors.grey),
                                        ),
                                        Text(
                                          '₩$beforePriceText',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.green.shade600,
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '이번달',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: Colors.grey),
                                        ),
                                        Text(
                                          '₩$afterPriceText',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade600,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100.withValues(
                                      alpha: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '절약액',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: Colors.green.shade700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₩$savingsAmountText '
                                        '(-$savingsPercentText%)',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyGraph(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_outlined,
            size: 48,
            color: theme
                .colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            '식비 기록이 아직 없습니다.',
            style:
                theme.textTheme.bodyLarge?.copyWith(
              color: theme
                  .colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '식비 카테고리의 거래를 추가하면\n'
            '그래프가 표시됩니다.',
            textAlign: TextAlign.center,
            style:
                theme.textTheme.bodySmall?.copyWith(
              color: theme
                  .colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
