// ignore_for_file: invalid_use_of_protected_member

part of 'icon_management_screen.dart';

/// Initialization, data loading/saving, and apply logic.
extension IconManagementLoad on _IconManagementScreenState {
  void _initializeState() {
    _pageIndex = _pageCount > 0
        ? widget.initialPageIndex.clamp(0, _pageCount - 1)
        : 0;
    final visible = _visiblePageIndices();
    if (visible.isNotEmpty && !visible.contains(_pageIndex)) {
      _pageIndex = visible.first;
    }

    if (_maybeRedirectToDedicatedScreen(_pageIndex)) return;

    _iconById = {
      for (final icon
          in MainFeatureIconCatalog.pages.expand((p) => p.items))
        icon.id: icon,
    };
    _iconPageIndexById = {
      for (final page in MainFeatureIconCatalog.pages)
        for (final icon in page.items) icon.id: page.index,
    };

    _incomeIconIds = MainFeatureIconCatalog.iconsForModuleKey('income')
        .map((e) => e.id)
        .toSet();
    _assetIconIds = MainFeatureIconCatalog.iconsForModuleKey('asset')
        .map((e) => e.id)
        .toSet();
    _rootIconIds = MainFeatureIconCatalog.iconsForModuleKey('root')
        .map((e) => e.id)
        .toSet();
    _statsIconIds = MainFeatureIconCatalog.iconsForModuleKey('stats')
        .map((e) => e.id)
        .toSet();
    _settingsIconIds = MainFeatureIconCatalog.iconsForModuleKey('settings')
        .map((e) => e.id)
        .toSet();

    _loadAll();
  }

  List<MainFeatureIcon> _autoFillSourceIconsForPage(int pageIndex) {
    if (_isStatsReservedPage(pageIndex)) {
      return MainFeatureIconCatalog.iconsForModuleKey('stats');
    }
    if (_isAssetReservedPage(pageIndex)) {
      final out = <MainFeatureIcon>[];
      out.addAll(MainFeatureIconCatalog.iconsForModuleKey('asset'));
      out.addAll(MainFeatureIconCatalog.iconsForModuleKey('income'));
      final seen = <String>{};
      return out.where((e) => seen.add(e.id)).toList(growable: false);
    }
    if (_isRootReservedPage(pageIndex)) {
      return MainFeatureIconCatalog.iconsForModuleKey('root');
    }
    if (_isSettingsOnlyPage(pageIndex)) {
      return MainFeatureIconCatalog.iconsForModuleKey('settings');
    }
    if (pageIndex < 0 || pageIndex >= MainFeatureIconCatalog.pages.length) {
      return const [];
    }
    return MainFeatureIconCatalog.pages[pageIndex].items;
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final biometricEnabled =
        prefs.getBool(PrefKeys.biometricAuthEnabled) ?? false;
    final allowAssetOutside = prefs.getBool(
            PrefKeys.iconAllowAssetIconsOutsideAssetWhenUnlocked) ??
        false;
    final untilMs = prefs.getInt(PrefKeys.assetAuthSessionUntilMs);
    final unlockedNow =
        untilMs != null && DateTime.now().millisecondsSinceEpoch < untilMs;
    final configs = await UserPrefService.getMainPageConfigs(
      accountName: widget.accountName,
      pageCount: _pageCount,
    );
    _updateSpecialPageIndices(configs);

    final slots = await UserPrefService.getPageIconSlots(
      accountName: widget.accountName,
      pageIndex: _pageIndex,
      profileKey: widget.prefProfileKey,
    );
    final settings = await UserPrefService.getPageIconSettings(
      accountName: widget.accountName,
      pageIndex: _pageIndex,
      profileKey: widget.prefProfileKey,
    );
    final labelOverrides = await UserPrefService.getIconLabelOverrides(
      accountName: widget.accountName,
      profileKey: widget.prefProfileKey,
    );

    if (!mounted) return;
    final normalizedSlots = _normalizeSlotsForCurrentPage(slots);
    final filledSlots = _fillSlotsKeepingExisting(
      pageIndex: _pageIndex,
      slots: normalizedSlots,
      order: settings.order,
    );
    setState(() {
      _slots = filledSlots;
      _order = settings.order;
      _labelOverrides = labelOverrides;
      _assetBiometricLockEnabled = biometricEnabled;
      _allowAssetOutsideWhenUnlocked = allowAssetOutside;
      _assetSessionUnlocked = unlockedNow;
      _isLoading = false;
      _pendingIds.clear();
    });

    if (filledSlots.join('|') != slots.join('|')) {
      await UserPrefService.setPageIconSlots(
        accountName: widget.accountName,
        pageIndex: _pageIndex,
        slots: filledSlots,
        profileKey: widget.prefProfileKey,
      );
    }
  }

  String _effectiveLabelFor(String iconId) {
    final override = _labelOverrides[iconId];
    if (override != null && override.trim().isNotEmpty) return override;
    final meta = _iconById[iconId];
    return meta?.label ?? iconId;
  }

  Future<void> _applyPending() async {
    if (_pendingIds.isEmpty) return;

    final editable = _editableSlotIndices();
    var nextSlots = List<String>.from(_slots);

    int firstEmptySlotIndex() {
      for (final i in editable) {
        if (nextSlots[i].trim().isEmpty) return i;
      }
      return -1;
    }

    for (final id in _pendingIds) {
      if (id.trim().isEmpty) continue;
      if (_isBlockedForCurrentPage(id)) continue;
      if (nextSlots.contains(id)) continue;
      final empty = firstEmptySlotIndex();
      if (empty == -1) break;
      nextSlots[empty] = id;
    }

    nextSlots = _normalizeSlotsForCurrentPage(nextSlots);

    setState(() {
      _slots = nextSlots;
    });

    await UserPrefService.setPageIconSettings(
      accountName: widget.accountName,
      pageIndex: _pageIndex,
      order: _order,
      profileKey: widget.prefProfileKey,
    );
    await UserPrefService.setPageIconSlots(
      accountName: widget.accountName,
      pageIndex: _pageIndex,
      slots: nextSlots,
      profileKey: widget.prefProfileKey,
    );

    if (!mounted) return;
    setState(_pendingIds.clear);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('적용했습니다')));
  }

  String _catalogSectionTitleForPage(int pageIndex) => 'Index $pageIndex';

  Future<void> _saveSlotsDebounced() async {
    var nextSlots = _normalizeSlotsForCurrentPage(_slots);
    nextSlots = _fillSlotsKeepingExisting(
      pageIndex: _pageIndex,
      slots: nextSlots,
      order: _order,
    );

    if (nextSlots.join('|') != _slots.join('|')) {
      if (!mounted) return;
      setState(() {
        _slots = nextSlots;
      });
    }
    await UserPrefService.setPageIconSlots(
      accountName: widget.accountName,
      pageIndex: _pageIndex,
      slots: nextSlots,
      profileKey: widget.prefProfileKey,
    );
  }
}
