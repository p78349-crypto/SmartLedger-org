import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/app_icon_service.dart';
import 'package:smart_ledger/theme/theme_preset.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

class AppThemeSeedController {
  AppThemeSeedController._();

  static final AppThemeSeedController instance = AppThemeSeedController._();

  final ValueNotifier<String> presetId = ValueNotifier<String>(
    ThemePresets.defaultId,
  );

  Future<void> loadFromPrefs(SharedPreferences prefs) async {
    final raw = prefs.getString(PrefKeys.themePresetId);
    presetId.value = _normalizePresetId(raw);
  }

  Future<void> setPresetId(String id) async {
    final next = _normalizePresetId(id);
    if (presetId.value == next) return;
    presetId.value = next;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.themePresetId, next);

    // Minimal system impact: change launcher icon only when the user
    // changes presets.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final isFemale = ThemePresets.female.any((p) => p.id == next);
      final iconThemeId = isFemale ? 'light' : 'dark';
      await AppIconService.setLauncherIconTheme(iconThemeId);
    }
  }

  static String _normalizePresetId(String? raw) {
    final trimmed = (raw ?? '').trim();
    final resolved = ThemePresets.byId(trimmed).id;
    return resolved;
  }
}
