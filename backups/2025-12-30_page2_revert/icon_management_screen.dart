import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/main_page_config.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/main_feature_icon_catalog.dart';
import 'package:smart_ledger/utils/page1_bottom_quick_icons.dart';
import 'package:smart_ledger/utils/pref_keys.dart';
import 'package:smart_ledger/utils/screen_saver_ids.dart';

class IconManagementScreen extends StatefulWidget {
  final String accountName;

  /// Optional preference profile key.
  ///
  /// When set, icon layout/hidden/origins/label overrides are stored separately
  /// from the default icon management.
  final String? prefProfileKey;

  /// Initial page to show (0-based).
  final int initialPageIndex;

  /// Whether user can switch pages via the dropdown.
  final bool pagePickerEnabled;

  /// Optional title override for specialized entrypoints.
  final String? titleOverride;

  /// Whether to show the current page indicator in the app bar.
  ///
  /// When false, the app bar status line omits the "N페이지" part.
  final bool showCurrentPageIndicator;

  /// Whether to show the clear-selection (X) action in the app bar.
  final bool showClearSelectionAction;

  /// Whether to reserve space for the clear-selection action even when hidden.
  ///
  /// Useful when you want the apply (ENT) button to stay aligned with screens
  /// that do show the clear-selection action.
  final bool reserveClearSelectionActionSpace;

  /// Whether to flatten the icon catalog (no per-page sections).
  ///
  /// When true, icons are shown as a single list (sorted by label), and
  /// page section headers like "1페이지" are not shown.
  final bool flattenCatalog;

  /// Whether to group the icon catalog by feature modules (e.g., 자산/통계).
  ///
  /// When true, icons are grouped by logical modules rather than page indices.
  /// This is useful for Icon Management 2 where you want functional grouping.
  final bool groupCatalogByModule;

  /// Whether to show per-page section titles in the icon catalog.
  final bool showCatalogSectionTitles;

  /// Pages to hide from the page picker (0-based page indices).
  ///
  /// This only affects the page picker UI; the underlying catalog page count
  /// remains unchanged.
  final Set<int> hiddenPageIndices;

  /// Whether asset/root pages should be managed only via dedicated screens.
  ///
  /// When true, attempting to open/select asset pages (6~7 => {5,6}) or root
  /// pages (8~9 => {7,8}) in this screen will redirect to
  /// [AppRoutes.iconManagementAsset] / [AppRoutes.iconManagementRoot].
  ///
  /// Dedicated wrappers like IconManagementAssetScreen/RootScreen should set
  /// this to false to avoid redirect loops.
  final bool redirectAssetRootToDedicatedScreens;

  /// Optional pages to hide from the icon catalog (0-based page indices).
  ///
  /// When null, [hiddenPageIndices] is also applied to the catalog.
  final Set<int>? catalogHiddenPageIndices;

  const IconManagementScreen({
    super.key,
    required this.accountName,
    this.initialPageIndex = 0,
    this.pagePickerEnabled = true,
    this.titleOverride,
    this.prefProfileKey,
    this.showCurrentPageIndicator = true,
    this.showClearSelectionAction = true,
    this.reserveClearSelectionActionSpace = false,
    this.flattenCatalog = false,
    this.groupCatalogByModule = false,
    this.showCatalogSectionTitles = true,
    this.hiddenPageIndices = const <int>{},
    this.redirectAssetRootToDedicatedScreens = true,
    this.catalogHiddenPageIndices,
  });

  @override
  State<IconManagementScreen> createState() => _IconManagementScreenState();
}

class _CatalogSection {
  final int pageIndex;
  final String title;
  final List<MainFeatureIcon> icons;

  const _CatalogSection({
    required this.pageIndex,
    required this.title,
    required this.icons,
  });
}

class _IconManagementScreenState extends State<IconManagementScreen> {
  static const int _slotCount = Page1BottomQuickIcons.slotCount;
  static final int _pageCount = MainFeatureIconCatalog.pageCount;

