// ignore_for_file: deprecated_member_use
// NOTE: Radio groupValue/onChanged는 Flutter 3.32+에서 RadioGroup으로 마이그레이션 필요
import 'package:flutter/material.dart';
import '../utils/meal_plan_generator_utils.dart';
import '../utils/user_preference_utils.dart';

/// 사용자 설정 커스터마이징 위젯
class UserPreferencesWidget extends StatefulWidget {
  const UserPreferencesWidget({super.key});

  @override
  State<UserPreferencesWidget> createState() => _UserPreferencesWidgetState();
}

class _UserPreferencesWidgetState extends State<UserPreferencesWidget> {
  UserPreferences? _preferences;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await UserPreferenceUtils.getAllPreferences();
      if (mounted) {
        setState(() {
          _preferences = prefs;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateMealPrepName(String name) async {
    await UserPreferenceUtils.setMealPrepName(name);
    await _loadPreferences();
  }

  Future<void> _updateMealPreference(String preference) async {
    await UserPreferenceUtils.setMealPreference(preference);
    await _loadPreferences();
  }

  Future<void> _updateBudget(int budget) async {
    await UserPreferenceUtils.setBudgetLimit(budget);
    await _loadPreferences();
  }

  void _showMealPrepNameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
          text: _preferences?.mealPrepName ?? '',
        );
        return AlertDialog(
          title: const Text('식사 준비 이름 설정'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: '예: 김은서 도시락, 가족 식단',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  _updateMealPrepName(controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _showMealPreferenceDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final options = MealPlanGeneratorUtils.getPreferenceOptions();
        return AlertDialog(
          title: const Text('식사 선호도 선택'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: options
                  .map(
                    (option) => ListTile(
                      title: Text(option),
                      leading: Radio<String>(
                        value: option,
                        groupValue: _preferences?.mealPreference,
                        onChanged: (value) {
                          if (value != null) {
                            _updateMealPreference(value);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  void _showBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(
          text: (_preferences?.budgetLimit ?? 500000).toString(),
        );
        return AlertDialog(
          title: const Text('월 예산 설정'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '월 예산 (원)',
              border: OutlineInputBorder(),
              suffixText: '원',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final budget = int.tryParse(controller.text);
                if (budget != null && budget > 0) {
                  _updateBudget(budget);
                  Navigator.pop(context);
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
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

    if (_preferences == null) {
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
                  Icons.settings,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  '⚙️ 개인 설정',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 설정 항목들
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 식사 준비 이름
                _buildSettingTile(
                  context,
                  theme,
                  '🍽️ 식사 준비 이름',
                  _preferences?.mealPrepName ?? '미설정',
                  onTap: _showMealPrepNameDialog,
                ),
                const SizedBox(height: 12),

                // 식사 선호도
                _buildSettingTile(
                  context,
                  theme,
                  '🥘 식사 선호도',
                  _preferences?.mealPreference ?? '한식 중심',
                  onTap: _showMealPreferenceDialog,
                ),
                const SizedBox(height: 12),

                // 월 예산
                _buildSettingTile(
                  context,
                  theme,
                  '💰 월 예산',
                  '${_preferences?.budgetLimit ?? 500000}원',
                  onTap: _showBudgetDialog,
                ),
                const SizedBox(height: 12),

                // 알림 설정
                _buildToggleSetting(
                  theme,
                  '🔔 유통기한 알림',
                  _preferences?.notificationEnabled ?? true,
                  (value) async {
                    await UserPreferenceUtils.setNotificationEnabled(value);
                    await _loadPreferences();
                  },
                ),
                const SizedBox(height: 12),

                // 식단 제한사항
                _buildRestrictionsSection(context, theme),
              ],
            ),
          ),

          const Divider(height: 1),

          // 설정 요약
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 설정 요약',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _preferences!.getSummary(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    ThemeData theme,
    String label,
    String value, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
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
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, size: 20, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleSetting(
    ThemeData theme,
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _buildRestrictionsSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🚫 식단 제한사항',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _showRestrictionDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('추가'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if ((_preferences?.dietaryRestrictions ?? []).isEmpty)
          Text(
            '제한사항이 없습니다.',
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.grey[600],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: (_preferences?.dietaryRestrictions ?? [])
                .map(
                  (restriction) => Chip(
                    label: Text(restriction),
                    onDeleted: () async {
                      await UserPreferenceUtils.removeRestriction(restriction);
                      await _loadPreferences();
                    },
                    backgroundColor: theme.colorScheme.tertiaryContainer
                        .withValues(alpha: 0.5),
                    deleteIconColor: theme.colorScheme.tertiary,
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  void _showRestrictionDialog(BuildContext context) {
    final restrictions = [
      '계란',
      '우유',
      '견과류',
      '해산물',
      '밀가루',
      '쇠고기',
      '돼지고기',
      '닭고기',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('식단 제한사항 추가'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: restrictions
                  .map(
                    (restriction) => CheckboxListTile(
                      title: Text(restriction),
                      value: (_preferences?.dietaryRestrictions ?? []).contains(
                        restriction,
                      ),
                      onChanged: (value) async {
                        if (value == true) {
                          await UserPreferenceUtils.addRestriction(restriction);
                        } else {
                          await UserPreferenceUtils.removeRestriction(
                            restriction,
                          );
                        }
                        await _loadPreferences();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }
}
