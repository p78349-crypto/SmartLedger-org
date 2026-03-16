import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'memo_stats_screen.dart';
import '../navigation/app_routes.dart';
import '../services/account_service.dart';
import '../services/home_server_sync_service.dart';
import '../services/user_pref_service.dart';
import '../theme/app_colors.dart';
import '../utils/icon_catalog.dart';
import '../utils/icon_launch_utils.dart';
import '../utils/interaction_blockers.dart';
import '../utils/main_feature_icon_catalog.dart';
import '../utils/memo_search_utils.dart';
import '../utils/page_indicator.dart';
import '../utils/pref_keys.dart';
import '../widgets/background_widget.dart';
import '../widgets/root_auth_gate.dart';
import '../widgets/special_backgrounds.dart';
import '../theme/app_theme_seed_controller.dart';

part 'account_main_build.dart';
part 'account_main_helpers.dart';
part 'account_main_widgets.dart';
part 'icon_grid_page_icons.dart';
part 'icon_grid_page_slots.dart';
part 'icon_grid_page_build.dart';

// ---------------------------------------------------------------------------
// Top-level statics (moved from nested classes for extension compatibility)
// ---------------------------------------------------------------------------

int get _pageCount => MainFeatureIconCatalog.pageCount;

const List<String> _pageNameLabels = <String>[
  '대시보드',
  '요리/쇼핑/지출',
  '수입',
  '통계',
  '자산',
  'ROOT',
  '설정',
  '미사용',
];

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

const String _voiceShortcutsIconId = 'voice_shortcuts';
const int _defaultSlotCount = 24;
const Set<int> _statsReservedPages = <int>{};
const Set<int> _assetReservedPages = <int>{};
const Set<int> _rootReservedPages = <int>{};
const Set<int> _settingsOnlyPages = <int>{};

// ---------------------------------------------------------------------------
// AccountMainScreen
// ---------------------------------------------------------------------------

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
  late final PageController _controller;
  int _currentIndex = 0;
  bool _isRestoringIndex = false;
  bool _disablePageSwipe = false;
  late final List<GlobalKey<_IconGridPageState>> _pageKeys;

  @override
  void initState() {
    super.initState();
    MainFeatureIconCatalog.setPagesBlocked(false);
    WidgetsBinding.instance.addObserver(this);
    _currentIndex = _pageCount > 0
        ? widget.initialIndex.clamp(0, _pageCount - 1)
        : 0;
    _controller = PageController(initialPage: _currentIndex);
    _pageKeys = List.generate(
      _pageCount,
      (_) => GlobalKey<_IconGridPageState>(),
    );
    _restoreSavedIndexIfNeeded();
    unawaited(_runStartupSync());
  }

  Future<void> _runStartupSync() async {
    if (widget.accountName == 'ROOT') {
      return;
    }
    try {
      await HomeServerSyncService().syncAllForAccount(widget.accountName);
    } catch (_) {
      // Best-effort startup sync; ignore to keep UX smooth.
    }
  }

  @override
  Widget build(BuildContext context) => _buildMain(context);
}

// ---------------------------------------------------------------------------
// _IconGridPage
// ---------------------------------------------------------------------------

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
  bool _isEditMode = false;
  bool _hideEmptySlots = true;
  List<String> _iconOrder = [];
  List<String> _slots = List<String>.filled(_defaultSlotCount, '');
  bool _isSavingSlots = false;

  late final Set<String> _allKnownIconIds = MainFeatureIconCatalog.pages
      .expand((p) => p.items)
      .map((e) => e.id)
      .toSet();

  late final Set<String> _incomeIconIds =
      MainFeatureIconCatalog.iconsForModuleKey(
        'income',
      ).map((e) => e.id).toSet();

  // Public helpers for parent to control this page via GlobalKey
  bool get isEditMode => _isEditMode;
  void toggleEditModePublic() => _toggleEditMode();
  void assignOrSwapPublic(String draggedId, int targetIndex) =>
      _assignOrSwap(draggedId, targetIndex);

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
    // Page 0 (대시보드): 항상 빈 슬롯 숨기기
    if (widget.pageIndex == 0) {
      if (!mounted) return;
      setState(() => _hideEmptySlots = true);
      return;
    }

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

  String? _getBadgeText(String id) {
    if (_isEditMode) return null;

    // 사용자 요청 가이드 순서 (레시피 1, 장바구니 2, 지출입력 3, 일일지출 4)
    switch (id) {
      case 'nutrition_report':
        return '1'; // "레시피/식재료 검색"
      case 'shopping_cart':
        return '2'; // "장바구니"
      case 'transactionAdd':
        return '3'; // "지출입력/거래 입력"
      case 'daily_transactions':
        return '4'; // "일일지출/오늘의 지출"
      case 'emergency_services':
        return '!';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) => _buildGridPage(context);
}
