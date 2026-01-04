import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/theme/theme_preset.dart';
import 'package:smart_ledger/theme/ui_style.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

class AppThemeSeedController {
  AppThemeSeedController._();

  static final AppThemeSeedController instance = AppThemeSeedController._();

  final ValueNotifier<String> presetId = ValueNotifier<String>(
    ThemePresets.defaultId,
  );

  final ValueNotifier<UIStyle> uiStyle = ValueNotifier<UIStyle>(
    UIStyle.standard,
  );

  Future<void> loadFromPrefs(SharedPreferences prefs) async {
    final raw = prefs.getString(PrefKeys.themePresetId);
    presetId.value = _normalizePresetId(raw);

    final rawStyle = prefs.getString(PrefKeys.themeUiStyle);
    uiStyle.value = UIStyle.byId(rawStyle);

    // Initialize last_icon_theme_id to prevent unnecessary restarts on
    // first change
    if (prefs.getString('last_icon_theme_id') == null) {
      final isFemale = ThemePresets.female.any((p) => p.id == presetId.value);
      final iconThemeId = isFemale ? 'light' : 'dark';
      await prefs.setString('last_icon_theme_id', iconThemeId);
    }
  }

  Future<void> setPresetId(String id) async {
    final next = _normalizePresetId(id);
    if (presetId.value == next) return;
    presetId.value = next;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.themePresetId, next);

    // Automatic icon change removed to prevent unexpected app restarts.
    // Icon theme can now be synced manually in the Theme Settings screen.
  }

  Future<void> setUiStyle(UIStyle style) async {
    if (uiStyle.value == style) return;
    uiStyle.value = style;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.themeUiStyle, style.name);
  }

  static String _normalizePresetId(String? raw) {
    final trimmed = (raw ?? '').trim();
    final resolved = ThemePresets.byId(trimmed).id;
    return resolved;
  }
}
