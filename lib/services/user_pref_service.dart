import 'dart:convert';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/category_hint.dart';
import '../models/main_page_config.dart';
import '../models/shopping_cart_history_entry.dart';
import '../models/shopping_cart_item.dart';
import '../models/shopping_points_draft_entry.dart';
import '../models/shopping_template_item.dart';
import '../models/transaction.dart';
import '../models/wms_inventory_draft_entry.dart';
import 'account_service.dart';
import 'transaction_service.dart';
import '../utils/page1_bottom_quick_icons.dart';
import '../utils/pref_keys.dart';

part 'user_pref_service.core.dart';
part 'user_pref_service.theme.dart';
part 'user_pref_service.drafts.dart';
part 'user_pref_service.main_page.dart';
part 'user_pref_service.main_page_mgmt.dart';
part 'user_pref_service.shopping.dart';
part 'user_pref_service.shopping_hints.dart';
part 'user_pref_service.icons.dart';
part 'user_pref_service.policy.dart';

/// Central user-preference service.
///
/// All public methods are thin forwarding stubs that delegate to
/// library-private top-level implementations in the `part` files.
class UserPrefService {
  static const String lastAccountKey = 'lastAccountName';
  static const List<String> defaultCountLikeUnitsV1 = _kDefaultCountLikeUnitsV1;

  // ── Core: count-like units & stock depletion ──
  static Future<List<String>> getCountLikeUnitsV1() => _getCountLikeUnitsV1();
  static Future<void> setCountLikeUnitsV1(List<String> u) =>
      _setCountLikeUnitsV1(u);
  static Future<int> getStockUseAutoAddDepletionDaysFoodV1() =>
      _getStockUseAutoAddDepletionDaysFoodV1();
  static Future<int> getStockUseAutoAddDepletionDaysHouseholdV1() =>
      _getStockUseAutoAddDepletionDaysHouseholdV1();
  static Future<void> setStockUseAutoAddDepletionDaysFoodV1(int d) =>
      _setStockUseAutoAddDepletionDaysFoodV1(d);
  static Future<void> setStockUseAutoAddDepletionDaysHouseholdV1(int d) =>
      _setStockUseAutoAddDepletionDaysHouseholdV1(d);

  // ── Language & feature flags ──
  static Future<String> getLanguageCode() => _getLanguageCode();
  static Future<bool> getPage1FullScreenAdEnabled() =>
      _getPage1FullScreenAdEnabled();
  static Future<void> setPage1FullScreenAdEnabled({required bool enabled}) =>
      _setPage1FullScreenAdEnabled(enabled: enabled);
  static Future<bool> getIsOfficialUser() => _getIsOfficialUser();
  static Future<void> setIsOfficialUser({required bool isOfficial}) =>
      _setIsOfficialUser(isOfficial: isOfficial);
  static Future<bool> getZeroQuickButtonsEnabled() =>
      _getZeroQuickButtonsEnabled();
  static Future<void> setZeroQuickButtonsEnabled({required bool enabled}) =>
      _setZeroQuickButtonsEnabled(enabled: enabled);

  // ── Account name ──
  static Future<void> setLastAccountName(String n) => _setLastAccountName(n);
  static Future<String?> getLastAccountName() => _getLastAccountName();
  static Future<void> clearLastAccountName() => _clearLastAccountName();

  // ── Theme ──
  static Future<String?> getThemePresetId() => _getThemePresetId();
  static Future<void> setThemePresetId({required String presetId}) =>
      _setThemePresetId(presetId: presetId);
  static Future<String?> getThemeIconBgPresetId() => _getThemeIconBgPresetId();
  static Future<void> setThemeIconBgPresetId({required String presetId}) =>
      _setThemeIconBgPresetId(presetId: presetId);
  static Future<String?> getThemeWallpaperPresetId() =>
      _getThemeWallpaperPresetId();
  static Future<void> setThemeWallpaperPresetId({required String presetId}) =>
      _setThemeWallpaperPresetId(presetId: presetId);
  static Future<String?> getThemeLocalWallpaperPath() =>
      _getThemeLocalWallpaperPath();
  static Future<void> setThemeLocalWallpaperPath({required String? path}) =>
      _setThemeLocalWallpaperPath(path: path);
  static Future<Map<String, Map<String, dynamic>>> getThemePresets() =>
      _getThemePresets();
  static Future<void> setThemePreset({
    required String id,
    required Map<String, dynamic> data,
  }) => _setThemePreset(id: id, data: data);
  static Future<void> removeThemePreset({required String id}) =>
      _removeThemePreset(id: id);

