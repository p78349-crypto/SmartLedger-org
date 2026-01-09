import 'package:flutter/material.dart';
import '../services/food_expiry_service.dart';
import '../utils/icon_catalog.dart';
import '../utils/cost_prediction_utils.dart';
import '../utils/user_preference_utils.dart';
import '../mixins/food_expiry_items_auto_refresh_mixin.dart';

/// 비용 예측 분석 위젯
class CostAnalysisWidget extends StatefulWidget {
  const CostAnalysisWidget({super.key});

  @override
  State<CostAnalysisWidget> createState() => _CostAnalysisWidgetState();
}

class _CostAnalysisWidgetState extends State<CostAnalysisWidget>
    with FoodExpiryItemsAutoRefreshMixin {
  BudgetAnalysis? _analysis;
  Map<String, double>? _categorySpending;
  String? _monthlyTrend;
  String? _purchasingAdvice;
  bool _isLoading = true;
  int _budgetLimit = 500000;

  @override
  Future<void> onFoodExpiryItemsChanged() => _loadAnalysis();

  @override
  void initState() {
    super.initState();
    requestFoodExpiryItemsRefresh();
  }

  Future<void> _loadAnalysis() async {
    try {
      final items = FoodExpiryService.instance.items.value;
      final budget = await UserPreferenceUtils.getBudgetLimit();

      final analysis = CostPredictionUtils.analyzeBudget(
        items,
        monthlyBudget: budget,
      );

      final categorySpending = CostPredictionUtils.getCategorySpending(items);

      final monthlyTrend = CostPredictionUtils.getMonthlyTrend(
        items,
        DateTime.now(),
      );

      final purchasingAdvice = CostPredictionUtils.getOptimalPurchasingAdvice(
        items,
        budget,
      );

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _categorySpending = categorySpending;
          _monthlyTrend = monthlyTrend;
          _purchasingAdvice = purchasingAdvice;
          _budgetLimit = budget;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator.adaptive(),
      );
    }

    if (_analysis == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  IconCatalog.spending,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '💰 비용 분석',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 예산 현황 카드
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildBudgetCard(theme),
          ),

          const Divider(height: 1),

          // 예산 진행바
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '월 지출 현황',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_analysis!.usagePercentage.toStringAsFixed(1)}%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_analysis!.usagePercentage / 100).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 경고 메시지
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getBudgetStatusBackground(theme),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                CostPredictionUtils.getBudgetWarning(_analysis!),
                style: theme.textTheme.labelMedium,
              ),
            ),
          ),

          const Divider(height: 1),

          // 카테고리별 지출
          if (_categorySpending != null && _categorySpending!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📊 카테고리별 지출',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._buildCategoryRows(theme),
                ],
              ),
            ),

          const Divider(height: 1),

          // 월 추세 및 조언
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 월 추세
                if (_monthlyTrend != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _monthlyTrend!,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                  ),

                // 구매 조언
                if (_purchasingAdvice != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer.withValues(
                        alpha: 0.3,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _purchasingAdvice!,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '월 예산',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${_budgetLimit.toStringAsFixed(0)}원',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '현재 지출',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${_analysis!.currentCost.toStringAsFixed(0)}원',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '남은 예산',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${_analysis!.remaining.toStringAsFixed(0)}원',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _analysis!.statusText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryRows(ThemeData theme) {
    if (_categorySpending == null) return [];

    final entries = _categorySpending!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.take(5).map((entry) {
      final percentage = (entry.value / _budgetLimit * 100).toStringAsFixed(1);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(entry.key, style: theme.textTheme.labelMedium),
            ),
            Text(
              '${entry.value.toStringAsFixed(0)}원 ($percentage%)',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getStatusColor() {
    if (_analysis!.isOverBudget) return Colors.red;
    if (_analysis!.usagePercentage > 80) return Colors.orange;
    if (_analysis!.usagePercentage > 50) return Colors.green;
    return Colors.blue;
  }

  Color _getBudgetStatusBackground(ThemeData theme) {
    if (_analysis!.isOverBudget) {
      return Colors.red.withValues(alpha: 0.1);
    } else if (_analysis!.usagePercentage > 80) {
      return Colors.orange.withValues(alpha: 0.1);
    } else {
      return Colors.green.withValues(alpha: 0.1);
    }
  }
}
