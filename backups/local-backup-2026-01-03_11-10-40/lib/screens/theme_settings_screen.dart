import 'package:flutter/material.dart';
import 'package:smart_ledger/theme/app_theme_mode_controller.dart';
import 'package:smart_ledger/theme/app_theme_seed_controller.dart';
import 'package:smart_ledger/theme/theme_preset.dart';

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
      ]),
      builder: (context, _) {
        final mode = AppThemeModeController.instance.themeMode.value;
        final selectedPresetId = AppThemeSeedController.instance.presetId.value;

        return Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('모드', style: Theme.of(context).textTheme.titleMedium),
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
                'One UI 색상 테마',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
                        horizontal: 0,
                        vertical: 6,
                      ),
                      child: Text(
                        '여성 스타일 (5)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...ThemePresets.female.map(
                      (preset) => _presetTile(context, preset: preset),
                    ),
                    const Divider(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 6,
                      ),
                      child: Text(
                        '남성 스타일 (5)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...ThemePresets.male.map(
                      (preset) => _presetTile(context, preset: preset),
                    ),
                  ],
                ),
              ),
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
