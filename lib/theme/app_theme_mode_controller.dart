import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/utils/pref_keys.dart';
import 'package:smart_ledger/theme/theme_preset.dart';

enum AppThemeMode {
  system,
  light,
  dark,
  femaleDark,
  maleDark,
  femaleLight,
  maleLight,
}

class ThemeResolution {
  final ThemeMode mode;
  final ThemePreset preset;

  ThemeResolution({required this.mode, required this.preset});
}

class AppThemeModeController {
  AppThemeModeController._();

  static final AppThemeModeController instance = AppThemeModeController._();

  final ValueNotifier<AppThemeMode> themeMode = ValueNotifier<AppThemeMode>(
    AppThemeMode.system,
  );

  ThemeResolution resolve(String currentPresetId) {
    final mode = themeMode.value;
    ThemeMode targetMode;
    ThemePreset targetPreset;

    switch (mode) {
      case AppThemeMode.system:
        targetMode = ThemeMode.system;
        targetPreset = ThemePresets.byId(currentPresetId);
        break;
      case AppThemeMode.light:
        targetMode = ThemeMode.light;
        targetPreset = ThemePresets.byId(currentPresetId);
        break;
      case AppThemeMode.dark:
        targetMode = ThemeMode.dark;
        targetPreset = ThemePresets.byId(currentPresetId);
        break;
      case AppThemeMode.femaleDark:
      case AppThemeMode.femaleLight:
        targetMode =
            mode == AppThemeMode.femaleDark ? ThemeMode.dark : ThemeMode.light;
        if (!ThemePresets.female.any(
          (p) => p.id == currentPresetId && p.id.contains('intense'),
        )) {
          targetPreset =
              ThemePresets.female.firstWhere((p) => p.id.contains('intense'));
        } else {
          targetPreset = ThemePresets.byId(currentPresetId);
        }
        break;
      case AppThemeMode.maleDark:
      case AppThemeMode.maleLight:
        targetMode =
            mode == AppThemeMode.maleDark ? ThemeMode.dark : ThemeMode.light;
        if (!ThemePresets.male.any(
          (p) => p.id == currentPresetId && p.id.contains('intense'),
        )) {
          targetPreset =
              ThemePresets.male.firstWhere((p) => p.id.contains('intense'));
        } else {
          targetPreset = ThemePresets.byId(currentPresetId);
        }
        break;
    }

    return ThemeResolution(mode: targetMode, preset: targetPreset);
  }

  Future<void> loadFromPrefs(SharedPreferences prefs) async {
    final raw = prefs.getString(PrefKeys.theme);
    themeMode.value = _parseThemeMode(raw);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (themeMode.value == mode) return;
    themeMode.value = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.theme, _encodeThemeMode(mode));
  }

  static AppThemeMode _parseThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'female_dark':
        return AppThemeMode.femaleDark;
      case 'male_dark':
        return AppThemeMode.maleDark;
      case 'female_light':
        return AppThemeMode.femaleLight;
      case 'male_light':
        return AppThemeMode.maleLight;
      case 'system':
    }

    return AppThemeMode.system;
  }

  static String _encodeThemeMode(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'light';
      case AppThemeMode.dark:
        return 'dark';
      case AppThemeMode.femaleDark:
        return 'female_dark';
      case AppThemeMode.maleDark:
        return 'male_dark';
      case AppThemeMode.femaleLight:
        return 'female_light';
      case AppThemeMode.maleLight:
        return 'male_light';
      case AppThemeMode.system:
        return 'system';
    }
  }
}
