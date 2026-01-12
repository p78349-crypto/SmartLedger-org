library theme_settings_screen;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_icon_service.dart';
import '../theme/app_theme_mode_controller.dart';
import '../theme/app_theme_seed_controller.dart';
import '../theme/theme_preset.dart';
import '../theme/ui_style.dart';

part 'theme_settings_screen_app_icon_sync_section.dart';

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
              RadioGroup<AppThemeMode>(
                groupValue: mode,
                onChanged: (value) {
                  if (value == null) return;
                  AppThemeModeController.instance.setThemeMode(value);
                },
                child: const Column(
                  children: [
                    RadioListTile<AppThemeMode>(
                      title: Text('시스템 설정 따름'),
                      value: AppThemeMode.system,
                    ),
                    RadioListTile<AppThemeMode>(
                      title: Text('라이트'),
                      value: AppThemeMode.light,
                    ),
                    RadioListTile<AppThemeMode>(
                      title: Text('다크'),
                      value: AppThemeMode.dark,
                    ),
                    RadioListTile<AppThemeMode>(
                      title: Text('여성 스타일 (다크)'),
                      subtitle: Text('다크 모드 + 여성용 진한 색상'),
                      value: AppThemeMode.femaleDark,
                    ),
                    RadioListTile<AppThemeMode>(
                      title: Text('남성 스타일 (다크)'),
                      subtitle: Text('다크 모드 + 남성용 진한 색상'),
                      value: AppThemeMode.maleDark,
                    ),
                    RadioListTile<AppThemeMode>(
                      title: Text('여성 스타일 (진한 색상)'),
                      subtitle: Text('라이트 모드 + 여성용 진한 색상'),
                      value: AppThemeMode.femaleLight,
                    ),
                    RadioListTile<AppThemeMode>(
                      title: Text('남성 스타일 (진한 색상)'),
                      subtitle: Text('라이트 모드 + 남성용 진한 색상'),
                      value: AppThemeMode.maleLight,
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
                onChanged: (style) {
                  if (style == null) return;
                  AppThemeSeedController.instance.setUiStyle(style);
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
                onChanged: (presetId) {
                  if (presetId == null) return;
                  AppThemeSeedController.instance.setPresetId(presetId);
                },
                child: Column(
                  children: [
                    if (mode != AppThemeMode.maleDark &&
                        mode != AppThemeMode.maleLight) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '여성 스타일 (10)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      ...ThemePresets.female
                          .where(
                            (p) =>
                                (mode != AppThemeMode.femaleDark &&
                                    mode != AppThemeMode.femaleLight) ||
                                p.id.contains('intense'),
                          )
                          .map(
                            (preset) => _presetTile(context, preset: preset),
                          ),
                      const Divider(height: 12),
                    ],
                    if (mode != AppThemeMode.femaleDark &&
                        mode != AppThemeMode.maleDark &&
                        mode != AppThemeMode.femaleLight &&
                        mode != AppThemeMode.maleLight) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '스페셜 스타일',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      ...ThemePresets.special.map(
                        (preset) => _presetTile(context, preset: preset),
                      ),
                      const Divider(height: 12),
                    ],
                    if (mode != AppThemeMode.femaleDark &&
                        mode != AppThemeMode.femaleLight) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          '남성 스타일 (10)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      ...ThemePresets.male
                          .where(
                            (p) =>
                                (mode != AppThemeMode.maleDark &&
                                    mode != AppThemeMode.maleLight) ||
                                p.id.contains('intense'),
                          )
                          .map(
                            (preset) => _presetTile(context, preset: preset),
                          ),
                    ],
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