  bool _isLoading = true;
  late int _pageIndex;

  final Set<String> _pendingIds = <String>{};

  List<String> _slots = List<String>.filled(_slotCount, '');
  List<String> _order = <String>[];
  Map<String, String> _labelOverrides = <String, String>{};

  late final Map<String, MainFeatureIcon> _iconById;
  late final Map<String, int> _iconPageIndexById;

  bool _assetBiometricLockEnabled = false;

  Set<int> get _catalogHiddenPages =>
      widget.catalogHiddenPageIndices ?? widget.hiddenPageIndices;
  bool _allowAssetOutsideWhenUnlocked = false;
  bool _assetSessionUnlocked = false;
  int _assetPageIndex = 3;
  int _rootPageIndex = 4;

  // Reserved page policy (0-based indices):
  // - 2: stats (page 3)
  // - 3: asset (page 4)
  // - 4: root (page 5)
  // - 5: settings (page 6)
  static const Set<int> _statsReservedPages = <int>{2};
  static const Set<int> _assetReservedPages = <int>{3};
  static const Set<int> _rootReservedPages = <int>{4};
  static const Set<int> _settingsOnlyPages = <int>{5};

  static const String _shortcutSettingsPage10Id = 'shortcut_settings_page10';
  static const int _shortcutSettingsAllowedPageIndex = 1; // 2nd page (1-based)

  late final Set<String> _incomeIconIds;
  late final Set<String> _assetIconIds;
  late final Set<String> _rootIconIds;
  late final Set<String> _statsIconIds;
  late final Set<String> _settingsIconIds;

  bool _redirectingToDedicated = false;

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

  bool _isStatsReservedPage(int pageIndex) {
    return _statsReservedPages.contains(pageIndex);
  }

  bool _isAssetReservedPage(int pageIndex) {
    return _assetReservedPages.contains(pageIndex);
  }

  bool _isRootReservedPage(int pageIndex) {
    return _rootReservedPages.contains(pageIndex);
  }

