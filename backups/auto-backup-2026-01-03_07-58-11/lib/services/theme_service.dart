import 'dart:io';
import 'package:flutter/material.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/image_utils.dart';

import 'package:smart_ledger/utils/theme_presets.dart';

class ThemeService extends ChangeNotifier {
  ThemeVariant? _preview;
  ThemeVariant? _appliedIconVariant;
  ThemeVariant? _appliedWallpaperVariant;

  ThemeService._privateConstructor();
  static final ThemeService instance = ThemeService._privateConstructor();

  /// Current variant used for live preview (falls back to applied icon variant)
  ThemeVariant get current => _preview ?? _appliedIconVariant ?? ThemeVariant.vibrantBlue;

  Future<void> load() async {
    final iconId = await UserPrefService.getThemeIconBgPresetId();
    final wallId = await UserPrefService.getThemeWallpaperPresetId();

    _appliedIconVariant = ThemeVariant.byId(iconId) ?? ThemeVariant.vibrantBlue;
    _appliedWallpaperVariant = ThemeVariant.byId(wallId) ?? _appliedIconVariant;

    // Prune cache in background to limit disk usage
    pruneCache();

    notifyListeners();
  }

  /// Currently applied wallpaper variant (may differ from icon variant)
  ThemeVariant? get appliedWallpaper => _appliedWallpaperVariant;

  /// Map theme variant -> wallpaper asset path (app bundle). Local-first; can be replaced with SAF URI mapping later.
  String wallpaperAssetFor(ThemeVariant v) {
    switch (v.id) {
      case 'vibrant_blue':
        return 'assets/images/wallpapers/vibrant_blue.png';
      case 'aqua_green':
        return 'assets/images/wallpapers/aqua_green.png';
      case 'purple_pink':
        return 'assets/images/wallpapers/purple_pink.png';
      case 'warm_orange':
        return 'assets/images/wallpapers/warm_orange.png';
      case 'neutral_dark':
      default:
        return 'assets/images/wallpapers/neutral_dark.png';
    }
  }

  /// Returns local wallpaper file path if user selected one, otherwise null
  Future<String?> getLocalWallpaperPath() async {
    return await UserPrefService.getThemeLocalWallpaperPath();
  }

  /// Process a chosen image file and set as the local wallpaper (applies immediately)
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
    await UserPrefService.setThemeWallpaperPresetId(presetId: ThemeVariant.vibrantBlue.id);
    _appliedWallpaperVariant = ThemeVariant.vibrantBlue;
    notifyListeners();
  }

  /// Returns either a local file path (if set) else an asset path for appliedWallpaper
  Future<String> wallpaperForCurrent() async {
    final local = await getLocalWallpaperPath();
    if (local != null && local.isNotEmpty) return local;
    final applied = appliedWallpaper ?? ThemeVariant.vibrantBlue;
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
  Future<void> applyPreview({bool applyIcons = true, bool applyWallpaper = true}) async {
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