  // ── Drafts: shopping points ──
  static Future<List<ShoppingPointsDraftEntry>> getShoppingPointsDrafts({
    required String accountName,
  }) => _getShoppingPointsDrafts(accountName: accountName);
  static Future<void> setShoppingPointsDrafts({
    required String accountName,
    required List<ShoppingPointsDraftEntry> drafts,
  }) => _setShoppingPointsDrafts(accountName: accountName, drafts: drafts);
  static Future<void> addShoppingPointsDraft({
    required String accountName,
    required ShoppingPointsDraftEntry draft,
    int maxEntries = 60,
  }) => _addShoppingPointsDraft(
    accountName: accountName,
    draft: draft,
    maxEntries: maxEntries,
  );
  static Future<void> updateShoppingPointsDraft({
    required String accountName,
    required ShoppingPointsDraftEntry draft,
  }) => _updateShoppingPointsDraft(accountName: accountName, draft: draft);
  static Future<void> removeShoppingPointsDraft({
    required String accountName,
    required String id,
  }) => _removeShoppingPointsDraft(accountName: accountName, id: id);

  // ── Drafts: WMS inventory ──
  static Future<List<WmsInventoryDraftEntry>> getWmsInventoryDrafts({
    required String accountName,
  }) => _getWmsInventoryDrafts(accountName: accountName);
  static Future<void> setWmsInventoryDrafts({
    required String accountName,
    required List<WmsInventoryDraftEntry> drafts,
  }) => _setWmsInventoryDrafts(accountName: accountName, drafts: drafts);
  static Future<void> addWmsInventoryDraft({
    required String accountName,
    required WmsInventoryDraftEntry draft,
    int maxEntries = 30,
  }) => _addWmsInventoryDraft(
    accountName: accountName,
    draft: draft,
    maxEntries: maxEntries,
  );
  static Future<void> updateWmsInventoryDraft({
    required String accountName,
    required WmsInventoryDraftEntry draft,
  }) => _updateWmsInventoryDraft(accountName: accountName, draft: draft);
  static Future<void> removeWmsInventoryDraft({
    required String accountName,
    required String id,
  }) => _removeWmsInventoryDraft(accountName: accountName, id: id);
  static Future<void> clearAllWmsInventoryDrafts({
    required String accountName,
  }) => _clearAllWmsInventoryDrafts(accountName: accountName);

  // ── Main page configs ──
  static List<MainPageConfig> defaultMainPageConfigs() =>
      _defaultMainPageConfigs();
  static Future<void> setMainPageConfigs({
    required String accountName,
    required List<MainPageConfig> configs,
  }) => _setMainPageConfigs(accountName: accountName, configs: configs);
  static Future<bool> hasMainPageConfigs({required String accountName}) =>
      _hasMainPageConfigs(accountName: accountName);
  static Future<List<MainPageConfig>> getMainPageConfigs({
    required String accountName,
    int pageCount = 0,
  }) => _getMainPageConfigs(accountName: accountName, pageCount: pageCount);
  static Future<void> setMainPageIndex({
    required String accountName,
    required int index,
  }) => _setMainPageIndex(accountName: accountName, index: index);
  static Future<int?> getMainPageIndex({required String accountName}) =>
      _getMainPageIndex(accountName: accountName);
  static Future<void> setMainPageLastId({
    required String accountName,
    required String pageId,
  }) => _setMainPageLastId(accountName: accountName, pageId: pageId);
  static Future<String?> getMainPageLastId({required String accountName}) =>
      _getMainPageLastId(accountName: accountName);
  static Future<void> setMainPageNames({
    required String accountName,
    required List<String> names,
  }) => _setMainPageNames(accountName: accountName, names: names);
  static Future<List<String>?> getMainPageNames({
    required String accountName,
  }) => _getMainPageNames(accountName: accountName);
  static Future<void> setPageTypes({
    required String accountName,
    required List<String> types,
  }) => _setPageTypes(accountName: accountName, types: types);
  static Future<List<String>> getPageTypes({required String accountName}) =>
      _getPageTypes(accountName: accountName);

