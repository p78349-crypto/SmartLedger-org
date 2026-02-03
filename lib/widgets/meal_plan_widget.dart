import 'package:flutter/material.dart';
import '../services/consumable_inventory_service.dart';
import '../utils/meal_plan_generator_utils.dart';
import '../utils/user_preference_utils.dart';
import '../mixins/food_expiry_items_auto_refresh_mixin.dart';

/// 식사 계획 자동 생성 위젯
class MealPlanWidget extends StatefulWidget {
  const MealPlanWidget({super.key});

  @override
  State<MealPlanWidget> createState() => _MealPlanWidgetState();
}

class _MealPlanWidgetState extends State<MealPlanWidget>
    with FoodExpiryItemsAutoRefreshMixin {
  List<DayMealPlan>? _mealPlans;
  String _selectedPeriod = '3일';
  bool _isLoading = true;
  String _mealPreference = '한식 중심';

  @override
  Future<void> onFoodExpiryItemsChanged() => _loadMealPlans();

  @override
  void initState() {
    super.initState();
    requestFoodExpiryItemsRefresh();
  }

  Future<void> _loadMealPlans() async {
    try {
      final items = ConsumableInventoryService.instance.items.value;
      final preference = await UserPreferenceUtils.getMealPreference();

      final plans = _selectedPeriod == '3일'
          ? MealPlanGeneratorUtils.generate3DayMealPlan(
              items,
              preference: preference,
            )
          : MealPlanGeneratorUtils.generate1WeekMealPlan(
              items,
              preference: preference,
            );

      if (mounted) {
        setState(() {
          _mealPlans = plans;
          _mealPreference = preference;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _changePeriod(String period) {
    if (_selectedPeriod != period) {
      setState(() {
        _selectedPeriod = period;
        _isLoading = true;
      });
      _loadMealPlans();
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

    if (_mealPlans == null || _mealPlans!.isEmpty) {
      return const SizedBox.shrink();
    }

    final summary = MealPlanGeneratorUtils.getMealPlanSummary(_mealPlans!);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '📅 식단 계획',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildPeriodButton('3일', theme),
                    const SizedBox(width: 8),
                    _buildPeriodButton('1주일', theme),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(summary, style: theme.textTheme.labelMedium),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mealPlans!.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final plan = _mealPlans![index];
              final meals = plan.meals;

              return _buildMealDayCard(context, theme, plan, meals);
            },
          ),

          // 영양정보 및 조리 난이도 요약
          if (_mealPlans!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Text(
                    '식사 팁',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '💡 $_mealPreference을(를) 기준으로 식단을 구성했습니다.\n'
                    '원하는 요리를 선택하여 조리하세요.',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, ThemeData theme) {
    final isSelected = _selectedPeriod == period;
    return OutlinedButton(
      onPressed: () => _changePeriod(period),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? theme.colorScheme.primary
            : Colors.transparent,
        side: BorderSide(
          color: theme.colorScheme.primary,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Text(
        period,
        style: theme.textTheme.labelSmall?.copyWith(
          color: isSelected ? Colors.white : theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMealDayCard(
    BuildContext context,
    ThemeData theme,
    DayMealPlan plan,
    DayMeals meals,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              plan.displayDate,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 아침/점심/저녁
          _buildMealRow(context, theme, '🌅 아침', meals.breakfast),
          const SizedBox(height: 8),
          _buildMealRow(context, theme, '🌞 점심', meals.lunch),
          const SizedBox(height: 8),
          _buildMealRow(context, theme, '🌙 저녁', meals.dinner),
        ],
      ),
    );
  }

  Widget _buildMealRow(
    BuildContext context,
    ThemeData theme,
    String label,
    String meal,
  ) {
    final difficulty = MealPlanGeneratorUtils.getCookingDifficulty(meal);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meal,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              difficulty,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
