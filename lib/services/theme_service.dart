import 'dart:io';
import 'package:flutter/material.dart';
import 'user_pref_service.dart';
import '../utils/image_utils.dart';

import '../utils/theme_presets.dart';

class ThemeService extends ChangeNotifier {
  ThemeVariant? _preview;
  ThemeVariant? _appliedIconVariant;
  ThemeVariant? _appliedWallpaperVariant;

  ThemeService._privateConstructor();
  static final ThemeService instance = ThemeService._privateConstructor();

  /// Current variant used for live preview (falls back to applied icon variant)
  ThemeVariant get current =>
      _preview ?? _appliedIconVariant ?? ThemeVariant.miNavy;

  Future<void> load() async {
    final iconId = await UserPrefService.getThemeIconBgPresetId();
    final wallId = await UserPrefService.getThemeWallpaperPresetId();

    _appliedIconVariant = ThemeVariant.byId(iconId) ?? ThemeVariant.miNavy;
    _appliedWallpaperVariant = ThemeVariant.byId(wallId) ?? _appliedIconVariant;

    // Prune cache in background to limit disk usage
    pruneCache();

    notifyListeners();
  }

  /// Currently applied wallpaper variant (may differ from icon variant)
  ThemeVariant? get appliedWallpaper => _appliedWallpaperVariant;

  /// Map theme variant -> wallpaper asset path (app bundle).
  /// Local-first; can be replaced with SAF URI mapping later.
  String wallpaperAssetFor(ThemeVariant v) {
    // For now, map to existing wallpapers or a default
    if (v.id.startsWith('fi_') || v.id.startsWith('mi_')) {
      return 'assets/images/wallpapers/neutral_dark.png';
    }

    switch (v.id) {
      case 'fl_soft_pink':
      case 'fl_lavender':
        return 'assets/images/wallpapers/purple_pink.png';
      case 'fl_peach':
      case 'fl_mint':
        return 'assets/images/wallpapers/warm_orange.png';
      case 'fl_sky':
      case 'ml_teal':
        return 'assets/images/wallpapers/aqua_green.png';
      default:
        return 'assets/images/wallpapers/neutral_dark.png';
    }
  }

  /// Returns local wallpaper file path if user selected one, otherwise null
  Future<String?> getLocalWallpaperPath() async {
    return await UserPrefService.getThemeLocalWallpaperPath();
  }

  /// Process a chosen image file and set as the local wallpaper.
  /// Applies immediately.
  Future<void> applyLocalWallpaperFile(File input) async {
    final processed = await processAndCacheImage(input);
    await UserPrefService.setThemeLocalWallpaperPath(path: processed.path);
    // mark wallpaper preset as 'custom' for clarity
    await UserPrefService.setThemeWallpaperPresetId(presetId: 'custom');
    // ensure applied wallpaper variant reference points to custom (null)
    _appliedWallpaperVariant = null;

    // Prune cache after adding a new file
    await pruneCache();

    notifyListeners();
  }

  /// Remove local wallpaper (revert to variant-based wallpapers)
  Future<void> clearLocalWallpaper() async {
    await UserPrefService.setThemeLocalWallpaperPath(path: null);
    await UserPrefService.setThemeWallpaperPresetId(
      presetId: ThemeVariant.miNavy.id,
    );
    _appliedWallpaperVariant = ThemeVariant.miNavy;
    notifyListeners();
  }

  /// Returns a local file path (if set) or
  /// an asset path for the current wallpaper.
  Future<String> wallpaperForCurrent() async {
    final local = await getLocalWallpaperPath();
    if (local != null && local.isNotEmpty) return local;
    final applied = appliedWallpaper ?? ThemeVariant.miNavy;
    return wallpaperAssetFor(applied);
  }

  /// Preview a variant (non-destructive)
  void preview(ThemeVariant v) {
    _preview = v;
    notifyListeners();
  }

  /// Reset preview to the applied variants
  void resetPreview() {
    _preview = null;
    notifyListeners();
  }

  /// Apply the preview variant to icons and/or wallpaper depending on flags.
  Future<void> applyPreview({
    bool applyIcons = true,
    bool applyWallpaper = true,
  }) async {
    if (_preview == null) return;

    final toApply = _preview!;
    if (applyIcons) {
      _appliedIconVariant = toApply;
      await UserPrefService.setThemeIconBgPresetId(presetId: toApply.id);
    }
    if (applyWallpaper) {
      _appliedWallpaperVariant = toApply;
      await UserPrefService.setThemeWallpaperPresetId(presetId: toApply.id);
    }

    _preview = null;
    notifyListeners();
  }
}