  // ── Main page management ──
  static Future<void> resetAccountMainPages({
    required String accountName,
    int pageCount = 0,
  }) => _resetAccountMainPages(accountName: accountName, pageCount: pageCount);
  static Future<List<Map<String, dynamic>>> exportMainPageUiPrefsSnapshot({
    required String accountName,
  }) => _exportMainPageUiPrefsSnapshot(accountName: accountName);
  static Future<void> importMainPageUiPrefsSnapshot({
    required String accountName,
    required List<dynamic> snapshot,
  }) => _importMainPageUiPrefsSnapshot(
    accountName: accountName,
    snapshot: snapshot,
  );
  static Future<void> clearAllAccountScopedPrefs({
    required String accountName,
  }) => _clearAllAccountScopedPrefs(accountName: accountName);

  // ── Shopping cart / history / templates / budget ──
  static Future<List<ShoppingCartItem>> getShoppingCartItems({
    required String accountName,
  }) => _getShoppingCartItems(accountName: accountName);
  static Future<void> setShoppingCartItems({
    required String accountName,
    required List<ShoppingCartItem> items,
  }) => _setShoppingCartItems(accountName: accountName, items: items);
  static Future<void> clearShoppingCartItems({required String accountName}) =>
      _clearShoppingCartItems(accountName: accountName);
  static Future<double?> getShoppingCartPlannedBudget({
    required String accountName,
  }) => _getShoppingCartPlannedBudget(accountName: accountName);
  static Future<void> setShoppingCartPlannedBudget({
    required String accountName,
    required double? budget,
  }) => _setShoppingCartPlannedBudget(accountName: accountName, budget: budget);
  static Future<List<ShoppingCartHistoryEntry>> getShoppingCartHistory({
    required String accountName,
    int limit = 200,
  }) => _getShoppingCartHistory(accountName: accountName, limit: limit);
  static Future<void> addShoppingCartHistoryEntry({
    required String accountName,
    required ShoppingCartHistoryEntry entry,
    int maxItems = 500,
  }) => _addShoppingCartHistoryEntry(
    accountName: accountName,
    entry: entry,
    maxItems: maxItems,
  );
  static Future<void> clearShoppingCartHistory({required String accountName}) =>
      _clearShoppingCartHistory(accountName: accountName);
  static Future<void> setShoppingCartHistory({
    required String accountName,
    required List<ShoppingCartHistoryEntry> entries,
    int maxItems = 500,
  }) => _setShoppingCartHistory(
    accountName: accountName,
    entries: entries,
    maxItems: maxItems,
  );
  static Future<List<ShoppingTemplateItem>> getShoppingGroceryTemplateItems({
    required String accountName,
    int limit = 200,
  }) =>
      _getShoppingGroceryTemplateItems(accountName: accountName, limit: limit);
  static Future<void> setShoppingGroceryTemplateItems({
    required String accountName,
    required List<ShoppingTemplateItem> items,
    int maxItems = 500,
  }) => _setShoppingGroceryTemplateItems(
    accountName: accountName,
    items: items,
    maxItems: maxItems,
  );
  static Future<void> clearShoppingGroceryTemplateItems({
    required String accountName,
  }) => _clearShoppingGroceryTemplateItems(accountName: accountName);
  static Future<List<String>> getRecentStores(String a) => _getRecentStores(a);
  static Future<void> saveRecentStore(String a, String s) =>
      _saveRecentStore(a, s);
  static Future<List<String>> getRecentPayments(String a) =>
      _getRecentPayments(a);
  static Future<void> saveRecentPayment(String a, String p) =>
      _saveRecentPayment(a, p);

