import 'package:flutter/material.dart';
import '../services/savings_statistics_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/icon_catalog.dart';

part 'savings_statistics_screen_tabs.dart';
part 'savings_statistics_screen_expense_graph.dart';

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
                buildCookingSuccessTab(context, theme),
                buildSavedIngredientsTab(context, theme),
                buildExpenseGraphTab(context, theme),
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
