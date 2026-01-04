import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

enum AppThemeMode {
  system,
  light,
  dark,
  femaleDark,
  maleDark,
}

class AppThemeModeController {
  AppThemeModeController._();

  static final AppThemeModeController instance = AppThemeModeController._();

  final ValueNotifier<AppThemeMode> themeMode = ValueNotifier<AppThemeMode>(
    AppThemeMode.system,
  );

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
      case AppThemeMode.system:
        return 'system';
    }
  }
}
