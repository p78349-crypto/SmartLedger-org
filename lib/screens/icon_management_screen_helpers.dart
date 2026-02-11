// ignore_for_file: invalid_use_of_protected_member

part of 'icon_management_screen.dart';

/// Policy, permission checks, and slot management helpers.
extension IconManagementHelpers on _IconManagementScreenState {
  // ---------------------------------------------------------------------------
  // Redirect / page policy
  // ---------------------------------------------------------------------------

  bool _maybeRedirectToDedicatedScreen(int pageIndex) {
    if (!widget.redirectAssetRootToDedicatedScreens) return false;
    if (_redirectingToDedicated) return true;

    if (_assetReservedPages.contains(pageIndex)) {
      _redirectingToDedicated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.iconManagementAsset,
          arguments: IconManagementArgs(accountName: widget.accountName),
        );
      });
      return true;
    }

    if (_rootReservedPages.contains(pageIndex)) {
      _redirectingToDedicated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.iconManagementRoot,
          arguments: IconManagementArgs(accountName: widget.accountName),
        );
      });
      return true;
    }

    return false;
  }

  bool _isStatsReservedPage(int pageIndex) =>
      _statsReservedPages.contains(pageIndex);

  bool _isAssetReservedPage(int pageIndex) =>
      _assetReservedPages.contains(pageIndex);

  bool _isRootReservedPage(int pageIndex) =>
      _rootReservedPages.contains(pageIndex);

  bool _isSettingsOnlyPage(int pageIndex) =>
      _settingsOnlyPages.contains(pageIndex);

  bool _isAllowedOnPage(int pageIndex, String iconId) {
    // Screen saver shortcut: only placeable on page 1.
    if (iconId == ScreenSaverIds.shortcutIconId) {
      return pageIndex == ScreenSaverIds.shortcutAllowedMainPageIndex;
    }

    // Navigation shortcut: only placeable on 2nd page.
    if (iconId == _shortcutSettingsPage10Id) {
      return pageIndex == _shortcutSettingsAllowedPageIndex;
    }

    if (_isSettingsOnlyPage(pageIndex)) {
      return _settingsIconIds.contains(iconId);
    }
    if (_isStatsReservedPage(pageIndex)) {
      return _statsIconIds.contains(iconId);
    }
    if (_isAssetReservedPage(pageIndex)) {
      return _incomeIconIds.contains(iconId) ||
          _assetIconIds.contains(iconId);
    }
    if (_isRootReservedPage(pageIndex)) {
      return _rootIconIds.contains(iconId);
    }

    // Non-reserved pages: always block root/settings to keep them dedicated.
    if (_rootIconIds.contains(iconId)) return false;
    if (_settingsIconIds.contains(iconId)) return false;

    // Asset lock: when enabled, prevent asset+income from being placed on
    // non-asset pages, unless user explicitly allows it AND the asset session
    // is currently unlocked.
    if (_assetBiometricLockEnabled &&
        (_incomeIconIds.contains(iconId) ||
            _assetIconIds.contains(iconId))) {
      final canBypass =
          _allowAssetOutsideWhenUnlocked && _assetSessionUnlocked;
      if (!canBypass) return false;
    }

    return true;
  }

  bool _isBlockedForPage(int pageIndex, String iconId) =>
      !_isAllowedOnPage(pageIndex, iconId);

  bool _isBlockedForCurrentPage(String iconId) =>
      _isBlockedForPage(_pageIndex, iconId);

  bool _isExcludedByDedicatedCatalogPolicy(String iconId) {
    if (!widget.redirectAssetRootToDedicatedScreens) return false;
    if (_rootIconIds.contains(iconId)) return true;
    if (_assetIconIds.contains(iconId) ||
        _incomeIconIds.contains(iconId)) {
      return true;
    }
    return false;
  }

  void _updateSpecialPageIndices(List<MainPageConfig> configs) {
    var assetIndex = _assetPageIndex;
    var rootIndex = _rootPageIndex;
    for (int i = 0; i < configs.length; i++) {
      final cfg = configs[i];
      if (cfg.moduleKey == 'asset') assetIndex = i;
      if (cfg.moduleKey == 'root') rootIndex = i;
    }
    _assetPageIndex = assetIndex;
    _rootPageIndex = rootIndex;
  }

  // ---------------------------------------------------------------------------
  // Slot management
  // ---------------------------------------------------------------------------

  List<int> _dropZoneSlotIndices() {
    final n = _slots.length;
    if (n <= 4) return List<int>.generate(n, (i) => i);
    return List<int>.generate(4, (i) => n - 4 + i);
  }

  void _assignOrSwap(String draggedId, int targetIndex) {
    final currentIndex = _slots.indexOf(draggedId);
    if (currentIndex == -1) {
      _slots[targetIndex] = draggedId;
      return;
    }
    if (currentIndex == targetIndex) return;
    final temp = _slots[targetIndex];
    _slots[targetIndex] = draggedId;
    _slots[currentIndex] = temp;
  }

  List<MainFeatureIcon> _orderedIconsForPage(
    int pageIndex, {
    required List<String> order,
  }) {
    final icons = _autoFillSourceIconsForPage(pageIndex)
        .where((icon) => !_isBlockedForPage(pageIndex, icon.id))
        .toList(growable: false);
    if (icons.isEmpty) return const [];

    final byId = {for (final icon in icons) icon.id: icon};

    final ordered = <MainFeatureIcon>[];
    if (order.isNotEmpty) {
      for (final id in order) {
        final icon = byId[id];
        if (icon == null) continue;
        ordered.add(icon);
      }
    }

    for (final icon in icons) {
      if (order.contains(icon.id)) continue;
      ordered.add(icon);
    }
    return ordered;
  }

  List<String> _fillSlotsKeepingExisting({
    required int pageIndex,
    required List<String> slots,
    required List<String> order,
  }) {
    final next = List<String>.from(slots);
    final editable = List<int>.generate(_slotCount, (i) => i);

    // Policy: duplicates are not allowed.
    final seenExisting = <String>{};
    for (final i in editable) {
      final id = next[i].trim();
      if (id.isEmpty) continue;
      if (seenExisting.contains(id)) {
        next[i] = '';
        continue;
      }
      seenExisting.add(id);
    }

    // Policy: clear blocked icons for this page.
    for (final i in editable) {
      final id = next[i].trim();
      if (id.isEmpty) continue;
      if (_isBlockedForPage(pageIndex, id)) next[i] = '';
    }

    final used = <String>{
      for (final i in editable)
        if (next[i].trim().isNotEmpty) next[i].trim(),
    };

    final candidates = _orderedIconsForPage(pageIndex, order: order);
    var ci = 0;
    for (final i in editable) {
      if (next[i].trim().isNotEmpty) continue;
      while (ci < candidates.length) {
        final id = candidates[ci++].id;
        if (id.trim().isEmpty) continue;
        if (used.contains(id)) continue;
        next[i] = id;
        used.add(id);
        break;
      }
    }

    return next;
  }

  void _fillCurrentPageSlotsFull() {
    setState(() {
      _slots = _fillSlotsKeepingExisting(
        pageIndex: _pageIndex,
        slots: _slots,
        order: _order,
      );
    });
    _saveSlotsDebounced();
  }

  List<int> _visiblePageIndices() {
    final hidden = widget.hiddenPageIndices;
    return List<int>.generate(_pageCount, (i) => i)
        .where((i) => !hidden.contains(i))
        .toList(growable: false);
  }

  List<int> _editableSlotIndices() =>
      List<int>.generate(_slotCount, (i) => i);

  bool _isEditableSlotIndex(int slotIndex) => true;

  List<String> _normalizeSlotsForCurrentPage(List<String> slots) => slots;

  Set<String> _placedIdsOnPage() {
    final indices = _editableSlotIndices();
    return indices
        .map((i) => _slots[i])
        .where((id) => id.trim().isNotEmpty)
        .toSet();
  }

  bool _isPlacedOnPage(String iconId) {
    if (iconId.trim().isEmpty) return false;
    return _placedIdsOnPage().contains(iconId);
  }

  void _clearSelection() {
    setState(_pendingIds.clear);
  }
}
