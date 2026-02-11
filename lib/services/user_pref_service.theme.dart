part of 'user_pref_service.dart';

const _themePresetsKey = 'theme_presets_v1';

Future<String?> _getThemePresetId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(PrefKeys.themePresetId);
}

Future<void> _setThemePresetId({required String presetId}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(PrefKeys.themePresetId, presetId);
}

Future<String?> _getThemeIconBgPresetId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(PrefKeys.themeIconBgPresetId);
}

Future<void> _setThemeIconBgPresetId({required String presetId}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(PrefKeys.themeIconBgPresetId, presetId);
}

Future<String?> _getThemeWallpaperPresetId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(PrefKeys.themeWallpaperPresetId);
}

Future<void> _setThemeWallpaperPresetId({required String presetId}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(PrefKeys.themeWallpaperPresetId, presetId);
}

Future<String?> _getThemeLocalWallpaperPath() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(PrefKeys.themeLocalWallpaperPath);
}

Future<void> _setThemeLocalWallpaperPath({required String? path}) async {
  final prefs = await SharedPreferences.getInstance();
  if (path == null) {
    await prefs.remove(PrefKeys.themeLocalWallpaperPath);
  } else {
    await prefs.setString(PrefKeys.themeLocalWallpaperPath, path);
  }
}

Future<Map<String, Map<String, dynamic>>> _getThemePresets() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_themePresetsKey);
  if (raw == null) return {};
  try {
    final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return decoded.map(
      (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
    );
  } catch (_) {
    return {};
  }
}

Future<void> _setThemePreset({
  required String id,
  required Map<String, dynamic> data,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = await _getThemePresets();
  existing[id] = data;
  await prefs.setString(_themePresetsKey, jsonEncode(existing));
}

Future<void> _removeThemePreset({required String id}) async {
  final prefs = await SharedPreferences.getInstance();
  final existing = await _getThemePresets();
  existing.remove(id);
  await prefs.setString(_themePresetsKey, jsonEncode(existing));
}