  bool _isSettingsOnlyPage(int pageIndex) {
    return _settingsOnlyPages.contains(pageIndex);
  }

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
      return _incomeIconIds.contains(iconId) || _assetIconIds.contains(iconId);
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
        (_incomeIconIds.contains(iconId) || _assetIconIds.contains(iconId))) {
      final canBypass = _allowAssetOutsideWhenUnlocked && _assetSessionUnlocked;
      if (!canBypass) return false;
    }

    return true;
  }

  bool _isBlockedForPage(int pageIndex, String iconId) {
    return !_isAllowedOnPage(pageIndex, iconId);
  }

  bool _isBlockedForCurrentPage(String iconId) {
    return _isBlockedForPage(_pageIndex, iconId);
  }

  bool _isExcludedByDedicatedCatalogPolicy(String iconId) {
    // When asset/root are managed via dedicated screens, keep their icons
    // out of the generic catalog to reduce confusion.
    if (!widget.redirectAssetRootToDedicatedScreens) return false;
    if (_rootIconIds.contains(iconId)) return true;
    if (_assetIconIds.contains(iconId) || _incomeIconIds.contains(iconId)) {
      return true;
    }
    return false;
  }

  void _updateSpecialPageIndices(List<MainPageConfig> configs) {
    // Defaults are aligned with UserPrefService.defaultMainPageConfigs.
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

  List<int> _dropZoneSlotIndices() {
    // Default pages: show the bottom row (last 4 slots).
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
        .where((icon) {
          if (_isBlockedForPage(pageIndex, icon.id)) return false;
          return true;
        })
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

    // Policy: duplicates are not allowed. If duplicates exist, keep the first
    // occurrence and clear later ones.
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
      if (_isBlockedForPage(pageIndex, id)) {
        next[i] = '';
      }
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
    return List<int>.generate(
      _pageCount,
      (i) => i,
    ).where((i) => !hidden.contains(i)).toList(growable: false);
  }

  List<int> _editableSlotIndices() {
    return List<int>.generate(_slotCount, (i) => i);
  }

  bool _isEditableSlotIndex(int slotIndex) {
    return true;
  }

  List<String> _normalizeSlotsForCurrentPage(List<String> slots) {
    return slots;
  }

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

  @override
  void initState() {
    super.initState();
    _pageIndex = _pageCount > 0
        ? widget.initialPageIndex.clamp(0, _pageCount - 1)
        : 0;
    final visible = _visiblePageIndices();
    if (visible.isNotEmpty && !visible.contains(_pageIndex)) {
      _pageIndex = visible.first;
    }

    if (_maybeRedirectToDedicatedScreen(_pageIndex)) {
      return;
    }
    _iconById = {
      for (final icon in MainFeatureIconCatalog.pages.expand((p) => p.items))
        icon.id: icon,
    };
    _iconPageIndexById = {
      for (final page in MainFeatureIconCatalog.pages)
        for (final icon in page.items) icon.id: page.index,
    };

    _incomeIconIds = MainFeatureIconCatalog.iconsForModuleKey(
      'income',
    ).map((e) => e.id).toSet();
    _assetIconIds = MainFeatureIconCatalog.iconsForModuleKey(
      'asset',
    ).map((e) => e.id).toSet();
    _rootIconIds = MainFeatureIconCatalog.iconsForModuleKey(
      'root',
    ).map((e) => e.id).toSet();

    _statsIconIds = MainFeatureIconCatalog.iconsForModuleKey(
      'stats',
    ).map((e) => e.id).toSet();
    _settingsIconIds = MainFeatureIconCatalog.iconsForModuleKey(
      'settings',
    ).map((e) => e.id).toSet();

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
      // Remove duplicates by id.
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
    final allowAssetOutside =
        prefs.getBool(PrefKeys.iconAllowAssetIconsOutsideAssetWhenUnlocked) ??
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
      slotCount: _slotCount,
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
    return meta?.labelFor(context) ?? iconId;
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

    // Prototype mode: never hide. Apply only places selected icons into empty
    // editable slots (best-effort).
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('적용했습니다')));
  }

  String _catalogSectionTitleForPage(int pageIndex) {
    return '${pageIndex + 1}페이지';
  }

  Widget _buildCatalogIconTile(ThemeData theme, MainFeatureIcon icon) {
    final scheme = theme.colorScheme;
    final isSelected = _pendingIds.contains(icon.id);

    final blocked = _isBlockedForCurrentPage(icon.id);
    final isAllowed = !blocked;

    final isPlaced = _isPlacedOnPage(icon.id);

    final bgColor = isSelected
        ? scheme.primaryContainer
        : (isPlaced ? scheme.tertiaryContainer : scheme.surface);

    final borderColor = isSelected
        ? scheme.primary
        : (isPlaced ? scheme.tertiary : scheme.outlineVariant);

    return Opacity(
      opacity: isAllowed ? 1.0 : 0.45,
      child: InkWell(
        key: ValueKey<String>('icon_mgmt_catalog_${icon.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          if (!isAllowed) {
            if (blocked) {
              final msg = _settingsIconIds.contains(icon.id)
                  ? '설정 아이콘은 10페이지에서만 노출할 수 있습니다'
                  : (_rootIconIds.contains(icon.id)
                        ? 'ROOT 아이콘은 8~9페이지에서만 노출할 수 있습니다'
                        : (_isStatsReservedPage(_pageIndex)
                              ? '4~5페이지는 통계 아이콘 전용입니다'
                              : (_isAssetReservedPage(_pageIndex)
                                    ? '6~7페이지는 자산/수입 아이콘 전용입니다'
                                    : '현재 페이지 정책상 배치할 수 없습니다')));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(msg)));
              return;
            }
          }
          setState(() {
            if (isSelected) {
              _pendingIds.remove(icon.id);
            } else {
              _pendingIds.add(icon.id);
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            color: bgColor,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon.icon, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      _effectiveLabelFor(icon.id),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  isSelected
                      ? IconCatalog.checkCircle
                      : IconCatalog.radioButtonUnchecked,
                  size: 22,
                  color: isSelected ? scheme.primary : scheme.outline,
                ),
              ),
              if (isPlaced)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.tertiary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '배치',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onTertiary,
                      ),
                    ),
                  ),
                ),
              if (!isAllowed)
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Text(
                      '하단불가',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSlots(ThemeData theme) {
    final scheme = theme.colorScheme;

    // 배치된 아이콘들 vs 빈 슬롯들 분리 (전체 슬롯)
    final placedSlots = <(int index, String id)>[];
    final emptySlots = <int>[];

    for (var i = 0; i < _slots.length; i++) {
      final iconId = _slots[i];
      if (iconId.trim().isNotEmpty) {
        placedSlots.add((i, iconId));
      } else {
        emptySlots.add(i);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 배치된 아이콘들
        if (placedSlots.isNotEmpty) ...[
          Text(
            '현재 배치 (${placedSlots.length}개)',
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: placedSlots.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final iconId = placedSlots[index].$2;
                final icon = _iconById[iconId];

                return SizedBox(
                  width: 80,
                  child: LongPressDraggable<String>(
                    data: iconId,
                    feedback: Opacity(
                      opacity: 0.9,
                      child: SizedBox(
                        width: 70,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: scheme.primaryContainer,
                                border: Border.all(color: scheme.primary),
                              ),
                              child: Center(
                                child: Icon(
                                  icon?.icon ?? IconCatalog.help,
                                  size: 28,
                                  color: scheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              icon?.labelFor(context) ?? iconId,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: scheme.primaryContainer,
                              border: Border.all(color: scheme.primary),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: scheme.primaryContainer,
                            border: Border.all(color: scheme.primary),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  icon?.icon ?? IconCatalog.help,
                                  size: 28,
                                  color: scheme.primary,
                                ),
                              ),
                              Positioned(
                                right: -6,
                                top: -6,
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: scheme.primary,
                                  ),
                                  child: Icon(
                                    IconCatalog.check,
                                    size: 14,
                                    color: scheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          icon?.labelFor(context) ?? iconId,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 하단 슬롯(드롭존): 항상 4개 표시
        Row(
          children: [
            Expanded(
              child: Text(
                '빈 슬롯 (드롭존 4개)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: _fillCurrentPageSlotsFull,
              child: const Text('FULL'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final dropSlots = _dropZoneSlotIndices();

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final slotIndex = index < dropSlots.length
                    ? dropSlots[index]
                    : -1;
                final isValidSlot = slotIndex >= 0 && slotIndex < _slots.length;
                final slotId = isValidSlot ? _slots[slotIndex] : '';
                final isEmpty = slotId.trim().isEmpty;
                final icon = (!isEmpty && isValidSlot)
                    ? _iconById[slotId]
                    : null;

                Widget tileContent;
                if (isEmpty) {
                  tileContent = Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        IconCatalog.add,
                        size: 24,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '추가',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                } else {
                  tileContent = Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon?.icon ?? IconCatalog.help,
                        size: 24,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        icon?.labelFor(context) ?? slotId,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                }

                Widget baseTile({required bool highlight}) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    transform: Matrix4.diagonal3Values(
                      highlight ? 1.05 : 1.0,
                      highlight ? 1.05 : 1.0,
                      1.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: highlight
                            ? scheme.primary
                            : scheme.outlineVariant,
                        width: highlight ? 2 : 1,
                      ),
                      color: highlight
                          ? scheme.primaryContainer
                          : scheme.surfaceContainerHighest,
                    ),
                    child: Center(child: tileContent),
                  );
                }

                DragTarget<String> target() {
                  return DragTarget<String>(
                    onWillAcceptWithDetails: (details) {
                      final draggedId = details.data;
                      if (draggedId.trim().isEmpty) return false;
                      if (_isBlockedForCurrentPage(draggedId)) return false;
                      return true;
                    },
                    onAcceptWithDetails: (details) {
                      final draggedId = details.data;

                      if (_isBlockedForCurrentPage(draggedId)) {
                        final msg = _settingsIconIds.contains(draggedId)
                            ? '설정 아이콘은 10페이지에서만 노출할 수 있습니다'
                            : (_rootIconIds.contains(draggedId)
                                  ? 'ROOT 아이콘은 8~9페이지에서만 노출할 수 있습니다'
                                  : (_isStatsReservedPage(_pageIndex)
                                        ? '4~5페이지는 통계 아이콘 전용입니다'
                                        : (_isAssetReservedPage(_pageIndex)
                                              ? '6~7페이지는 자산/수입 아이콘 전용입니다'
                                              : '현재 페이지 정책상 배치할 수 없습니다')));
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(msg)));
                        return;
                      }
                      if (!isValidSlot) return;
                      if (draggedId.trim().isEmpty) return;

                      if (!_isEditableSlotIndex(slotIndex)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('이 슬롯에는 배치할 수 없습니다')),
                        );
                        return;
                      }

                      setState(() {
                        _assignOrSwap(draggedId, slotIndex);
                        _slots = _normalizeSlotsForCurrentPage(_slots);
                      });
                      _saveSlotsDebounced();
                    },
                    builder: (context, candidateData, rejectedData) {
                      final highlight = candidateData.isNotEmpty;
                      return baseTile(highlight: highlight);
                    },
                  );
                }

                if (isEmpty || !isValidSlot) {
                  return target();
                }

                // Allow dragging icons already placed in bottom slots.
                return LongPressDraggable<String>(
                  data: slotId,
                  feedback: Opacity(
                    opacity: 0.9,
                    child: SizedBox(
                      width: 80,
                      child: baseTile(highlight: true),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: baseTile(highlight: false),
                  ),
                  child: target(),
                );
              },
            );
          },
        ),
      ],
    );
  }

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

  Widget _buildIconCatalogPicker(ThemeData theme) {
    if (widget.groupCatalogByModule) {
      const moduleOrder = <({String key, String title})>[
        (key: 'page1', title: '기본'),
        (key: 'purchase', title: '구매'),
        (key: 'stats', title: '통계'),
        (key: 'asset', title: '자산'),
        (key: 'root', title: 'ROOT'),
        (key: 'settings', title: '설정'),
      ];

      final sections = <(String title, List<MainFeatureIcon> icons)>[];
      for (final entry in moduleOrder) {
        if (widget.redirectAssetRootToDedicatedScreens &&
            (entry.key == 'asset' || entry.key == 'root')) {
          continue;
        }
        final icons = <MainFeatureIcon>[];
        final seen = <String>{};
        final includeIncomeInAsset =
            entry.key == 'asset' && !widget.redirectAssetRootToDedicatedScreens;
        final sources = <MainFeatureIcon>[
          ...MainFeatureIconCatalog.iconsForModuleKey(entry.key),
          if (includeIncomeInAsset)
            ...MainFeatureIconCatalog.iconsForModuleKey('income'),
        ];

        for (final icon in sources) {
          if (seen.contains(icon.id)) continue;
          seen.add(icon.id);

          if (_isExcludedByDedicatedCatalogPolicy(icon.id)) continue;

          final pageIndex = _iconPageIndexById[icon.id];
          if (pageIndex != null && _catalogHiddenPages.contains(pageIndex)) {
            continue;
          }
          icons.add(icon);
        }

        icons.sort((a, b) {
          final al = _effectiveLabelFor(a.id);
          final bl = _effectiveLabelFor(b.id);
          return al.compareTo(bl);
        });

        if (icons.isEmpty) continue;
        sections.add((entry.title, icons));
      }

      if (sections.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final section in sections) ...[
            if (widget.showCatalogSectionTitles)
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(
                  section.$1,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: section.$2.length,
              itemBuilder: (context, index) {
                final icon = section.$2[index];
                return _buildCatalogIconTile(theme, icon);
              },
            ),
          ],
        ],
      );
    }

    if (widget.flattenCatalog) {
      final icons = <MainFeatureIcon>[];
      for (final page in MainFeatureIconCatalog.pages) {
        if (_catalogHiddenPages.contains(page.index)) continue;
        if (page.items.isEmpty) continue;
        icons.addAll(
          page.items.where(
            (icon) =>
                !_isBlockedForCurrentPage(icon.id) &&
                !_isExcludedByDedicatedCatalogPolicy(icon.id),
          ),
        );
      }

      icons.sort((a, b) {
        final al = _effectiveLabelFor(a.id);
        final bl = _effectiveLabelFor(b.id);
        return al.compareTo(bl);
      });

      if (icons.isEmpty) return const SizedBox.shrink();

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: icons.length,
        itemBuilder: (context, index) {
          final icon = icons[index];
          return _buildCatalogIconTile(theme, icon);
        },
      );
    }

    final sections = <_CatalogSection>[];
    for (final page in MainFeatureIconCatalog.pages) {
      if (_catalogHiddenPages.contains(page.index)) continue;
      if (page.items.isEmpty) continue;

      final visible =
          List<MainFeatureIcon>.from(
            page.items.where(
              (icon) =>
                  !_isBlockedForCurrentPage(icon.id) &&
                  !_isExcludedByDedicatedCatalogPolicy(icon.id),
            ),
          )..sort((a, b) {
            final al = _effectiveLabelFor(a.id);
            final bl = _effectiveLabelFor(b.id);
            return al.compareTo(bl);
          });

      if (visible.isEmpty) continue;
      sections.add(
        _CatalogSection(
          pageIndex: page.index,
          title: _catalogSectionTitleForPage(page.index),
          icons: visible,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          if (widget.showCatalogSectionTitles)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(
                section.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: section.icons.length,
            itemBuilder: (context, index) {
              final icon = section.icons[index];
              return _buildCatalogIconTile(theme, icon);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildApplyEnterKeyButton(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: OutlinedButton(
        onPressed: _pendingIds.isEmpty ? null : _applyPending,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 32)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
          side: WidgetStateProperty.resolveWith<BorderSide>((states) {
            final base = scheme.outlineVariant;
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: base.withValues(alpha: 0.55));
            }
            return BorderSide(color: base);
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return scheme.onSurfaceVariant.withValues(alpha: 0.55);
            }
            return scheme.onSurfaceVariant;
          }),
          backgroundColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
        ),
        child: const Text('ENT', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.titleOverride ?? '아이콘 관리';

    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.showCurrentPageIndicator
                    ? '${_pageIndex + 1}페이지 · 선택: ${_pendingIds.length}'
                    : '선택: ${_pendingIds.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        actions: [
          Tooltip(message: '적용', child: _buildApplyEnterKeyButton(theme)),
          if (widget.showClearSelectionAction)
            IconButton(
              tooltip: '선택해제',
              onPressed: _pendingIds.isEmpty ? null : _clearSelection,
              icon: const Icon(IconCatalog.clear),
            ),
          if (!widget.showClearSelectionAction &&
              widget.reserveClearSelectionActionSpace)
            const SizedBox(width: 48),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  '2) 현재 배치',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildCurrentSlots(theme),
                const SizedBox(height: 12),
                const Text(
                  '3) 아이콘 선택',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '여러 개 선택 후 상단(ENT)를 누르면 적용됩니다.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '배치됨: 현재 페이지에 배치됨 · 체크: 선택됨',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _buildIconCatalogPicker(theme),
              ],
            ),
    );
  }
}

