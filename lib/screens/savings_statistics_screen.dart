import 'package:flutter/material.dart';
import '../services/savings_statistics_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/icon_catalog.dart';

/// 절약 통계 화면
/// 1. 냉파 성공 지수 (챌린지 기간 끼니 수)
/// 2. 구조된 식재료 (유통기한 임박 식재료 활용 금액)
/// 3. 지출 감소 그래프 (월별 식비 변화)
class SavingsStatisticsScreen extends StatefulWidget {
  const SavingsStatisticsScreen({super.key});

  @override
  State<SavingsStatisticsScreen> createState() =>
      _SavingsStatisticsScreenState();
}

class _SavingsStatisticsScreenState extends State<SavingsStatisticsScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    SavingsStatisticsService.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '식비 절약 통계',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '냉장고 파먹기 챌린지를 통한 실제 절약 효과',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // 탭 버튼
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  _buildTabButton(context, 0, '냉파 성공', IconCatalog.restaurant),
                  _buildTabButton(context, 1, '구조된 재료', IconCatalog.favorite),
                  _buildTabButton(
                    context,
                    2,
                    '지출 변화',
                    IconCatalog.trendingDown,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 탭별 컨텐츠
          Expanded(
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                _buildCookingSuccessTab(context, theme),
                _buildSavedIngredientsTab(context, theme),
                _buildExpenseGraphTab(context, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context,
    int index,
    String label,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.surface : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCookingSuccessTab(BuildContext context, ThemeData theme) {
    final successIndex = SavingsStatisticsService.instance
        .calculateCookingSuccessIndex();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 큰 숫자 표시
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(32),
          alignment: Alignment.center,
          child: Column(
            children: [
              Text(
                '냉파 성공 지수',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$successIndex',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '끼니',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 설명 카드
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '성공 지수란?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '매달 20일부터 말일까지의 "냉장고 파먹기 챌린지" 기간 동안 '
                  '추가 식재료 구매 없이 현재 재고로만 준비한 끼니의 총 수입니다.\n\n'
                  '이 숫자가 높을수록 냉장고를 효과적으로 비우고, 식비 낭비를 줄였다는 뜻입니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.celebration, color: theme.colorScheme.tertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    successIndex > 0
                        ? '축하합니다! 이미 $successIndex끼니를 절약했어요 🎉'
                        : '다음 20일부터 챌린지를 시작해보세요!',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedIngredientsTab(BuildContext context, ThemeData theme) {
    final savedValue = SavingsStatisticsService.instance
        .calculateSavedIngredientsValue();
    final formattedValue = CurrencyFormatter.format(savedValue.toInt());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.shade300, Colors.pink.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(32),
          alignment: Alignment.center,
          child: Column(
            children: [
              Text(
                '구조된 식재료',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '₩$formattedValue',
                style: theme.textTheme.displayLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '어치의 식재료를 버리지 않고 활용',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '구조된 식재료란?',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '앱에서 "유통기한 임박" 알림을 받았으나, 버리지 않고 실제 요리에 '
                  '활용한 식재료의 총 가치입니다.\n\n'
                  '이 금액이 높을수록 당신은 식재료를 낭비 없이 효율적으로 활용하고 있다는 의미입니다.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.pink.shade100.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.eco, color: Colors.green.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    savedValue > 0
                        ? '환경도 지키고 돈도 절약했어요! ♻️'
                        : '요리를 통해 식재료를 활용하면 이 수치가 올라갑니다.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseGraphTab(BuildContext context, ThemeData theme) {
    return FutureBuilder<Map<String, double>>(
      future: SavingsStatisticsService.instance.calculateMonthlyFoodExpenses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  '식비 기록이 아직 없습니다.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '식비 카테고리의 거래를 추가하면\n그래프가 표시됩니다.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        final monthlyData = snapshot.data!;
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
              ({
                double beforePrice,
                double afterPrice,
                double savingsAmount,
                double savingsPercent,
              })
            >(
              future: SavingsStatisticsService.instance
                  .calculateSavingsCompare(),
              builder: (context, compareSnapshot) {
                if (!compareSnapshot.hasData) return const SizedBox.shrink();

                final compare = compareSnapshot.data!;

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

  Widget _buildBarChart(
    BuildContext context,
    ThemeData theme,
    String month,
    double value,
    double maxValue,
  ) {
    final height = (value / maxValue) * 150;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '₩${(value / 1000).toStringAsFixed(0)}k',
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            height: height.clamp(10, 150),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            month.split('-')[1],
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyDetail(
    ThemeData theme,
    String month,
    double value, [
    bool isLast = false,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            month,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '₩${CurrencyFormatter.format(value.toInt())}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