  // ── Shopping category hints & quick expense ──
  static Future<Map<String, CategoryHint>> getShoppingCategoryHints({
    required String accountName,
  }) => _getShoppingCategoryHints(accountName: accountName);
  static Future<void> setShoppingCategoryHint({
    required String accountName,
    required String keyword,
    required CategoryHint hint,
    int maxItems = 500,
  }) => _setShoppingCategoryHint(
    accountName: accountName,
    keyword: keyword,
    hint: hint,
    maxItems: maxItems,
  );
  static Future<void> setShoppingCategoryHints({
    required String accountName,
    required Map<String, CategoryHint> hints,
    int maxItems = 500,
  }) => _setShoppingCategoryHints(
    accountName: accountName,
    hints: hints,
    maxItems: maxItems,
  );
  static Future<void> clearShoppingCategoryHints({
    required String accountName,
  }) => _clearShoppingCategoryHints(accountName: accountName);
  static Future<int> bootstrapShoppingCategoryHintsFromTransactions({
    required String accountName,
    int maxItems = 300,
    int maxScanTransactions = 2000,
    bool includeRefunds = false,
  }) => _bootstrapShoppingCategoryHintsFromTransactions(
    accountName: accountName,
    maxItems: maxItems,
    maxScanTransactions: maxScanTransactions,
    includeRefunds: includeRefunds,
  );
  static Future<CategoryHint?> getShoppingQuickExpenseLastCategory({
    required String accountName,
  }) => _getShoppingQuickExpenseLastCategory(accountName: accountName);
  static Future<void> setShoppingQuickExpenseLastCategory({
    required String accountName,
    required CategoryHint hint,
  }) => _setShoppingQuickExpenseLastCategory(
    accountName: accountName,
    hint: hint,
  );
  static Future<String?> getShoppingQuickExpenseStoreLastPayment({
    required String accountName,
    required String storeKey,
  }) => _getShoppingQuickExpenseStoreLastPayment(
    accountName: accountName,
    storeKey: storeKey,
  );
  static Future<void> setShoppingQuickExpenseStoreLastPayment({
    required String accountName,
    required String storeKey,
    required String payment,
  }) => _setShoppingQuickExpenseStoreLastPayment(
    accountName: accountName,
    storeKey: storeKey,
    payment: payment,
  );
  static Future<CategoryHint?> getShoppingQuickExpenseStoreLastCategory({
    required String accountName,
    required String storeKey,
  }) => _getShoppingQuickExpenseStoreLastCategory(
    accountName: accountName,
    storeKey: storeKey,
  );
  static Future<void> setShoppingQuickExpenseStoreLastCategory({
    required String accountName,
    required String storeKey,
    required CategoryHint hint,
  }) => _setShoppingQuickExpenseStoreLastCategory(
    accountName: accountName,
    storeKey: storeKey,
    hint: hint,
  );

  // ── Icons: pageId-based ──
  static Future<void> setPageIconSettingsById({
    required String accountName,
    required String pageId,
    int? legacyPageIndex,
    required List<String> order,
  }) => _setPageIconSettingsById(
    accountName: accountName,
    pageId: pageId,
    legacyPageIndex: legacyPageIndex,
    order: order,
  );
  static Future<({List<String> order})> getPageIconSettingsById({
    required String accountName,
    required String pageId,
    int? legacyPageIndex,
  }) => _getPageIconSettingsById(
    accountName: accountName,
    pageId: pageId,
    legacyPageIndex: legacyPageIndex,
  );
  static Future<void> setPageIconSlotsById({
    required String accountName,
    required String pageId,
    int? legacyPageIndex,
    required List<String> slots,
  }) => _setPageIconSlotsById(
    accountName: accountName,
    pageId: pageId,
    legacyPageIndex: legacyPageIndex,
    slots: slots,
  );
  static Future<List<String>> getPageIconSlotsById({
    required String accountName,
    required String pageId,
    int? legacyPageIndex,
    int slotCount = Page1BottomQuickIcons.slotCount,
  }) => _getPageIconSlotsById(
    accountName: accountName,
    pageId: pageId,
    legacyPageIndex: legacyPageIndex,
    slotCount: slotCount,
  );
  static Future<void> setPageSlotGroupsById({
    required String accountName,
    required String pageId,
    int? legacyPageIndex,
    required List<List<String>> groups,
  }) => _setPageSlotGroupsById(
    accountName: accountName,
    pageId: pageId,
    legacyPageIndex: legacyPageIndex,
    groups: groups,
  );
  static Future<List<List<String>>> getPageSlotGroupsById({
    required String accountName,
    required String pageId,
    int? legacyPageIndex,
    int slotCount = Page1BottomQuickIcons.slotCount,
  }) => _getPageSlotGroupsById(
    accountName: accountName,
    pageId: pageId,
    legacyPageIndex: legacyPageIndex,
    slotCount: slotCount,
  );

