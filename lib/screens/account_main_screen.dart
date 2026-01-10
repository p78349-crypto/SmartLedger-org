import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'memo_stats_screen.dart';
import '../services/user_pref_service.dart';
import '../theme/app_colors.dart';
import '../utils/icon_catalog.dart';
import '../utils/icon_launch_utils.dart';
import '../utils/interaction_blockers.dart';
import '../utils/main_feature_icon_catalog.dart';
import '../utils/memo_search_utils.dart';
import '../utils/page_indicator.dart';
import '../utils/pref_keys.dart';
import '../utils/screen_saver_ids.dart';
import '../utils/screen_saver_launcher.dart';
import '../widgets/background_widget.dart';
import '../widgets/emergency_button.dart';
import '../widgets/special_backgrounds.dart';
import '../theme/app_theme_seed_controller.dart';

class AccountMainScreen extends StatefulWidget {
  final String accountName;
  final int initialIndex;

  const AccountMainScreen({
    super.key,
    required this.accountName,
    this.initialIndex = 0,
  });

  @override
  State<AccountMainScreen> createState() => _AccountMainScreenState();
}

class _AccountMainScreenState extends State<AccountMainScreen>
    with WidgetsBindingObserver {
  static int get _pageCount => MainFeatureIconCatalog.pageCount;
  static const List<String> _pageNameLabels = <String>[
    '대시보드',
    '요리/쇼핑/지출',
    '수입',
    '통계',
    '자산',
    'ROOT',
    '설정',
  ];

  late final PageController _controller;
  int _currentIndex = 0;
  bool _isRestoringIndex = false;
  bool _disablePageSwipe = false;

  late final List<GlobalKey<_IconGridPageState>> _pageKeys;

  Future<void> _confirmAndResetMainPages() async {
    if (!mounted) return;

    final shouldReset = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메인 페이지 초기화'),
        content: const Text(
          '메인 페이지(1~15) 구성과 아이콘 배치가 모두 초기화됩니다.\n'
          '※ 거래/자산 등 데이터는 삭제되지 않습니다. (배치만 초기화)\n\n'
          '계속할까요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('초기화'),
          ),
        ],
      ),
    );

    if (shouldReset != true) return;

    final rawAccountName = widget.accountName;
    final trimmedAccountName = rawAccountName.trim();

    // Defensive: some legacy data may have been saved with accidental
    // whitespace differences in the account name.
    await UserPrefService.resetAccountMainPages(
      accountName: rawAccountName,
      pageCount: _pageCount,
    );
    if (trimmedAccountName.isNotEmpty && trimmedAccountName != rawAccountName) {
      await UserPrefService.resetAccountMainPages(
        accountName: trimmedAccountName,
        pageCount: _pageCount,
      );
    }

    if (!mounted) return;

    setState(() {
      _currentIndex = 0;
    });
    _controller.jumpToPage(0);

    for (final key in _pageKeys) {
      await key.currentState?.reloadFromPrefsPublic();
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('메인 페이지가 초기화되었습니다')));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = _pageCount > 0
        ? widget.initialIndex.clamp(0, _pageCount - 1)
        : 0;
    _controller = PageController(initialPage: _currentIndex);
    // Generate page keys based on current dynamic page count so the UI
    // adapts when pages are recreated at runtime.
    _pageKeys = List.generate(
      _pageCount,
      (_) => GlobalKey<_IconGridPageState>(),
    );
    _restoreSavedIndexIfNeeded();
  }

  void _showQuickJumpSheet() {
    final total = _pageCount;
    if (total <= 1) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  '페이지 바로가기',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ...List.generate(total, (index) {
                final label = _pageNameLabels[index];
                return ListTile(
                  title: Text('${index + 1}. $label'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // NOTE: Kept intentionally for future opt-in/manual use.
  // ignore: unused_element
  Future<void> _normalizeReservedPageIconSlotsBestEffort() async {
    // Fire-and-forget. Avoid blocking first paint.
    try {
      // Asset page policy: asset icons are fixed to the asset page (page 4).
      // Safety: never drops icons; if targets are full, leaves as-is.
      const enforceAssetPlacement = true;

      // Icon-id sets by module (derived from the catalog SSOT).
      final statsIds = <String>{
        ...MainFeatureIconCatalog.iconsForModuleKey('stats').map((e) => e.id),
      };

      final assetIds = MainFeatureIconCatalog.iconsForModuleKey(
        'asset',
      ).map((e) => e.id).toSet();

      final rootIds = MainFeatureIconCatalog.iconsForModuleKey(
        'root',
      ).map((e) => e.id).toSet();
      final settingsIds = MainFeatureIconCatalog.iconsForModuleKey(
        'settings',
      ).map((e) => e.id).toSet();

      // Policy pages (0-based main page indices).
      // NOTE: These are aligned with MainFeatureIconCatalog ordering.
      const statsTargetPages = <int>[3];
      const assetTargetPages = <int>[5];
      const rootTargetPages = <int>[6];
      const settingsTargetPages = <int>[8];

      List<int> targetsForId(String id) {
        if (settingsIds.contains(id)) return settingsTargetPages;
        if (rootIds.contains(id)) return rootTargetPages;
        if (enforceAssetPlacement && assetIds.contains(id)) {
          return assetTargetPages;
        }
        if (statsIds.contains(id)) return statsTargetPages;
        return const <int>[];
      }

      bool isReservedId(String id) {
        return statsIds.contains(id) ||
            (enforceAssetPlacement && assetIds.contains(id)) ||
            rootIds.contains(id) ||
            settingsIds.contains(id);
      }

      // Load all pages.
      final pages = <int, List<String>>{};
      for (int i = 0; i < _pageCount; i++) {
        pages[i] = await UserPrefService.getPageIconSlots(
          accountName: widget.accountName,
          pageIndex: i,
        );
      }

      // De-duplicate: keep first occurrence across all pages, drop the rest.
      final seen = <String>{};
      for (int pageIndex = 0; pageIndex < _pageCount; pageIndex++) {
        final slots = pages[pageIndex]!;
        for (int si = 0; si < slots.length; si++) {
          final id = slots[si];
          if (id.isEmpty) continue;
          if (seen.add(id)) continue;
          slots[si] = '';
        }
      }

      // Collect moves (id -> target pages), clear from illegal pages.
      final moves = <String, List<int>>{};
      for (int pageIndex = 0; pageIndex < _pageCount; pageIndex++) {
        final slots = pages[pageIndex]!;
        for (int si = 0; si < slots.length; si++) {
          final id = slots[si];
          if (id.isEmpty) continue;
          if (!isReservedId(id)) continue;

          final targets = targetsForId(id);
          if (targets.isEmpty) continue;

          // If current page is not allowed, move.
          if (!targets.contains(pageIndex)) {
            moves[id] = targets;
            slots[si] = '';
          }
        }
      }

      // Apply moves: place into first empty slot across target pages.
      for (final entry in moves.entries) {
        final id = entry.key;
        final targets = entry.value;

        var placed = false;
        for (final pageIndex in targets) {
          final slots = pages[pageIndex]!;
          final emptyIndex = slots.indexOf('');
          if (emptyIndex == -1) continue;
          slots[emptyIndex] = id;
          placed = true;
          break;
        }

        // If targets are full, keep behavior safe: do not drop.
        if (!placed) {
          // Put it back to its primary (catalog) page if possible.
          final fallbackPage = targets.first;
          final fallbackSlots = pages[fallbackPage]!;
          final emptyIndex = fallbackSlots.indexOf('');
          if (emptyIndex != -1) {
            fallbackSlots[emptyIndex] = id;
          }
        }
      }

      // Persist only if changed.
      for (int i = 0; i < _pageCount; i++) {
        final next = pages[i]!;
        final current = await UserPrefService.getPageIconSlots(
          accountName: widget.accountName,
          pageIndex: i,
        );
        if (_listEquals(current, next)) continue;
        await UserPrefService.setPageIconSlots(
          accountName: widget.accountName,
          pageIndex: i,
          slots: next,
        );
      }
    } catch (_) {
      // Best-effort: ignore.
    }
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> _restoreSavedIndexIfNeeded() async {
    // If caller explicitly provided a non-zero initial index, respect it.
    if (widget.initialIndex != 0) return;

    final saved = await UserPrefService.getMainPageIndex(
      accountName: widget.accountName,
    );
    if (!mounted) return;

    final desired = _pageCount > 0 ? (saved ?? 0).clamp(0, _pageCount - 1) : 0;
    if (desired == _currentIndex) return;

    _isRestoringIndex = true;
    _currentIndex = desired;
    _controller.jumpToPage(desired);
    _isRestoringIndex = false;
  }

  @override
  Widget build(BuildContext context) {
    // Phase 1: Smart style horizontal main pages (icons-only).
    // Top banner removed: only render the PageView.
    return ListenableBuilder(
      listenable: Listenable.merge([
        BackgroundHelper.colorNotifier,
        BackgroundHelper.typeNotifier,
        BackgroundHelper.imagePathNotifier,
        BackgroundHelper.blurNotifier,
      ]),
      builder: (context, _) {
        final bgColor = BackgroundHelper.colorNotifier.value;
        final bgType = BackgroundHelper.typeNotifier.value;
        final bgImagePath = BackgroundHelper.imagePathNotifier.value;
        final bgBlur = BackgroundHelper.blurNotifier.value;

        final presetId = AppThemeSeedController.instance.presetId.value;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;

        // DEBUG: 화면 크기 출력 (프로토타입/개발 모드 전용, 출시 전 자동 제거됨)
        if (kDebugMode) {
          final size = MediaQuery.of(context).size;
          final padding = MediaQuery.of(context).padding;
          debugPrint(
            '📱 화면 크기: ${size.width.toStringAsFixed(1)} '
            'x ${size.height.toStringAsFixed(1)}',
          );
          debugPrint(
            '📱 SafeArea 여백: top=${padding.top.toStringAsFixed(1)}, '
            'bottom=${padding.bottom.toStringAsFixed(1)}, '
            'left=${padding.left.toStringAsFixed(1)}, '
            'right=${padding.right.toStringAsFixed(1)}',
          );
          debugPrint(
            '📱 방향: ${isLandscape ? '가로(Landscape)' : '세로(Portrait)'}',
          );
        }

        final effectiveBgColor = bgColor;

        return Stack(
          children: [
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  if (bgType == 'image' && bgImagePath != null) {
                    return Image.file(
                      File(bgImagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          ColoredBox(color: effectiveBgColor),
                    );
                  }

                  if (presetId == 'midnight_gold') {
                    return MidnightGoldBackground(baseColor: effectiveBgColor);
                  } else if (presetId == 'starlight_navy') {
                    return StarlightNavyBackground(baseColor: effectiveBgColor);
                  }
                  return ColoredBox(color: effectiveBgColor);
                },
              ),
            ),

            // 2. Blur Effect (if image)
            if (bgType == 'image' && bgImagePath != null && bgBlur > 0)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: bgBlur, sigmaY: bgBlur),
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),

            // 3. Dark Overlay for images to ensure readability
            if (bgType == 'image' && bgImagePath != null)
              Positioned.fill(
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.2)),
              ),

            PageView.builder(
              controller: _controller,
              physics: _disablePageSwipe
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: _pageCount,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _disablePageSwipe =
                      _pageKeys[index].currentState?.isEditMode ?? false;
                });
                if (_isRestoringIndex) return;
                // Fire-and-forget: a best-effort persistence.
                UserPrefService.setMainPageIndex(
                  accountName: widget.accountName,
                  index: index,
                );
              },
              itemBuilder: (context, index) {
                return _IconGridPage(
                  key: _pageKeys[index],
                  accountName: widget.accountName,
                  pageIndex: index,
                  pageCount: _pageCount,
                  currentPage: _currentIndex,
                  pageController: _controller,
                  onRequestResetMainPages: _confirmAndResetMainPages,
                  onRequestQuickJump: _showQuickJumpSheet,
                  onRequestJumpToPage: (targetIndex) {
                    if (targetIndex < 0 || targetIndex >= _pageCount) {
                      return;
                    }
                    _controller.animateToPage(
                      targetIndex,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  onEditModeChanged: (isEditMode) {
                    if (index != _currentIndex) return;
                    if (_disablePageSwipe == isEditMode) return;
                    setState(() => _disablePageSwipe = isEditMode);
                  },
                );
              },
            ),
            // Page quick-jump indicator (bottom center)
            if (_pageCount > 0)
              // Top page label for pages 1..7 (small, non-intrusive)
              Positioned(
                left: 0,
                right: 0,
                top: isLandscape ? 4 : 12,
                child: SafeArea(
                  bottom: false,
                  child: Builder(
                    builder: (context) {
                      final showLabel =
                          _currentIndex >= 0 &&
                          _currentIndex < _pageNameLabels.length;
                      if (!showLabel) return const SizedBox.shrink();
                      final label = _pageNameLabels[_currentIndex];
                      final scheme = Theme.of(context).colorScheme;

                      return Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6.0,
                            horizontal: 16.0,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLow.withValues(
                              alpha: 0.7,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: scheme.primary.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: scheme.primary,
                                  letterSpacing: -0.2,
                                ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // DEBUG: 그리드 오버레이 (프로토타입/개발 모드 전용, 출시 전 자동 제거됨)
            if (kDebugMode)
              Positioned.fill(
                child: IgnorePointer(
                  child: GridPaper(
                    color: Colors.blue.withValues(alpha: 0.15),
                    interval: 50,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _IconGridPage extends StatefulWidget {
  final String accountName;
  final int pageIndex;
  final int pageCount;
  final int currentPage;
  final PageController pageController;
  final ValueChanged<bool>? onEditModeChanged;
  final ValueChanged<int>? onRequestJumpToPage;
  final VoidCallback? onRequestResetMainPages;
  final VoidCallback? onRequestQuickJump;

  const _IconGridPage({
    super.key,
    required this.accountName,
    required this.pageIndex,
    required this.pageCount,
    required this.currentPage,
    required this.pageController,
    this.onEditModeChanged,
    this.onRequestJumpToPage,
    this.onRequestResetMainPages,
    this.onRequestQuickJump,
  });

  @override
  State<_IconGridPage> createState() => _IconGridPageState();
}

class _IconGridPageState extends State<_IconGridPage> {
  static const String _shortcutSettingsPage10Id = 'shortcut_settings_page10';
  static const String _voiceShortcutsIconId = 'voice_shortcuts';
  static const int _shortcutSettingsAllowedPageIndex = 1; // 2nd page (1-based)
  static const int _settingsReservedPageIndex = 5; // 6th page (1-based)
  bool _isEditMode = false;
  bool _hideEmptySlots = true;
  List<String> _iconOrder = [];

  // Public helpers for parent to control this page via GlobalKey
  bool get isEditMode => _isEditMode;
  void toggleEditModePublic() => _toggleEditMode();

  Future<void> reloadFromPrefsPublic() async {
    await _loadSettings();
    await _loadHideEmptySlots();
    await _loadSlots();
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadHideEmptySlots();
    _loadSlots();
  }

  Future<void> _loadHideEmptySlots() async {
    final hide = await UserPrefService.getHideEmptySlots(
      accountName: widget.accountName,
    );
    if (!mounted) return;
    setState(() => _hideEmptySlots = hide);
  }

  Future<void> _loadSettings() async {
    final prefs = await UserPrefService.getPageIconSettings(
      accountName: widget.accountName,
      pageIndex: widget.pageIndex,
    );
    if (!mounted) return;
    setState(() {
      _iconOrder = prefs.order;
    });
  }

  Future<void> _saveSettings() async {
    await UserPrefService.setPageIconSettings(
      accountName: widget.accountName,
      pageIndex: widget.pageIndex,
      order: _iconOrder,
    );
  }

  void _toggleEditMode() {
    setState(() => _isEditMode = !_isEditMode);
    widget.onEditModeChanged?.call(_isEditMode);
    if (!_isEditMode) {
      _saveSettings();
      _saveSlotsDebounced();
    }
  }

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
    if (targetPages.length <= 1) return icons;

    final indexInGroup = targetPages.indexOf(pageIndex);
    if (indexInGroup == -1) return icons;

    final chunkSize = (icons.length / targetPages.length).ceil();
    if (chunkSize <= 0) return const <MainFeatureIcon>[];

    final start = indexInGroup * chunkSize;
    if (start >= icons.length) return const <MainFeatureIcon>[];
    final end = (start + chunkSize) > icons.length
        ? icons.length
        : (start + chunkSize);
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

  // --- Slot-based grid API ---
  static const int _defaultSlotCount = 24; // 4x6 (24 slots)

  // Reserved page policy (0-based indices):
  // 3: stats (page 4), 4: asset (page 5),
  // 5: root (page 6), 6: settings (page 7)
  static const Set<int> _statsReservedPages = <int>{3};
  static const Set<int> _assetReservedPages = <int>{4};
  static const Set<int> _rootReservedPages = <int>{5};
  static const Set<int> _settingsOnlyPages = <int>{6};

  late final Set<String> _allKnownIconIds = MainFeatureIconCatalog.pages
      .expand((p) => p.items)
      .map((e) => e.id)
      .toSet();

  late final Set<String> _incomeIconIds =
      MainFeatureIconCatalog.iconsForModuleKey(
        'income',
      ).map((e) => e.id).toSet();

  late final Set<String> _statsIconIds =
      MainFeatureIconCatalog.iconsForModuleKey(
        'stats',
      ).map((e) => e.id).toSet();

  late final Set<String> _assetIconIds =
      MainFeatureIconCatalog.iconsForModuleKey(
        'asset',
      ).map((e) => e.id).toSet();

  late final Set<String> _rootIconIds =
      MainFeatureIconCatalog.iconsForModuleKey('root').map((e) => e.id).toSet();

  late final Set<String> _settingsIconIds =
      MainFeatureIconCatalog.iconsForModuleKey(
        'settings',
      ).map((e) => e.id).toSet();

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

    // Navigation shortcut: only placeable on 2nd page.
    if (iconId == _shortcutSettingsPage10Id) {
      return pageIndex == _shortcutSettingsAllowedPageIndex;
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

    // Asset fixed policy: asset icons must live on asset pages (6~7).
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

  List<String> _slots = List<String>.filled(_defaultSlotCount, '');
  bool _isSavingSlots = false;

  Future<void> _loadSlots() async {
    final prefs = await SharedPreferences.getInstance();
    final assetLockEnabled =
        prefs.getBool(PrefKeys.biometricAuthEnabled) ?? false;
    final allowAssetOutsideWhenUnlocked =
        prefs.getBool(PrefKeys.iconAllowAssetIconsOutsideAssetWhenUnlocked) ??
        false;
    final untilMs = prefs.getInt(PrefKeys.assetAuthSessionUntilMs);
    final assetSessionUnlocked =
        untilMs != null && DateTime.now().millisecondsSinceEpoch < untilMs;

    final slots = await UserPrefService.getPageIconSlots(
      accountName: widget.accountName,
      pageIndex: widget.pageIndex,
    );
    final validated = slots.map((s) {
      final id = s.trim();
      if (id.isEmpty) return '';
      if (!_allKnownIconIds.contains(id)) return '';
      final allowed = _isAllowedOnPage(
        pageIndex: widget.pageIndex,
        iconId: id,
        assetLockEnabled: assetLockEnabled,
        allowAssetOutsideWhenUnlocked: allowAssetOutsideWhenUnlocked,
        assetSessionUnlocked: assetSessionUnlocked,
      );
      return allowed ? id : '';
    }).toList();

    // If slots are empty (or became empty after applying page policy), prefill
    // from available icons (visible + allowed set).
    final allEmptyStored = slots.every((s) => s.isEmpty);
    final allEmptyAfterValidation = validated.every((s) => s.isEmpty);
    final isReservedPage =
        _isStatsReservedPage(widget.pageIndex) ||
        _isAssetReservedPage(widget.pageIndex) ||
        _isRootReservedPage(widget.pageIndex) ||
        _isSettingsOnlyPage(widget.pageIndex);

    if (allEmptyStored || (isReservedPage && allEmptyAfterValidation)) {
      final visibleAndAllowedIcons = _getOrderedIcons()
          .where(
            (i) => _isAllowedOnPage(
              pageIndex: widget.pageIndex,
              iconId: i.id,
              assetLockEnabled: assetLockEnabled,
              allowAssetOutsideWhenUnlocked: allowAssetOutsideWhenUnlocked,
              assetSessionUnlocked: assetSessionUnlocked,
            ),
          )
          .toList();

      var writeIndex = 0;
      for (final icon in visibleAndAllowedIcons) {
        if (writeIndex >= _defaultSlotCount) break;
        validated[writeIndex] = icon.id;
        writeIndex++;
      }

      await UserPrefService.setPageIconSlots(
        accountName: widget.accountName,
        pageIndex: widget.pageIndex,
        slots: validated,
      );
    }

    // Page 1 convenience: if the screen saver shortcut is missing, try to
    // place it next to '오늘 지출' without overwriting any existing slot.
    if (widget.pageIndex == ScreenSaverIds.shortcutAllowedMainPageIndex) {
      final hasShortcut = validated.contains(ScreenSaverIds.shortcutIconId);
      if (!hasShortcut) {
        const preferredIndex = 1;
        final preferredEmpty =
            preferredIndex < validated.length &&
            validated[preferredIndex].isEmpty;
        if (preferredEmpty) {
          validated[preferredIndex] = ScreenSaverIds.shortcutIconId;
          await UserPrefService.setPageIconSlots(
            accountName: widget.accountName,
            pageIndex: widget.pageIndex,
            slots: validated,
          );
        } else {
          final emptyIndex = validated.indexOf('');
          if (emptyIndex != -1) {
            validated[emptyIndex] = ScreenSaverIds.shortcutIconId;
            await UserPrefService.setPageIconSlots(
              accountName: widget.accountName,
              pageIndex: widget.pageIndex,
              slots: validated,
            );
          }
        }
      }
    }

    // Page 0: ensure "음성 단축어" is visible early.
    // Do not overwrite existing slots; only fill an empty slot if possible.
    if (widget.pageIndex == 0) {
      final hasVoiceShortcuts = validated.contains(_voiceShortcutsIconId);
      if (!hasVoiceShortcuts) {
        const preferredIndex = 0;
        final preferredEmpty =
            preferredIndex < validated.length && validated[preferredIndex].isEmpty;
        if (preferredEmpty) {
          validated[preferredIndex] = _voiceShortcutsIconId;
          await UserPrefService.setPageIconSlots(
            accountName: widget.accountName,
            pageIndex: widget.pageIndex,
            slots: validated,
          );
        } else {
          final emptyIndex = validated.indexOf('');
          if (emptyIndex != -1) {
            validated[emptyIndex] = _voiceShortcutsIconId;
            await UserPrefService.setPageIconSlots(
              accountName: widget.accountName,
              pageIndex: widget.pageIndex,
              slots: validated,
            );
          }
        }
      }
    }

    // NOTE: removed single-icon-for-page-0 behavior to allow full slot
    // editing and consistent test expectations (page 1 can hold multiple
    // icons). Previously this forced only the first filled slot to remain
    // visible which broke drag & swap semantics in tests.

    if (!mounted) return;
    setState(() {
      _slots = validated;
    });
  }

  Future<void> _saveSlotsDebounced() async {
    if (_isSavingSlots) return; // simple guard
    _isSavingSlots = true;
    try {
      await UserPrefService.setPageIconSlots(
        accountName: widget.accountName,
        pageIndex: widget.pageIndex,
        slots: _slots,
      );
    } finally {
      _isSavingSlots = false;
    }
  }

  void _assignOrSwap(String draggedId, int targetIndex) {
    setState(() {
      final currentIndex = _slots.indexOf(draggedId);
      if (currentIndex == -1) {
        // dragged from palette, assign into slot
        _slots[targetIndex] = draggedId;
      } else {
        // dragged from another slot -> swap
        final temp = _slots[targetIndex];
        _slots[targetIndex] = draggedId;
        _slots[currentIndex] = temp;
      }
    });
    _saveSlotsDebounced();
  }

  MainFeatureIcon? _iconById(String id) {
    for (final page in MainFeatureIconCatalog.pages) {
      for (final icon in page.items) {
        if (icon.id == id) return icon;
      }
    }
    return null;
  }

  void _navigateToIcon(MainFeatureIcon icon) {
    if (icon.id == ScreenSaverIds.shortcutIconId) {
      ScreenSaverLauncher.show(
        context: context,
        accountName: widget.accountName,
      );
      return;
    }
    if (icon.id == _shortcutSettingsPage10Id) {
      widget.onRequestJumpToPage?.call(_settingsReservedPageIndex);
      return;
    }
    if (icon.id == 'accountStatsMemoSearch') {
      MemoSearchUtils.openMemoOnlySearch(
        context,
        accountName: widget.accountName,
      );
      return;
    }
    if (icon.id == 'accountStatsMemoStats') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MemoStatsScreen(accountName: widget.accountName),
        ),
      );
      return;
    }
    if (icon.routeName == null) return;

    final request = IconLaunchUtils.buildRequest(
      routeName: icon.routeName!,
      accountName: widget.accountName,
    );
    if (request == null) return;

    // debug prints removed (reverting temporary diagnostics)

    Navigator.of(
      context,
    ).pushNamed(request.routeName, arguments: request.arguments);
  }


  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget buildGrid() {
      return LayoutBuilder(
        builder: (context, constraints) {
          const crossAxisCount = 4;
          const rows =
              (_defaultSlotCount + crossAxisCount - 1) ~/ crossAxisCount;
          const mainAxisSpacing = 12.0;
          const horizontalPadding = 16.0 * 2; // left + right
          const verticalPadding = 16.0 * 2; // top + bottom
          const totalVerticalSpacing = mainAxisSpacing * (rows - 1);
          final usableWidth =
              constraints.maxWidth -
              horizontalPadding -
              (12.0 * (crossAxisCount - 1));
          final itemWidth = usableWidth / crossAxisCount;
          const childAspectRatio = 0.75; // width / height
          final itemHeight = itemWidth / childAspectRatio;
          final gridHeight =
              (rows * itemHeight) + totalVerticalSpacing + verticalPadding;

          return Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: gridHeight,
              width: double.infinity,
              child: GridView.count(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
                children: List.generate(_defaultSlotCount, (index) {
                  final slotKey = ValueKey<String>(
                    'main_icon_slot_${widget.pageIndex}_$index',
                  );
                  final id = _slots[index];
                  final isEmpty = id.isEmpty;
                  final icon = isEmpty ? null : _iconById(id);

                  if (!_isEditMode && _hideEmptySlots && isEmpty) {
                    return SizedBox.expand(key: slotKey);
                  }

                  final tile = icon != null
                      ? _IconTile(
                          label: icon.labelFor(context),
                          icon: icon.icon,
                          isEditMode: _isEditMode,
                          pageIndex: widget.pageIndex,
                          itemIndex: index,
                          liveDataWidget: null,
                          onTap: InteractionBlockers.gate(() {
                            if (_isEditMode) return;
                            _navigateToIcon(icon);
                          }),
                        )
                      : _EmptySlotTile(isEditMode: _isEditMode);

                  if (!_isEditMode) {
                    return SizedBox(key: slotKey, child: tile);
                  }

                  return SizedBox(
                    key: slotKey,
                    child: LongPressDraggable<String>(
                      data: id,
                      feedback: Opacity(
                        opacity: 0.9,
                        child: SizedBox(width: 80, child: tile),
                      ),
                      childWhenDragging: Opacity(
                        opacity: id.isEmpty ? 1.0 : 0.3,
                        child: tile,
                      ),
                      child: DragTarget<String>(
                        onWillAcceptWithDetails: (details) => true,
                        onAcceptWithDetails: (details) {
                          final draggedId = details.data;
                          if (draggedId.isEmpty) return;
                          _assignOrSwap(draggedId, index);
                        },
                        builder: (context, candidateData, rejectedData) {
                          final highlight = candidateData.isNotEmpty;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            transform: Matrix4.diagonal3Values(
                              highlight ? 1.03 : 1.0,
                              highlight ? 1.03 : 1.0,
                              1.0,
                            ),
                            child: tile,
                          );
                        },
                      ),
                    ),
                  );
                }),
              ),
            ),
          );
        },
      );
    }

    return Container(
      color: scheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 70),
          child: Column(
            children: [
              Expanded(child: buildGrid()),
              // 페이지 1(대시보드)에서만 긴급 버튼 표시
              if (widget.pageIndex == 0) const EmergencyButton(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        PageIndicator(
                          pageCount: widget.pageCount,
                          currentPage: widget.currentPage,
                          onPageTap: (index) {
                            widget.pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                        ),
                        _PageQuickMenuButton(
                          isEditMode: _isEditMode,
                          onToggleEditMode: _toggleEditMode,
                          onResetMainPages: widget.onRequestResetMainPages,
                          onPageSelected: (pageIndex) {
                            if (pageIndex < 0 ||
                                pageIndex >= widget.pageCount) {
                              return;
                            }
                            widget.pageController.animateToPage(
                              pageIndex,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageQuickMenuButton extends StatelessWidget {
  final bool isEditMode;
  final VoidCallback onToggleEditMode;
  final VoidCallback? onResetMainPages;
  final ValueChanged<int>? onPageSelected; // Callback with page index

  const _PageQuickMenuButton({
    required this.isEditMode,
    required this.onToggleEditMode,
    this.onResetMainPages,
    this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<_QuickMenuAction>(
      tooltip: '메뉴',
      icon: Icon(
        isEditMode ? Icons.check : Icons.more_vert,
        color: theme.colorScheme.onSurface,
      ),
      onSelected: (action) {
        switch (action) {
          case _QuickMenuAction.toggleEdit:
            onToggleEditMode();
            break;
          case _QuickMenuAction.jumpPage1:
            onPageSelected?.call(0);
            break;
          case _QuickMenuAction.jumpPage2:
            onPageSelected?.call(1);
            break;
          case _QuickMenuAction.jumpPage3:
            onPageSelected?.call(2);
            break;
          case _QuickMenuAction.jumpPage4:
            onPageSelected?.call(3);
            break;
          case _QuickMenuAction.jumpPage5:
            onPageSelected?.call(4);
            break;
          case _QuickMenuAction.jumpPage6:
            onPageSelected?.call(5);
            break;
          case _QuickMenuAction.jumpPage7:
            onPageSelected?.call(6);
            break;
        }
      },
      itemBuilder: (context) {
        return <PopupMenuEntry<_QuickMenuAction>>[
          PopupMenuItem<_QuickMenuAction>(
            value: _QuickMenuAction.toggleEdit,
            child: Text(isEditMode ? '편집 종료' : '편집 모드'),
          ),
          if (onPageSelected != null) ...<PopupMenuEntry<_QuickMenuAction>>[
            const PopupMenuDivider(),
            const PopupMenuItem<_QuickMenuAction>(
              value: _QuickMenuAction.jumpPage1,
              child: Text('1. 대시보드'),
            ),
            const PopupMenuItem<_QuickMenuAction>(
              value: _QuickMenuAction.jumpPage2,
              child: Text('2. 거래'),
            ),
            const PopupMenuItem<_QuickMenuAction>(
              value: _QuickMenuAction.jumpPage3,
              child: Text('3. 수입'),
            ),
            const PopupMenuItem<_QuickMenuAction>(
              value: _QuickMenuAction.jumpPage4,
              child: Text('4. 통계'),
            ),
            const PopupMenuItem<_QuickMenuAction>(
              value: _QuickMenuAction.jumpPage5,
              child: Text('5. 자산'),
            ),
            const PopupMenuItem<_QuickMenuAction>(
              value: _QuickMenuAction.jumpPage6,
              child: Text('6. ROOT'),
            ),
            const PopupMenuItem<_QuickMenuAction>(
              value: _QuickMenuAction.jumpPage7,
              child: Text('7. 설정'),
            ),
          ],
        ];
      },
    );
  }
}

enum _QuickMenuAction {
  toggleEdit,
  jumpPage1,
  jumpPage2,
  jumpPage3,
  jumpPage4,
  jumpPage5,
  jumpPage6,
  jumpPage7,
}

class _EmptySlotTile extends StatelessWidget {
  final bool isEditMode;
  const _EmptySlotTile({required this.isEditMode});

  @override
  Widget build(BuildContext context) {
    // If pages are blocked, don't show the empty-slot UI.
    if (MainFeatureIconCatalog.pageCount == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isEditMode
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Icon(
                IconCatalog.add,
                color: isEditMode
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isEditMode ? '추가' : '',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isEditMode;
  final int pageIndex;
  final int itemIndex;
  final Widget? liveDataWidget;
  final VoidCallback? onTap;

  const _IconTile({
    required this.label,
    required this.icon,
    required this.isEditMode,
    required this.pageIndex,
    required this.itemIndex,
    required this.liveDataWidget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final live = liveDataWidget;

    // Get page-based icon color
    final featureColor = AppColors.getFeatureIconColor(pageIndex, itemIndex);

    // Use theme color for background, feature color for icon
    final bgColor = !isEditMode
        ? scheme.primary.withValues(alpha: 0.12)
        : scheme.primaryContainer;
    final iconColor = !isEditMode ? featureColor : scheme.onPrimaryContainer;
    final labelStyle = theme.textTheme.labelMedium;
    final labelColor = !isEditMode
        ? (labelStyle?.color ?? scheme.onSurface)
        : scheme.onPrimaryContainer;

    return AnimatedRotation(
      turns: isEditMode ? -0.01 : 0,
      duration: const Duration(milliseconds: 140),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // Subtle glow for the icon
                  if (!isEditMode)
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: featureColor.withValues(alpha: 0.2),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(18),
                      border: isEditMode
                          ? Border.all(color: scheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style:
                    labelStyle?.copyWith(
                      color: labelColor,
                      fontWeight: isEditMode
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 11,
                      letterSpacing: -0.4,
                    ) ??
                    TextStyle(
                      color: labelColor,
                      fontWeight: isEditMode
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 11,
                      letterSpacing: -0.4,
                    ),
              ),
              if (!isEditMode && live != null) ...[
                const SizedBox(height: 4),
                live,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
