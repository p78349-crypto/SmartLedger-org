part of 'account_main_screen.dart';

// ignore_for_file: invalid_use_of_protected_member

extension IconGridPageIcons on _IconGridPageState {
  List<MainFeatureIcon> _iconsForReservedPage(int pageIndex) {
    String? moduleKey;
    List<int> targetPages = const <int>[];

    if (_settingsOnlyPages.contains(pageIndex)) {
      moduleKey = 'settings';
      targetPages = _settingsOnlyPages.toList()..sort();
    } else if (_rootReservedPages.contains(pageIndex)) {
      moduleKey = 'root';
      targetPages = _rootReservedPages.toList()..sort();
    } else if (_assetReservedPages.contains(pageIndex)) {
      moduleKey = 'asset';
      targetPages = _assetReservedPages.toList()..sort();
    } else if (_statsReservedPages.contains(pageIndex)) {
      moduleKey = 'stats';
      targetPages = _statsReservedPages.toList()..sort();
    }

    if (moduleKey == null) return const <MainFeatureIcon>[];

    final icons = MainFeatureIconCatalog.iconsForModuleKey(moduleKey);

    debugPrint(
      '📍 Page $pageIndex: moduleKey=$moduleKey, icons=${icons.length}',
    );

    if (targetPages.length <= 1) return icons;

    final indexInGroup = targetPages.indexOf(pageIndex);
    if (indexInGroup == -1) return icons;

    final chunkSize = (icons.length / targetPages.length).ceil();
    if (chunkSize <= 0) return const <MainFeatureIcon>[];

    final start = indexInGroup * chunkSize;
    if (start >= icons.length) return const <MainFeatureIcon>[];
    final end =
        (start + chunkSize) > icons.length ? icons.length : (start + chunkSize);
    return icons.sublist(start, end);
  }

  List<MainFeatureIcon> _getOrderedIcons() {
    final reservedIcons = _iconsForReservedPage(widget.pageIndex);
    final List<MainFeatureIcon> icons;

    if (reservedIcons.isNotEmpty ||
        _settingsOnlyPages.contains(widget.pageIndex) ||
        _rootReservedPages.contains(widget.pageIndex) ||
        _assetReservedPages.contains(widget.pageIndex) ||
        _statsReservedPages.contains(widget.pageIndex)) {
      icons = reservedIcons;
    } else if (widget.pageIndex < MainFeatureIconCatalog.pages.length) {
      icons = MainFeatureIconCatalog.pages[widget.pageIndex].items;
    } else {
      icons = const <MainFeatureIcon>[];
    }

    if (_iconOrder.isEmpty) return icons;

    final byId = {for (final icon in icons) icon.id: icon};
    final ordered = <MainFeatureIcon>[];
    for (final id in _iconOrder) {
      final icon = byId[id];
      if (icon != null) ordered.add(icon);
    }
    for (final icon in icons) {
      if (!_iconOrder.contains(icon.id)) ordered.add(icon);
    }
    return ordered;
  }

  bool _isStatsReservedPage(int pageIndex) =>
      _statsReservedPages.contains(pageIndex);

  bool _isAssetReservedPage(int pageIndex) =>
      _assetReservedPages.contains(pageIndex);

  bool _isRootReservedPage(int pageIndex) =>
      _rootReservedPages.contains(pageIndex);

  bool _isSettingsOnlyPage(int pageIndex) =>
      _settingsOnlyPages.contains(pageIndex);

  bool _isAllowedOnPage({
    required int pageIndex,
    required String iconId,
    required bool assetLockEnabled,
    required bool allowAssetOutsideWhenUnlocked,
    required bool assetSessionUnlocked,
  }) {
    // Screen saver shortcut: only placeable on page 1.
    if (iconId == ScreenSaverIds.shortcutIconId) {
      return pageIndex == ScreenSaverIds.shortcutAllowedMainPageIndex;
    }

    // Hard restrictions: settings and root are dedicated.
    if (_isSettingsOnlyPage(pageIndex)) {
      return _settingsIconIds.contains(iconId);
    }
    if (_settingsIconIds.contains(iconId)) return false;

    if (_isRootReservedPage(pageIndex)) {
      return _rootIconIds.contains(iconId);
    }
    if (_rootIconIds.contains(iconId)) return false;

    // Asset fixed policy: asset icons must live on index 4.
    if (_assetIconIds.contains(iconId)) {
      return _isAssetReservedPage(pageIndex);
    }

    // Optional: when asset lock is enabled, income icons are also restricted
    // outside asset pages unless explicitly allowed and currently unlocked.
    if (assetLockEnabled && _incomeIconIds.contains(iconId)) {
      if (_isAssetReservedPage(pageIndex)) return true;
      final canBypass = allowAssetOutsideWhenUnlocked && assetSessionUnlocked;
      return canBypass;
    }

    // If a page is reserved for stats, only allow stats module icons.
    if (_isStatsReservedPage(pageIndex)) {
      return _statsIconIds.contains(iconId);
    }

    return true;
  }

  MainFeatureIcon? _iconById(String id) {
    for (final page in MainFeatureIconCatalog.pages) {
      for (final icon in page.items) {
        if (icon.id == id) return icon;
      }
    }
    return null;
  }
}