  // ── Icons: show/hide, labels ──
  static Future<void> setShowEditButton({
    required String accountName,
    required bool show,
  }) => _setShowEditButton(accountName: accountName, show: show);
  static Future<bool> getShowEditButton({required String accountName}) =>
      _getShowEditButton(accountName: accountName);
  static Future<void> setHideEmptySlots({
    required String accountName,
    required bool hide,
  }) => _setHideEmptySlots(accountName: accountName, hide: hide);
  static Future<bool> getHideEmptySlots({required String accountName}) =>
      _getHideEmptySlots(accountName: accountName);
  static Future<Map<String, String>> getIconLabelOverrides({
    required String accountName,
    String? profileKey,
  }) =>
      _getIconLabelOverrides(accountName: accountName, profileKey: profileKey);
  static Future<void> setIconLabelOverride({
    required String accountName,
    required String iconId,
    required String? label,
    String? profileKey,
  }) => _setIconLabelOverride(
    accountName: accountName,
    iconId: iconId,
    label: label,
    profileKey: profileKey,
  );

  // ── Icons: legacy index-based ──
  static Future<void> setPageIconSettings({
    required String accountName,
    required int pageIndex,
    required List<String> order,
    String? profileKey,
  }) => _setPageIconSettings(
    accountName: accountName,
    pageIndex: pageIndex,
    order: order,
    profileKey: profileKey,
  );
  static Future<({List<String> order})> getPageIconSettings({
    required String accountName,
    required int pageIndex,
    String? profileKey,
  }) => _getPageIconSettings(
    accountName: accountName,
    pageIndex: pageIndex,
    profileKey: profileKey,
  );
  static Future<void> setPageIconSlots({
    required String accountName,
    required int pageIndex,
    required List<String> slots,
    String? profileKey,
  }) => _setPageIconSlots(
    accountName: accountName,
    pageIndex: pageIndex,
    slots: slots,
    profileKey: profileKey,
  );
  static Future<List<String>> getPageIconSlots({
    required String accountName,
    required int pageIndex,
    int slotCount = Page1BottomQuickIcons.slotCount,
    String? profileKey,
  }) => _getPageIconSlots(
    accountName: accountName,
    pageIndex: pageIndex,
    slotCount: slotCount,
    profileKey: profileKey,
  );
  static Future<void> setPageSlotGroups({
    required String accountName,
    required int pageIndex,
    required List<List<String>> groups,
  }) => _setPageSlotGroups(
    accountName: accountName,
    pageIndex: pageIndex,
    groups: groups,
  );
  static Future<List<List<String>>> getPageSlotGroups({
    required String accountName,
    required int pageIndex,
    int slotCount = Page1BottomQuickIcons.slotCount,
  }) => _getPageSlotGroups(
    accountName: accountName,
    pageIndex: pageIndex,
    slotCount: slotCount,
  );

  // ── Policy reset & recipe search ──
  static Future<void> resetAllPolicies({bool clearAccountPages = true}) =>
      _resetAllPolicies(clearAccountPages: clearAccountPages);
  static Future<String> getLastRecipeSearchQuery() =>
      _getLastRecipeSearchQuery();
  static Future<void> setLastRecipeSearchQuery(String q) =>
      _setLastRecipeSearchQuery(q);
  static Future<List<String>> getRecipeSearchHistory() =>
      _getRecipeSearchHistory();
  static Future<void> addToRecipeSearchHistory(String q) =>
      _addToRecipeSearchHistory(q);
  static Future<void> clearRecipeSearchHistory() => _clearRecipeSearchHistory();
}
