import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

class AppThemeModeController {
  AppThemeModeController._();

  static final AppThemeModeController instance = AppThemeModeController._();

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  Future<void> loadFromPrefs(SharedPreferences prefs) async {
    final raw = prefs.getString(PrefKeys.theme);
    themeMode.value = _parseThemeMode(raw);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode.value == mode) return;
    themeMode.value = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.theme, _encodeThemeMode(mode));
  }

  static ThemeMode _parseThemeMode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
    }

    return ThemeMode.system;
  }

  static String _encodeThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
