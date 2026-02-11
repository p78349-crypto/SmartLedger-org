// ignore_for_file: deprecated_member_use
// NOTE: Radio groupValue/onChanged는 Flutter 3.32+에서 RadioGroup으로 마이그레이션 필요
import 'package:flutter/material.dart';
import '../utils/meal_plan_generator_utils.dart';
import '../utils/user_preference_utils.dart';

part 'user_preferences_widget_helpers.dart';

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
}
