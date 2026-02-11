import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/main_page_config.dart';
import '../navigation/app_routes.dart';
import '../services/user_pref_service.dart';
import '../utils/main_feature_icon_catalog.dart';
import '../utils/page1_bottom_quick_icons.dart';
import '../utils/pref_keys.dart';
import '../utils/screen_saver_ids.dart';

part 'icon_management_screen_helpers.dart';
part 'icon_management_screen_load.dart';
part 'icon_management_screen_placed.dart';
part 'icon_management_screen_dropzone.dart';
part 'icon_management_screen_catalog.dart';
part 'icon_management_screen_build.dart';

// ---------------------------------------------------------------------------
// Top-level constants (moved from static for extension compatibility)
// ---------------------------------------------------------------------------

const int _slotCount = Page1BottomQuickIcons.slotCount;
final int _pageCount = MainFeatureIconCatalog.pageCount;

const Set<int> _statsReservedPages = <int>{3};
const Set<int> _assetReservedPages = <int>{4};
const Set<int> _rootReservedPages = <int>{5};
const Set<int> _settingsOnlyPages = <int>{6};

const String _shortcutSettingsPage10Id = 'shortcut_settings_page10';
const int _shortcutSettingsAllowedPageIndex = 1;

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
  /// When false, the app bar status line omits the "N\ud398\uc774\uc9c0" part.
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
  /// page section headers like "1\ud398\uc774\uc9c0" are not shown.
  final bool flattenCatalog;

  /// Whether to group the icon catalog by feature modules (e.g., \uc790\uc0b0/\ud1b5\uacc4).
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

class _IconManagementScreenState extends State<IconManagementScreen> {
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
  int _assetPageIndex = 4;
  int _rootPageIndex = 5;

  late final Set<String> _incomeIconIds;
  late final Set<String> _assetIconIds;
  late final Set<String> _rootIconIds;
  late final Set<String> _statsIconIds;
  late final Set<String> _settingsIconIds;

  bool _redirectingToDedicated = false;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  @override
  Widget build(BuildContext context) => _buildMain(context);
}
