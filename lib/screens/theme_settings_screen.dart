import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/app_icon_service.dart';
import 'package:smart_ledger/theme/app_theme_mode_controller.dart';
import 'package:smart_ledger/theme/app_theme_seed_controller.dart';
import 'package:smart_ledger/theme/theme_preset.dart';
import 'package:smart_ledger/theme/ui_style.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('테마')),
      body: ListView(
        children: const [
          SizedBox(height: 8),
          ThemeSettingsSection(),
          SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Shared theme controls so other screens can embed the same UI.
class ThemeSettingsSection extends StatelessWidget {
  final EdgeInsetsGeometry padding;

  const ThemeSettingsSection({
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AppThemeModeController.instance.themeMode,
        AppThemeSeedController.instance.presetId,
        AppThemeSeedController.instance.uiStyle,
      ]),
      builder: (context, _) {
        final mode = AppThemeModeController.instance.themeMode.value;
        final selectedPresetId = AppThemeSeedController.instance.presetId.value;
        final selectedUiStyle = AppThemeSeedController.instance.uiStyle.value;

        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('화면 모드', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              RadioGroup<ThemeMode>(
                groupValue: mode,
                onChanged: (v) {
                  if (v == null) return;
                  AppThemeModeController.instance.setThemeMode(v);
                },
                child: const Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: Text('시스템 설정 따름'),
                      value: ThemeMode.system,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('라이트'),
                      value: ThemeMode.light,
                    ),
                    RadioListTile<ThemeMode>(
                      title: Text('다크'),
                      value: ThemeMode.dark,
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              Text(
                '디자인 스타일 (모드)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              RadioGroup<UIStyle>(
                groupValue: selectedUiStyle,
                onChanged: (v) {
                  if (v == null) return;
                  AppThemeSeedController.instance.setUiStyle(v);
                },
                child: Column(
                  children: UIStyle.values.map((style) {
                    return RadioListTile<UIStyle>(
                      title: Text(style.label),
                      subtitle: Text(style.description),
                      value: style,
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 24),
              Text('스마트 색상 테마', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: selectedPresetId,
                onChanged: (v) {
                  if (v == null) return;
                  AppThemeSeedController.instance.setPresetId(v);
                },
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                      ),
                      child: Text(
                        '여성 스타일 (10)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...ThemePresets.female.map(
                      (preset) => _presetTile(
                        context,
                        preset: preset,
                        selectedPresetId: selectedPresetId,
                      ),
                    ),
                    const Divider(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                      ),
                      child: Text(
                        '남성 스타일 (10)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...ThemePresets.male.map(
                      (preset) => _presetTile(
                        context,
                        preset: preset,
                        selectedPresetId: selectedPresetId,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
              const _AppIconSyncSection(),
            ],
          ),
        );
      },
    );
  }

  static Widget _presetTile(
    BuildContext context, {
    required ThemePreset preset,
    required String selectedPresetId,
  }) {
    return RadioListTile<String>(
      value: preset.id,
      title: Text(preset.label),
      secondary: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: preset.seedColor,
        ),
      ),
    );
  }
}

class _AppIconSyncSection extends StatefulWidget {
  const _AppIconSyncSection();

  @override
  State<_AppIconSyncSection> createState() => _AppIconSyncSectionState();
}

class _AppIconSyncSectionState extends State<_AppIconSyncSection> {
  bool _isSyncing = false;
  String _iconStyle = 'standard'; // 'standard' or 'intense'

  Future<void> _syncIcon() async {
    final presetId = AppThemeSeedController.instance.presetId.value;
    final isFemale = ThemePresets.female.any((p) => p.id == presetId);

    String targetIconTheme;
    if (_iconStyle == 'intense') {
      targetIconTheme = isFemale ? 'light_intense' : 'dark_intense';
    } else {
      targetIconTheme = isFemale ? 'light' : 'dark';
    }

    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 아이콘 적용'),
        content: Text(
          '현재 선택된 테마(${isFemale ? "여성향" : "남성향"})와 스타일(${_iconStyle == "intense" ? "진하게" : "기본"})에 맞춰 앱 아이콘을 변경합니다.\n\n'
          '⚠️ 적용 시 안드로이드 시스템 정책에 의해 앱이 즉시 종료됩니다. 다시 실행해 주세요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('적용 및 종료'),
          ),
        ],
      ),
    );

    if (proceed == true) {
      setState(() => _isSyncing = true);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_icon_theme_id', targetIconTheme);

        // Import AppIconService if needed, but it's already used in the controller
        // so we can call it here.
        await AppIconService.setLauncherIconTheme(targetIconTheme);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('앱 아이콘 관리', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('기본 색상')),
                selected: _iconStyle == 'standard',
                onSelected: (selected) {
                  if (selected) setState(() => _iconStyle = 'standard');
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('진한 색상')),
                selected: _iconStyle == 'intense',
                onSelected: (selected) {
                  if (selected) setState(() => _iconStyle = 'intense');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.phonelink_setup_rounded),
            title: const Text('테마와 아이콘 동기화'),
            subtitle: const Text('선택한 테마 색상에 맞춰 홈 화면 아이콘을 변경합니다.'),
            trailing: _isSyncing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onTap: _isSyncing ? null : _syncIcon,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            '※ 아이콘 변경은 안드로이드 시스템에 의해 앱 재시작이 필요하므로, 모든 설정을 마친 후 수동으로 적용하는 것을 권장합니다.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
