import 'dart:convert';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/models/category_hint.dart';
import 'package:smart_ledger/models/main_page_config.dart';
import 'package:smart_ledger/models/shopping_cart_history_entry.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';
import 'package:smart_ledger/models/shopping_points_draft_entry.dart';
import 'package:smart_ledger/models/shopping_template_item.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/page1_bottom_quick_icons.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

class UserPrefService {
  static const String lastAccountKey = 'lastAccountName';

  // --- Shopping: post-shopping points drafts (for later input) ---
  static String _shoppingPointsDraftsKey(String accountName) {
    return PrefKeys.accountKey(accountName, 'shopping_points_drafts_v1');
  }

  static Future<List<ShoppingPointsDraftEntry>> getShoppingPointsDrafts({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shoppingPointsDraftsKey(accountName));
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map(
            (m) =>
                ShoppingPointsDraftEntry.fromJson(Map<String, dynamic>.from(m)),
          )
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static Future<void> setShoppingPointsDrafts({
    required String accountName,
    required List<ShoppingPointsDraftEntry> drafts,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(drafts.map((d) => d.toJson()).toList());
    await prefs.setString(_shoppingPointsDraftsKey(accountName), encoded);
  }

  static Future<void> addShoppingPointsDraft({
    required String accountName,
    required ShoppingPointsDraftEntry draft,
    int maxEntries = 60,
  }) async {
    final current = await getShoppingPointsDrafts(accountName: accountName);

    // Deduplicate by id.
    final next = <ShoppingPointsDraftEntry>[
      draft,
      for (final d in current)
        if (d.id != draft.id) d,
    ];

    final trimmed = next.length <= maxEntries
        ? next
        : next.take(maxEntries).toList();
    await setShoppingPointsDrafts(accountName: accountName, drafts: trimmed);
  }

  static Future<void> updateShoppingPointsDraft({
    required String accountName,
    required ShoppingPointsDraftEntry draft,
  }) async {
    final current = await getShoppingPointsDrafts(accountName: accountName);
    final next = current
        .map((d) => d.id == draft.id ? draft : d)
        .toList(growable: false);
    await setShoppingPointsDrafts(accountName: accountName, drafts: next);
  }

  static Future<void> removeShoppingPointsDraft({
    required String accountName,
    required String id,
  }) async {
    final current = await getShoppingPointsDrafts(accountName: accountName);
    final next = current.where((d) => d.id != id).toList(growable: false);
    await setShoppingPointsDrafts(accountName: accountName, drafts: next);
  }

  // --- Language ---
  // Default: Korean.
  static Future<String> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(PrefKeys.language);
    if (stored == null || stored == 'system') {
      return PlatformDispatcher.instance.locale.languageCode;
    }
    return stored;
  }

  static String _withProfile(String suffix, String? profileKey) {
    final p = profileKey?.trim();
    if (p == null || p.isEmpty) return suffix;
    return '${suffix}_$p';
  }

  // --- Global release/entitlement & feature flags ---
  // Default: OFF for safety (no ad until explicitly enabled).
  static Future<bool> getPage1FullScreenAdEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefKeys.page1FullScreenAdEnabled) ?? false;
  }

  static Future<void> setPage1FullScreenAdEnabled({
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.page1FullScreenAdEnabled, enabled);
  }

  // Default: NOT official.
  static Future<bool> getIsOfficialUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefKeys.isOfficialUser) ?? false;
  }

  static Future<void> setIsOfficialUser({required bool isOfficial}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.isOfficialUser, isOfficial);
  }

  // --- UI: numeric quick buttons (0/00/000) ---
  // Default: OFF (feature can be confusing / may affect layout).
  static Future<bool> getZeroQuickButtonsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PrefKeys.zeroQuickButtonsEnabled) ?? false;
  }

  static Future<void> setZeroQuickButtonsEnabled({
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefKeys.zeroQuickButtonsEnabled, enabled);
  }

  // --- Theme preset ---
  static Future<String?> getThemePresetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefKeys.themePresetId);
  }

  static Future<void> setThemePresetId({required String presetId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.themePresetId, presetId);
  }

  // Icon background preset id (separate)
  static Future<String?> getThemeIconBgPresetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefKeys.themeIconBgPresetId);
  }

  static Future<void> setThemeIconBgPresetId({required String presetId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.themeIconBgPresetId, presetId);
  }

  // Wallpaper preset id
  static Future<String?> getThemeWallpaperPresetId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefKeys.themeWallpaperPresetId);
  }

  static Future<void> setThemeWallpaperPresetId({
    required String presetId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.themeWallpaperPresetId, presetId);
  }

  // Local wallpaper path
  static Future<String?> getThemeLocalWallpaperPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefKeys.themeLocalWallpaperPath);
  }

  static Future<void> setThemeLocalWallpaperPath({
    required String? path,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(PrefKeys.themeLocalWallpaperPath);
    } else {
      await prefs.setString(PrefKeys.themeLocalWallpaperPath, path);
    }
  }

  // Custom theme presets storage (map of id -> json)
  static const _themePresetsKey = 'theme_presets_v1';

  static Future<Map<String, Map<String, dynamic>>> getThemePresets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_themePresetsKey);
    if (raw == null) return {};
    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return decoded.map(
        (k, v) => MapEntry(k, Map<String, dynamic>.from(v as Map)),
      );
    } catch (_) {
      return {};
    }
  }

  static Future<void> setThemePreset({
    required String id,
    required Map<String, dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getThemePresets();
    existing[id] = data;
    await prefs.setString(_themePresetsKey, jsonEncode(existing));
  }

  static Future<void> removeThemePreset({required String id}) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getThemePresets();
    existing.remove(id);
    await prefs.setString(_themePresetsKey, jsonEncode(existing));
  }

  // --- Main page config (index-independent) ---
  // Stored as JSON list for forward compatibility.
  static String _mainPageConfigsKey(String accountName) {
    return PrefKeys.accountKey(accountName, 'main_page_configs_v1');
  }

  static String _mainPageLastIdKey(String accountName) {
    return PrefKeys.accountKey(accountName, 'main_page_last_id');
  }

  static List<MainPageConfig> defaultMainPageConfigs() {
    // Provide a safe, repeatable default of 15 pages.
    // These defaults are conservative: `page1` uses an empty name
    // (legacy slot), others use simple labels.
    return const <MainPageConfig>[
      MainPageConfig(
        pageId: 'page1',
        moduleKey: 'page1',
        pageType: 'icons',
        name: '',
      ),
      MainPageConfig(
        pageId: 'page2',
        moduleKey: 'page2',
        pageType: 'icons',
        name: '구매',
      ),
      MainPageConfig(
        pageId: 'page3',
        moduleKey: 'page3',
        pageType: 'icons',
        name: '기능',
      ),
      MainPageConfig(
        pageId: 'page4',
        moduleKey: 'page4',
        pageType: 'icons',
        name: '통계',
      ),
      MainPageConfig(
        pageId: 'page5',
        moduleKey: 'page5',
        pageType: 'icons',
        name: '자산',
      ),
      MainPageConfig(
        pageId: 'page6',
        moduleKey: 'page6',
        pageType: 'icons',
        name: 'ROOT',
      ),
      MainPageConfig(
        pageId: 'page7',
        moduleKey: 'page7',
        pageType: 'icons',
        name: '페이지7',
      ),
      MainPageConfig(
        pageId: 'page8',
        moduleKey: 'page8',
        pageType: 'icons',
        name: '페이지8',
      ),
      MainPageConfig(
        pageId: 'page9',
        moduleKey: 'page9',
        pageType: 'icons',
        name: '페이지9',
      ),
      MainPageConfig(
        pageId: 'page10',
        moduleKey: 'page10',
        pageType: 'icons',
        name: '페이지10',
      ),
      MainPageConfig(
        pageId: 'page11',
        moduleKey: 'page11',
        pageType: 'icons',
        name: '페이지11',
      ),
      MainPageConfig(
        pageId: 'page12',
        moduleKey: 'page12',
        pageType: 'icons',
        name: '페이지12',
      ),
      MainPageConfig(
        pageId: 'page13',
        moduleKey: 'page13',
        pageType: 'icons',
        name: '페이지13',
      ),
      MainPageConfig(
        pageId: 'page14',
        moduleKey: 'page14',
        pageType: 'icons',
        name: '페이지14',
      ),
      MainPageConfig(
        pageId: 'page15',
        moduleKey: 'page15',
        pageType: 'icons',
        name: '페이지15',
      ),
    ];
  }

  static Future<void> setMainPageConfigs({
    required String accountName,
    required List<MainPageConfig> configs,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _mainPageConfigsKey(accountName),
      jsonEncode(configs.map((c) => c.toJson()).toList()),
    );

    // Keep legacy keys in sync for backward compatibility.
    await setMainPageNames(
      accountName: accountName,
      names: configs.map((c) => c.name).toList(),
    );
    await setPageTypes(
      accountName: accountName,
      types: configs.map((c) => c.pageType).toList(),
    );
  }

  static Future<bool> hasMainPageConfigs({required String accountName}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_mainPageConfigsKey(accountName));
  }

  static Future<List<MainPageConfig>> getMainPageConfigs({
    required String accountName,
    int pageCount = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_mainPageConfigsKey(accountName));
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final parsed = decoded
              .map(MainPageConfig.tryFromJson)
              .whereType<MainPageConfig>()
              .toList();
          if (parsed.isNotEmpty) {
            return _normalizeMainPageConfigs(parsed, pageCount);
          }
        }
      } catch (_) {
        // fall through to legacy
      }
    }

    // Legacy fallback: names/types were stored as separate string lists.
    final legacyNames = await getMainPageNames(accountName: accountName);
    final legacyTypes = await getPageTypes(accountName: accountName);
    final defaults = defaultMainPageConfigs();

    final names = _normalizeStringList(
      legacyNames ?? defaults.map((c) => c.name).toList(),
      defaults.map((c) => c.name).toList(),
      pageCount,
    );
    final types = _normalizeStringList(
      legacyTypes,
      defaults.map((c) => c.pageType).toList(),
      pageCount,
    );

    final out = <MainPageConfig>[];
    for (int i = 0; i < pageCount && i < defaults.length; i++) {
      final d = defaults[i];
      out.add(d.copyWith(name: names[i], pageType: types[i]));
    }
    return out;
  }

  static List<MainPageConfig> _normalizeMainPageConfigs(
    List<MainPageConfig> source,
    int pageCount,
  ) {
    final defaults = defaultMainPageConfigs();
    final out = List<MainPageConfig>.from(source);

    if (out.length < pageCount) {
      out.addAll(defaults.sublist(out.length, pageCount));
    } else if (out.length > pageCount) {
      out.removeRange(pageCount, out.length);
    }

    // Normalize reserved slots for safety
    // (without overriding user repurposing).
    for (int i = 0; i < out.length; i++) {
      final cfg = out[i];

      if (cfg.pageId == 'reserved_1' || cfg.pageId == 'reserved_2') {
        final normalizedName = cfg.pageId == 'reserved_1' ? '예약1' : '예약2';
        final shouldNormalizeModuleKey =
            cfg.moduleKey.isEmpty || cfg.moduleKey.startsWith('reserved');

        out[i] = cfg.copyWith(
          moduleKey: shouldNormalizeModuleKey ? 'reserved' : cfg.moduleKey,
          name: cfg.name.trim().isEmpty ? normalizedName : cfg.name,
        );
      }
    }

    return out;
  }

  static List<String> _normalizeStringList(
    List<String> source,
    List<String> defaults,
    int count,
  ) {
    final out = List<String>.from(source);
    if (out.length < count) {
      out.addAll(defaults.sublist(out.length, count));
    } else if (out.length > count) {
      out.removeRange(count, out.length);
    }
    return out;
  }

  static String _mainPageIndexKey(String accountName) {
    return PrefKeys.accountKey(accountName, PrefKeys.mainPageIndexSuffix);
  }

  static Future<void> setLastAccountName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(lastAccountKey, name);
  }

  static Future<String?> getLastAccountName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastAccountKey);
  }

  static Future<void> clearLastAccountName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(lastAccountKey);
  }

  // --- Shopping cart / pre-shopping list ---
  static String _shoppingCartItemsKey(String accountName) {
    return PrefKeys.accountKey(accountName, 'shopping_cart_items');
  }

  static String _shoppingCartHistoryKey(String accountName) {
    return PrefKeys.accountKey(accountName, 'shopping_cart_history_v1');
  }

  static String _shoppingCartPlannedBudgetKey(String accountName) {
    return PrefKeys.accountKey(accountName, 'shopping_cart_planned_budget_v1');
  }

  static String _shoppingGroceryTemplateKey(String accountName) {
    return PrefKeys.accountKey(accountName, 'shopping_grocery_template_v1');
  }

  static String _shoppingCategoryHintsKey(String accountName) {
    return PrefKeys.accountKey(accountName, 'shopping_category_hints_v1');
  }

  static String _shoppingQuickExpenseLastMainCategoryKey(String accountName) {
    return PrefKeys.accountKey(
      accountName,
      'shopping_quick_last_main_category_expense_v1',
    );
  }

  static String _shoppingQuickExpenseLastSubCategoryKey(String accountName) {
    return PrefKeys.accountKey(
      accountName,
      'shopping_quick_last_sub_category_expense_v1',
    );
  }

  static String _normalizeStoreKey(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    final collapsed = trimmed.replaceAll(RegExp(r'\s+'), ' ');
    final safe = collapsed.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣 _\-]'), '');
    final compact = safe.replaceAll(' ', '');
    if (compact.isEmpty) return '';
    return compact.length > 24 ? compact.substring(0, 24) : compact;
  }

  static String _shoppingQuickExpenseStoreLastPaymentKey(
    String accountName,
    String storeKey,
  ) {
    final k = _normalizeStoreKey(storeKey);
    return PrefKeys.accountKey(accountName, 'shopping_quick_${k}_pay_v1');
  }

  static String _shoppingQuickExpenseStoreLastMainCategoryKey(
    String accountName,
    String storeKey,
  ) {
    final k = _normalizeStoreKey(storeKey);
    return PrefKeys.accountKey(accountName, 'shopping_quick_${k}_main_v1');
  }

  static String _shoppingQuickExpenseStoreLastSubCategoryKey(
    String accountName,
    String storeKey,
  ) {
    final k = _normalizeStoreKey(storeKey);
    return PrefKeys.accountKey(accountName, 'shopping_quick_${k}_sub_v1');
  }

  static String _normalizeShoppingHintKey(String raw) {
    return raw.trim().toLowerCase().replaceAll(' ', '');
  }

  static Future<Map<String, CategoryHint>> getShoppingCategoryHints({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shoppingCategoryHintsKey(accountName));
    if (raw == null || raw.trim().isEmpty) return <String, CategoryHint>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, CategoryHint>{};
      final out = <String, CategoryHint>{};
      for (final entry in decoded.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || value is! Map) continue;
        out[key] = CategoryHint.fromJson(Map<String, dynamic>.from(value));
      }
      return out;
    } catch (_) {
      return <String, CategoryHint>{};
    }
  }

  static Future<CategoryHint?> getShoppingQuickExpenseLastCategory({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final main = prefs.getString(
      _shoppingQuickExpenseLastMainCategoryKey(accountName),
    );
    if (main == null || main.trim().isEmpty) return null;
    final sub = prefs.getString(
      _shoppingQuickExpenseLastSubCategoryKey(accountName),
    );
    return CategoryHint(mainCategory: main.trim(), subCategory: sub?.trim());
  }

  static Future<void> setShoppingQuickExpenseLastCategory({
    required String accountName,
    required CategoryHint hint,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final main = hint.mainCategory.trim();
    if (main.isEmpty) {
      await prefs.remove(_shoppingQuickExpenseLastMainCategoryKey(accountName));
      await prefs.remove(_shoppingQuickExpenseLastSubCategoryKey(accountName));
      return;
    }

    await prefs.setString(
      _shoppingQuickExpenseLastMainCategoryKey(accountName),
      main,
    );

    final sub = hint.subCategory?.trim() ?? '';
    if (sub.isEmpty) {
      await prefs.remove(_shoppingQuickExpenseLastSubCategoryKey(accountName));
    } else {
      await prefs.setString(
        _shoppingQuickExpenseLastSubCategoryKey(accountName),
        sub,
      );
    }
  }

  static Future<String?> getShoppingQuickExpenseStoreLastPayment({
    required String accountName,
    required String storeKey,
  }) async {
    final k = _normalizeStoreKey(storeKey);
    if (k.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      _shoppingQuickExpenseStoreLastPaymentKey(accountName, k),
    );
    final value = raw?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static Future<void> setShoppingQuickExpenseStoreLastPayment({
    required String accountName,
    required String storeKey,
    required String payment,
  }) async {
    final k = _normalizeStoreKey(storeKey);
    if (k.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final value = payment.trim();
    if (value.isEmpty) {
      await prefs.remove(
        _shoppingQuickExpenseStoreLastPaymentKey(accountName, k),
      );
      return;
    }
    await prefs.setString(
      _shoppingQuickExpenseStoreLastPaymentKey(accountName, k),
      value,
    );
  }

  static Future<CategoryHint?> getShoppingQuickExpenseStoreLastCategory({
    required String accountName,
    required String storeKey,
  }) async {
    final k = _normalizeStoreKey(storeKey);
    if (k.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final main = prefs.getString(
      _shoppingQuickExpenseStoreLastMainCategoryKey(accountName, k),
    );
    if (main == null || main.trim().isEmpty) return null;
    final sub = prefs.getString(
      _shoppingQuickExpenseStoreLastSubCategoryKey(accountName, k),
    );
    return CategoryHint(mainCategory: main.trim(), subCategory: sub?.trim());
  }

  static Future<void> setShoppingQuickExpenseStoreLastCategory({
    required String accountName,
    required String storeKey,
    required CategoryHint hint,
  }) async {
    final k = _normalizeStoreKey(storeKey);
    if (k.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final main = hint.mainCategory.trim();
    if (main.isEmpty) {
      await prefs.remove(
        _shoppingQuickExpenseStoreLastMainCategoryKey(accountName, k),
      );
      await prefs.remove(
        _shoppingQuickExpenseStoreLastSubCategoryKey(accountName, k),
      );
      return;
    }

    await prefs.setString(
      _shoppingQuickExpenseStoreLastMainCategoryKey(accountName, k),
      main,
    );

    final sub = hint.subCategory?.trim() ?? '';
    if (sub.isEmpty) {
      await prefs.remove(
        _shoppingQuickExpenseStoreLastSubCategoryKey(accountName, k),
      );
    } else {
      await prefs.setString(
        _shoppingQuickExpenseStoreLastSubCategoryKey(accountName, k),
        sub,
      );
    }
  }

  static Future<void> setShoppingCategoryHint({
    required String accountName,
    required String keyword,
    required CategoryHint hint,
    int maxItems = 500,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getShoppingCategoryHints(accountName: accountName);
    final next = Map<String, CategoryHint>.from(current);
    final normalizedKey = _normalizeShoppingHintKey(keyword);
    if (normalizedKey.isEmpty) return;

    next[normalizedKey] = hint;
    while (next.length > maxItems) {
      next.remove(next.keys.first);
    }

    final data = <String, dynamic>{
      for (final e in next.entries) e.key: e.value.toJson(),
    };
    await prefs.setString(
      _shoppingCategoryHintsKey(accountName),
      jsonEncode(data),
    );
  }

  static Future<void> setShoppingCategoryHints({
    required String accountName,
    required Map<String, CategoryHint> hints,
    int maxItems = 500,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final normalized = <String, CategoryHint>{};
    for (final entry in hints.entries) {
      if (normalized.length >= maxItems) break;
      final key = _normalizeShoppingHintKey(entry.key);
      if (key.isEmpty) continue;
      normalized[key] = entry.value;
    }

    if (normalized.isEmpty) {
      await prefs.remove(_shoppingCategoryHintsKey(accountName));
      return;
    }

    final data = <String, dynamic>{
      for (final e in normalized.entries) e.key: e.value.toJson(),
    };
    await prefs.setString(
      _shoppingCategoryHintsKey(accountName),
      jsonEncode(data),
    );
  }

  static Future<void> clearShoppingCategoryHints({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shoppingCategoryHintsKey(accountName));
  }

  /// Bootstraps learned shopping-category hints from existing transactions.
  ///
  /// Runs only when there are no existing hints.
  ///
  /// This helps improve auto-category success for many product names without
  /// requiring manual training upfront.
  static Future<int> bootstrapShoppingCategoryHintsFromTransactions({
    required String accountName,
    int maxItems = 300,
    int maxScanTransactions = 2000,
    bool includeRefunds = false,
  }) async {
    final existing = await getShoppingCategoryHints(accountName: accountName);
    if (existing.isNotEmpty) return 0;

    final service = TransactionService();
    await service.loadTransactions();
    final all = service.getTransactions(accountName);
    if (all.isEmpty) return 0;

    final candidates = all
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              t.description.trim().isNotEmpty &&
              t.mainCategory != Transaction.defaultMainCategory &&
              (includeRefunds ? true : !t.isRefund),
        )
        .toList(growable: false);
    if (candidates.isEmpty) return 0;

    candidates.sort((a, b) => b.date.compareTo(a.date));

    final next = <String, CategoryHint>{};
    final scanLimit = maxScanTransactions <= 0
        ? candidates.length
        : maxScanTransactions;
    for (final t in candidates.take(scanLimit)) {
      if (next.length >= maxItems) break;
      final key = _normalizeShoppingHintKey(t.description);
      if (key.isEmpty) continue;
      if (next.containsKey(key)) continue;
      next[key] = CategoryHint(
        mainCategory: t.mainCategory,
        subCategory: t.subCategory,
      );
    }

    if (next.isEmpty) return 0;
    await setShoppingCategoryHints(
      accountName: accountName,
      hints: next,
      maxItems: maxItems,
    );
    return next.length;
  }

  static Future<List<ShoppingCartItem>> getShoppingCartItems({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shoppingCartItemsKey(accountName));
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ShoppingCartItem.fromJson)
          .where((i) => i.id.trim().isNotEmpty && i.name.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> setShoppingCartItems({
    required String accountName,
    required List<ShoppingCartItem> items,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = items.map((i) => i.toJson()).toList(growable: false);
    await prefs.setString(_shoppingCartItemsKey(accountName), jsonEncode(data));
  }

  static Future<void> clearShoppingCartItems({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shoppingCartItemsKey(accountName));
  }

  static Future<double?> getShoppingCartPlannedBudget({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getDouble(_shoppingCartPlannedBudgetKey(accountName));
    return (value == null || value <= 0) ? null : value;
  }

  static Future<void> setShoppingCartPlannedBudget({
    required String accountName,
    required double? budget,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final next = (budget == null || budget <= 0) ? null : budget;
    if (next == null) {
      await prefs.remove(_shoppingCartPlannedBudgetKey(accountName));
      return;
    }
    await prefs.setDouble(_shoppingCartPlannedBudgetKey(accountName), next);
  }

  static Future<List<ShoppingCartHistoryEntry>> getShoppingCartHistory({
    required String accountName,
    int limit = 200,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shoppingCartHistoryKey(accountName));
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final entries = decoded
          .whereType<Map<String, dynamic>>()
          .map(ShoppingCartHistoryEntry.fromJson)
          .where(
            (e) =>
                e.id.trim().isNotEmpty &&
                e.itemId.trim().isNotEmpty &&
                e.name.trim().isNotEmpty,
          )
          .toList();
      entries.sort((a, b) => b.at.compareTo(a.at));
      return entries.take(limit).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static Future<void> addShoppingCartHistoryEntry({
    required String accountName,
    required ShoppingCartHistoryEntry entry,
    int maxItems = 500,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getShoppingCartHistory(
      accountName: accountName,
      limit: maxItems,
    );
    final next = [entry, ...current];
    final data = next.take(maxItems).map((e) => e.toJson()).toList();
    await prefs.setString(
      _shoppingCartHistoryKey(accountName),
      jsonEncode(data),
    );
  }

  static Future<void> clearShoppingCartHistory({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shoppingCartHistoryKey(accountName));
  }

  static Future<void> setShoppingCartHistory({
    required String accountName,
    required List<ShoppingCartHistoryEntry> entries,
    int maxItems = 500,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = entries.take(maxItems).toList(growable: false);
    final data = trimmed.map((e) => e.toJson()).toList(growable: false);
    await prefs.setString(
      _shoppingCartHistoryKey(accountName),
      jsonEncode(data),
    );
  }

  static Future<List<ShoppingTemplateItem>> getShoppingGroceryTemplateItems({
    required String accountName,
    int limit = 200,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shoppingGroceryTemplateKey(accountName));
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final items = decoded
          .whereType<Map<String, dynamic>>()
          .map(ShoppingTemplateItem.fromJson)
          .where((i) => i.name.trim().isNotEmpty)
          .toList();
      return items.take(limit).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static Future<void> setShoppingGroceryTemplateItems({
    required String accountName,
    required List<ShoppingTemplateItem> items,
    int maxItems = 500,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = items
        .where((i) => i.name.trim().isNotEmpty)
        .take(maxItems)
        .toList(growable: false);
    final data = trimmed.map((i) => i.toJson()).toList(growable: false);
    await prefs.setString(
      _shoppingGroceryTemplateKey(accountName),
      jsonEncode(data),
    );
  }

  static Future<void> clearShoppingGroceryTemplateItems({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_shoppingGroceryTemplateKey(accountName));
  }

  /// Removes all SharedPreferences keys that are scoped to [accountName].
  ///
  /// Account-scoped keys are consistently stored as `${accountName}_<suffix>`
  /// via [PrefKeys.accountKey]. This helper makes account deletion safe and
  /// future-proof by removing any present keys with that prefix.
  static Future<void> clearAllAccountScopedPrefs({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${accountName}_';
    final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  static bool _isMainPageUiPrefSuffix(String suffix) {
    if (suffix.startsWith('main_page_')) return true;
    if (suffix == PrefKeys.mainPageIndexSuffix) return true;
    if (suffix == 'page_types') return true;
    if (suffix == 'hide_empty_slots') return true;
    if (suffix == 'show_edit_button') return true;
    if (suffix == 'icon_label_overrides_v1') return true;
    if (suffix.startsWith('page_')) return true;
    if (suffix.startsWith('pageId_')) return true;
    return false;
  }

  static Future<List<Map<String, dynamic>>> exportMainPageUiPrefsSnapshot({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${accountName}_';

    final keys =
        prefs
            .getKeys()
            .where((k) => k.startsWith(prefix))
            .map((k) => k.substring(prefix.length))
            .where(_isMainPageUiPrefSuffix)
            .toList()
          ..sort();

    final out = <Map<String, dynamic>>[];
    for (final suffix in keys) {
      final key = PrefKeys.accountKey(accountName, suffix);
      if (!prefs.containsKey(key)) continue;

      final stringListValue = prefs.getStringList(key);
      if (stringListValue != null) {
        out.add({
          'suffix': suffix,
          'type': 'stringList',
          'value': stringListValue,
        });
        continue;
      }

      final stringValue = prefs.getString(key);
      if (stringValue != null) {
        out.add({'suffix': suffix, 'type': 'string', 'value': stringValue});
        continue;
      }

      final intValue = prefs.getInt(key);
      if (intValue != null) {
        out.add({'suffix': suffix, 'type': 'int', 'value': intValue});
        continue;
      }

      final doubleValue = prefs.getDouble(key);
      if (doubleValue != null) {
        out.add({'suffix': suffix, 'type': 'double', 'value': doubleValue});
        continue;
      }

      final boolValue = prefs.getBool(key);
      if (boolValue != null) {
        out.add({'suffix': suffix, 'type': 'bool', 'value': boolValue});
        continue;
      }
    }
    return out;
  }

  static Future<void> importMainPageUiPrefsSnapshot({
    required String accountName,
    required List<dynamic> snapshot,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '${accountName}_';

    final existingKeys = prefs
        .getKeys()
        .where((k) => k.startsWith(prefix))
        .map((k) => k.substring(prefix.length))
        .where(_isMainPageUiPrefSuffix)
        .toList();

    for (final suffix in existingKeys) {
      await prefs.remove(PrefKeys.accountKey(accountName, suffix));
    }

    for (final item in snapshot) {
      if (item is! Map) continue;
      final suffix = item['suffix'];
      final type = item['type'];
      final value = item['value'];
      if (suffix is! String || type is! String) continue;
      if (!_isMainPageUiPrefSuffix(suffix)) continue;

      final key = PrefKeys.accountKey(accountName, suffix);
      switch (type) {
        case 'stringList':
          if (value is List) {
            await prefs.setStringList(
              key,
              value.map((e) => e.toString()).toList(growable: false),
            );
          }
          break;
        case 'string':
          if (value is String) {
            await prefs.setString(key, value);
          }
          break;
        case 'int':
          if (value is num) {
            await prefs.setInt(key, value.toInt());
          }
          break;
        case 'double':
          if (value is num) {
            await prefs.setDouble(key, value.toDouble());
          }
          break;
        case 'bool':
          if (value is bool) {
            await prefs.setBool(key, value);
          }
          break;
      }
    }
  }

  static Future<void> setMainPageIndex({
    required String accountName,
    required int index,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mainPageIndexKey(accountName), index);
  }

  static Future<void> setMainPageLastId({
    required String accountName,
    required String pageId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mainPageLastIdKey(accountName), pageId);
  }

  static Future<String?> getMainPageLastId({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mainPageLastIdKey(accountName));
  }

  static Future<int?> getMainPageIndex({required String accountName}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_mainPageIndexKey(accountName));
  }

  static String _mainPageNamesKey(String accountName) {
    return PrefKeys.accountKey(accountName, 'main_page_names');
  }

  static Future<void> setMainPageNames({
    required String accountName,
    required List<String> names,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_mainPageNamesKey(accountName), names);
  }

  static Future<List<String>?> getMainPageNames({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_mainPageNamesKey(accountName));
  }

  /// Fully resets the account's main pages (1..15):
  /// - page configs (names/types/modules)
  /// - last selected page index/id
  /// - per-page icon slots/order
  ///
  /// This is intended for "delete -> recreate" workflows.
  static Future<void> resetAccountMainPages({
    required String accountName,
    int pageCount = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Capture current configs first so we can remove pageId-based keys even if
    // user customized IDs.
    final currentConfigs = await getMainPageConfigs(
      accountName: accountName,
      pageCount: pageCount,
    );
    final defaultConfigs = defaultMainPageConfigs();
    final pageIds = <String>{
      ...currentConfigs.map((c) => c.pageId),
      ...defaultConfigs.map((c) => c.pageId),
    };

    // Main page structure + legacy compatibility keys
    await prefs.remove(_mainPageConfigsKey(accountName));
    await prefs.remove(_mainPageLastIdKey(accountName));
    await prefs.remove(_mainPageIndexKey(accountName));
    await prefs.remove(_mainPageNamesKey(accountName));
    await prefs.remove(_pageTypesKey(accountName));

    // Account-wide icon display behavior
    await prefs.remove(_hideEmptySlotsKey(accountName));

    // Per-page icon state (legacy index-based + new pageId-based)
    for (int i = 0; i < pageCount; i++) {
      await prefs.remove(_pageIconOrderKey(accountName, i));
      await prefs.remove(_pageIconSlotsKey(accountName, i));
    }

    for (final pageId in pageIds) {
      await prefs.remove(_pageIconOrderKeyById(accountName, pageId));
      await prefs.remove(_pageIconSlotsKeyById(accountName, pageId));
      await prefs.remove(_pageSlotGroupsKeyById(accountName, pageId));
    }

    // Defensive cleanup: remove any profile-suffixed variants.
    // Keys are stored as: "<accountName>_<suffix>" where suffix may be
    // "page_<i>_icon_slots_<profile>" etc.
    final accountPrefix = '${accountName}_';
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (!key.startsWith(accountPrefix)) continue;

      // Index-based per-page icon keys (with or without profile suffix).
      final isIndexBasedPageKey =
          key.contains('_page_') &&
          (key.contains('_icon_slots') || key.contains('_icon_order'));

      // PageId-based per-page icon keys.
      final isPageIdKey =
          key.contains('_pageId_') &&
          (key.contains('_icon_slots') ||
              key.contains('_icon_order') ||
              key.contains('_slot_groups'));

      if (isIndexBasedPageKey || isPageIdKey) {
        await prefs.remove(key);
      }
    }
  }

  static String _pageTypesKey(String accountName) {
    return PrefKeys.accountKey(accountName, 'page_types');
  }

  static Future<void> setPageTypes({
    required String accountName,
    required List<String> types,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pageTypesKey(accountName), types);
  }

  static Future<List<String>> getPageTypes({
    required String accountName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_pageTypesKey(accountName));
    return saved ??
        [
          'icons',
          'icons',
          'icons',
          'icons',
          'icons',
          'icons',
          'icons',
          'icons',
          'icons',
          'icons',
          'icons',
          'icons',
          'icons',
          'icons',
          'icons',
        ];
  }

  static String _pageIconOrderKey(
    String accountName,
    int pageIndex, {
    String? profileKey,
  }) {
    return PrefKeys.accountKey(
      accountName,
      _withProfile('page_${pageIndex}_icon_order', profileKey),
    );
  }

  static String _pageIconSlotsKey(
    String accountName,
    int pageIndex, {
    String? profileKey,
  }) {
    return PrefKeys.accountKey(
      accountName,
      _withProfile('page_${pageIndex}_icon_slots', profileKey),
    );
  }

  // --- Per-page icon settings (pageId-based keys) ---
  static String _pageIdKey(String accountName, String pageId, String suffix) {
    return PrefKeys.accountKey(accountName, 'pageId_${pageId}_$suffix');
  }

  static String _pageIconOrderKeyById(String accountName, String pageId) {
    return _pageIdKey(accountName, pageId, 'icon_order');
  }

  static String _pageIconSlotsKeyById(String accountName, String pageId) {
    return _pageIdKey(accountName, pageId, 'icon_slots');
  }

  static String _pageSlotGroupsKeyById(String accountName, String pageId) {
    return _pageIdKey(accountName, pageId, 'slot_groups');
  }

  static Future<void> setPageIconSettingsById({
    required String accountName,
    required String pageId,
    int? legacyPageIndex,
    required List<String> order,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _pageIconOrderKeyById(accountName, pageId),
      order,
    );

    if (legacyPageIndex != null) {
      await setPageIconSettings(
        accountName: accountName,
        pageIndex: legacyPageIndex,
        order: order,
      );
    }
  }

  static Future<({List<String> order})> getPageIconSettingsById({
    required String accountName,
    required String pageId,
    int? legacyPageIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final order = prefs.getStringList(
      _pageIconOrderKeyById(accountName, pageId),
    );
    if (order != null) {
      return (order: order);
    }
    if (legacyPageIndex != null) {
      return await getPageIconSettings(
        accountName: accountName,
        pageIndex: legacyPageIndex,
      );
    }
    return (order: <String>[]);
  }

  static Future<void> setPageIconSlotsById({
    required String accountName,
    required String pageId,
    int? legacyPageIndex,
    required List<String> slots,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _pageIconSlotsKeyById(accountName, pageId),
      slots,
    );
    if (legacyPageIndex != null) {
      await setPageIconSlots(
        accountName: accountName,
        pageIndex: legacyPageIndex,
        slots: slots,
      );
    }
  }

  static Future<List<String>> getPageIconSlotsById({
    required String accountName,
    required String pageId,
    int? legacyPageIndex,
    int slotCount = Page1BottomQuickIcons.slotCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(
      _pageIconSlotsKeyById(accountName, pageId),
    );
    if (saved != null) {
      if (saved.length >= slotCount) return saved.sublist(0, slotCount);
      return [...saved, ...List<String>.filled(slotCount - saved.length, '')];
    }
    if (legacyPageIndex != null) {
      return await getPageIconSlots(
        accountName: accountName,
        pageIndex: legacyPageIndex,
        slotCount: slotCount,
      );
    }
    return List<String>.filled(slotCount, '');
  }

  static Future<void> setPageSlotGroupsById({
    required String accountName,
    required String pageId,
    int? legacyPageIndex,
    required List<List<String>> groups,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final strings = groups.map((g) => g.join(',')).toList();
    await prefs.setStringList(
      _pageSlotGroupsKeyById(accountName, pageId),
      strings,
    );
    if (legacyPageIndex != null) {
      await setPageSlotGroups(
        accountName: accountName,
        pageIndex: legacyPageIndex,
        groups: groups,
      );
    }
  }

  static Future<List<List<String>>> getPageSlotGroupsById({
    required String accountName,
    required String pageId,
    int? legacyPageIndex,
    int slotCount = Page1BottomQuickIcons.slotCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(
      _pageSlotGroupsKeyById(accountName, pageId),
    );
    if (saved != null) {
      final list = saved
          .take(slotCount)
          .map((s) => s.isEmpty ? <String>[] : s.split(','))
          .toList();
      if (list.length >= slotCount) return list.sublist(0, slotCount);
      return [
        ...list,
        ...List.generate(slotCount - list.length, (_) => <String>[]),
      ];
    }
    if (legacyPageIndex != null) {
      return await getPageSlotGroups(
        accountName: accountName,
        pageIndex: legacyPageIndex,
        slotCount: slotCount,
      );
    }
    return List.generate(slotCount, (_) => <String>[]);
  }

  static String _showEditButtonKey(String accountName) {
    return PrefKeys.accountKey(accountName, 'show_edit_button');
  }

  static Future<void> setShowEditButton({
    required String accountName,
    required bool show,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showEditButtonKey(accountName), show);
  }

  static Future<bool> getShowEditButton({required String accountName}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showEditButtonKey(accountName)) ?? true;
  }

  // Hide-empty-slots toggle (per-account)
  static String _hideEmptySlotsKey(String accountName) {
    return PrefKeys.accountKey(accountName, 'hide_empty_slots');
  }

  static Future<void> setHideEmptySlots({
    required String accountName,
    required bool hide,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideEmptySlotsKey(accountName), hide);
  }

  static Future<bool> getHideEmptySlots({required String accountName}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hideEmptySlotsKey(accountName)) ?? true;
  }

  // Icon label overrides (per-account)
  //
  // Used by: IconManagementScreen -> 이름 변경
  // Behavior:
  // - Empty/whitespace-only label clears the override.
  // - Stored as JSON Map<String, String> for future compatibility.
  static String _iconLabelOverridesKey(
    String accountName, {
    String? profileKey,
  }) {
    return PrefKeys.accountKey(
      accountName,
      _withProfile('icon_label_overrides_v1', profileKey),
    );
  }

  static Future<Map<String, String>> getIconLabelOverrides({
    required String accountName,
    String? profileKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      _iconLabelOverridesKey(accountName, profileKey: profileKey),
    );
    if (raw == null || raw.isEmpty) return <String, String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, String>{};
      final result = <String, String>{};
      for (final entry in decoded.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is String) {
          result[key] = value;
        }
      }
      return result;
    } catch (_) {
      return <String, String>{};
    }
  }

  static Future<void> setIconLabelOverride({
    required String accountName,
    required String iconId,
    required String? label,
    String? profileKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getIconLabelOverrides(
      accountName: accountName,
      profileKey: profileKey,
    );
    final next = Map<String, String>.from(current);
    final normalized = label?.trim();

    if (normalized == null || normalized.isEmpty) {
      next.remove(iconId);
    } else {
      next[iconId] = normalized;
    }

    await prefs.setString(
      _iconLabelOverridesKey(accountName, profileKey: profileKey),
      jsonEncode(next),
    );
  }

  static Future<void> setPageIconSettings({
    required String accountName,
    required int pageIndex,
    required List<String> order,
    String? profileKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _pageIconOrderKey(accountName, pageIndex, profileKey: profileKey),
      order,
    );
  }

  static Future<({List<String> order})> getPageIconSettings({
    required String accountName,
    required int pageIndex,
    String? profileKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final order =
        prefs.getStringList(
          _pageIconOrderKey(accountName, pageIndex, profileKey: profileKey),
        ) ??
        [];
    return (order: order);
  }

  // Slots API: fixed slot count per page (e.g., 12 slots)
  static Future<void> setPageIconSlots({
    required String accountName,
    required int pageIndex,
    required List<String> slots,
    String? profileKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _pageIconSlotsKey(accountName, pageIndex, profileKey: profileKey),
      slots,
    );
  }

  static Future<List<String>> getPageIconSlots({
    required String accountName,
    required int pageIndex,
    int slotCount = Page1BottomQuickIcons.slotCount,
    String? profileKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(
      _pageIconSlotsKey(accountName, pageIndex, profileKey: profileKey),
    );
    if (saved == null) {
      return List<String>.filled(slotCount, '');
    }
    if (saved.length >= slotCount) return saved.sublist(0, slotCount);
    return [...saved, ...List<String>.filled(slotCount - saved.length, '')];
  }

  // Slot groups API: each slot stores a comma-separated list of icon ids
  static String _pageSlotGroupsKey(String accountName, int pageIndex) {
    return PrefKeys.accountKey(accountName, 'page_${pageIndex}_slot_groups');
  }

  static Future<void> setPageSlotGroups({
    required String accountName,
    required int pageIndex,
    required List<List<String>> groups,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final strings = groups.map((g) => g.join(',')).toList();
    await prefs.setStringList(
      _pageSlotGroupsKey(accountName, pageIndex),
      strings,
    );
  }

  static Future<List<List<String>>> getPageSlotGroups({
    required String accountName,
    required int pageIndex,
    int slotCount = Page1BottomQuickIcons.slotCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(
      _pageSlotGroupsKey(accountName, pageIndex),
    );
    if (saved == null) return List.generate(slotCount, (_) => []);
    final list = saved
        .take(slotCount)
        .map((s) => s.isEmpty ? <String>[] : s.split(','))
        .toList();
    if (list.length >= slotCount) return list.sublist(0, slotCount);
    return [
      ...list,
      ...List.generate(slotCount - list.length, (_) => <String>[]),
    ];
  }

  /// Reset all policy-related preferences to defaults.
  ///
  /// This removes global policy keys (auth/policy flags, screen-saver auth
  /// locks, asset/session flags) and optionally clears account-scoped
  /// main-page configuration by calling [resetAccountMainPages] for every
  /// known account. Use with caution: this will remove user security and
  /// policy settings.
  static Future<void> resetAllPolicies({bool clearAccountPages = true}) async {
    final prefs = await SharedPreferences.getInstance();

    final keysToRemove = [
      PrefKeys.rootAuthMode,
      PrefKeys.rootAuthEnabled,
      PrefKeys.rootPinEnabled,
      PrefKeys.userPinEnabled,
      PrefKeys.userPasswordEnabled,
      PrefKeys.userBiometricEnabled,
      PrefKeys.rootPinSaltB64,
      PrefKeys.userPinSaltB64,
      PrefKeys.userPasswordSaltB64,
      PrefKeys.rootPinHashB64,
      PrefKeys.userPinHashB64,
      PrefKeys.userPasswordHashB64,
      PrefKeys.rootPinIterations,
      PrefKeys.userPinIterations,
      PrefKeys.userPasswordIterations,
      PrefKeys.userPinFailedAttempts,
      PrefKeys.userPasswordFailedAttempts,
      PrefKeys.userPinLockedUntilMs,
      PrefKeys.userPasswordLockedUntilMs,
      PrefKeys.rootPinFailedAttempts,
      PrefKeys.rootPinLockedUntilMs,
      PrefKeys.screenSaverExitAuthFailedAttempts,
      PrefKeys.screenSaverExitAuthLockedUntilMs,
      PrefKeys.rootAuthSessionUntilMs,
      PrefKeys.iconAllowAssetIconsOutsideAssetWhenUnlocked,
      PrefKeys.biometricAuthEnabled,
      PrefKeys.assetAuthSessionUntilMs,
      PrefKeys.screenSaverEnabled,
      PrefKeys.screenSaverIdleSeconds,
      PrefKeys.screenSaverShowAssetSummary,
      PrefKeys.screenSaverShowCharts,
      PrefKeys.screenSaverShowBudget,
      PrefKeys.screenSaverShowEmergency,
      PrefKeys.screenSaverShowSpending,
      PrefKeys.screenSaverShowRecent,
      PrefKeys.screenSaverShowAssetFlow,
    ];

    for (final k in keysToRemove) {
      await prefs.remove(k);
    }

    if (clearAccountPages) {
      try {
        final accounts = AccountService().accounts;
        for (final a in accounts) {
          await resetAccountMainPages(accountName: a.name);
          final trimmed = a.name.trim();
          if (trimmed.isNotEmpty && trimmed != a.name) {
            await resetAccountMainPages(accountName: trimmed);
          }
        }
      } catch (_) {
        // Best-effort: ignore if AccountService isn't initialized.
      }
    }
  }

  // --- Recipe/Ingredient Search History ---

  static const String _recipeSearchLastQueryKey = 'recipe_search_last_query';
  static const String _recipeSearchHistoryKey = 'recipe_search_history';

  static Future<String> getLastRecipeSearchQuery() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_recipeSearchLastQueryKey) ?? '';
  }

  static Future<void> setLastRecipeSearchQuery(String query) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recipeSearchLastQueryKey, query);
  }

  static Future<List<String>> getRecipeSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recipeSearchHistoryKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> addToRecipeSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    final history = await getRecipeSearchHistory();
    final Set<String> unique = {query.trim(), ...history};
    final List<String> newHistory = unique.take(20).toList();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recipeSearchHistoryKey, jsonEncode(newHistory));
  }

  static Future<void> clearRecipeSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recipeSearchHistoryKey);
  }
}

