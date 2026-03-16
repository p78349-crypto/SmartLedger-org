import '../services/account_service.dart';
import '../services/user_pref_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_feature_icon_catalog.dart';
import 'main_feature_icon_catalog_purchase_income.dart';
import 'main_feature_icon_catalog_stats_settings.dart';
import 'page1_bottom_quick_icons.dart';

class MainPageMigration {
  static const String _relayout20260223Flag = 'main_pages_relayout_20260223_done';
  static const String _relayout20260223RootSplitFlag =
      'main_pages_relayout_20260223_root_to_page4_done';

  /// One-off forced relayout (2026-02-23).
  ///
  /// Requested layout:
  /// - Income page icons: removed
  /// - Page 3(stats) -> page 2
  /// - Page 4(asset) -> page 3
  /// - Page 5(ROOT) -> page 4
  /// - Page 6(settings) -> page 5
  /// - Page 7(index 6) becomes empty
  static Future<void> applyRelayout20260223IfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_relayout20260223Flag) ?? false;
    if (done) return;

    await AccountService().loadAccounts();

    final statsIds = kStatsPageItems.map((e) => e.id).toList(growable: false);
    final assetIds = kAssetPageItems.map((e) => e.id).toList(growable: false);
    final rootIds = kRootPageItems.map((e) => e.id).toList(growable: false);
    final settingsIds = <String>{
      ...buildSettingsItems(voiceVisible: false).map((e) => e.id),
      ...buildSettingsItems(voiceVisible: true).map((e) => e.id),
    }.toList(growable: false);

    const targetStatsPage = 2;
    const targetAssetPage = 3;
    const targetRootPage = 4;
    const targetSettingsPage = 5;
    const emptyPage6 = 6;

    final pageCount = MainFeatureIconCatalog.pageCount;
    if (pageCount <= emptyPage6) {
      await prefs.setBool(_relayout20260223Flag, true);
      return;
    }

    for (final account in AccountService().accounts) {
      final accountName = account.name;

      // 1) Remove legacy income icons from ALL pages.
      for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        final slots = await UserPrefService.getPageIconSlots(
          accountName: accountName,
          pageIndex: pageIndex,
        );
        final next = slots
            .map((s) => kIncomePageIconIdsLegacy.contains(s) ? '' : s)
            .toList();
        if (!_listEquals(slots, next)) {
          await UserPrefService.setPageIconSlots(
            accountName: accountName,
            pageIndex: pageIndex,
            slots: next,
          );
        }
      }

      // 2) Force page2 = stats (catalog order).
      await UserPrefService.setPageIconSlots(
        accountName: accountName,
        pageIndex: targetStatsPage,
        slots: _fixedSlotsFromIds(statsIds),
      );

      // 3) Force page3 = asset (catalog order).
      await UserPrefService.setPageIconSlots(
        accountName: accountName,
        pageIndex: targetAssetPage,
        slots: _fixedSlotsFromIds(assetIds),
      );

      // 4) Force page4 = ROOT (catalog order).
      await UserPrefService.setPageIconSlots(
        accountName: accountName,
        pageIndex: targetRootPage,
        slots: _fixedSlotsFromIds(rootIds),
      );

      // 5) Force page5 = Settings (catalog order).
      await UserPrefService.setPageIconSlots(
        accountName: accountName,
        pageIndex: targetSettingsPage,
        slots: _fixedSlotsFromIds(settingsIds),
      );

      // 6) Clear page6 (index 6).
      await UserPrefService.setPageIconSlots(
        accountName: accountName,
        pageIndex: emptyPage6,
        slots: List<String>.filled(Page1BottomQuickIcons.slotCount, ''),
      );
    }

    await prefs.setBool(_relayout20260223Flag, true);
  }

  /// Fix-up migration for devices that already ran the 2026-02-23 relayout
  /// when ROOT and Settings were merged into index 5.
  static Future<void> applyRelayout20260223SplitRootToPage4IfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_relayout20260223RootSplitFlag) ?? false;
    if (done) return;

    await AccountService().loadAccounts();

    final rootIds = kRootPageItems.map((e) => e.id).toList(growable: false);
    final settingsIds = <String>{
      ...buildSettingsItems(voiceVisible: false).map((e) => e.id),
      ...buildSettingsItems(voiceVisible: true).map((e) => e.id),
    }.toList(growable: false);

    const targetRootPage = 4;
    const targetSettingsPage = 5;
    const emptyPage6 = 6;

    final pageCount = MainFeatureIconCatalog.pageCount;
    if (pageCount <= emptyPage6) {
      await prefs.setBool(_relayout20260223RootSplitFlag, true);
      return;
    }

    for (final account in AccountService().accounts) {
      final accountName = account.name;

      await UserPrefService.setPageIconSlots(
        accountName: accountName,
        pageIndex: targetRootPage,
        slots: _fixedSlotsFromIds(rootIds),
      );
      await UserPrefService.setPageIconSlots(
        accountName: accountName,
        pageIndex: targetSettingsPage,
        slots: _fixedSlotsFromIds(settingsIds),
      );
      await UserPrefService.setPageIconSlots(
        accountName: accountName,
        pageIndex: emptyPage6,
        slots: List<String>.filled(Page1BottomQuickIcons.slotCount, ''),
      );
    }

    await prefs.setBool(_relayout20260223RootSplitFlag, true);
  }

  static List<String> _fixedSlotsFromIds(List<String> ids) {
    final slots = List<String>.filled(Page1BottomQuickIcons.slotCount, '');
    for (final id in ids) {
      final i = slots.indexWhere((e) => e.isEmpty);
      if (i == -1) break;
      slots[i] = id;
    }
    return slots;
  }

  /// Move all asset-related icons into [targetPageIndex] for every account.
  ///
  /// This is best-effort and non-destructive: it only updates per-account
  /// persisted page slots to prefer asset icons on the asset page.
  static Future<void> moveAssetIconsToPageForAllAccounts({
    int targetPageIndex = 4,
  }) async {
    await AccountService().loadAccounts();

    final assetIcons = MainFeatureIconCatalog.iconsForModuleKey(
      'asset',
    ).map((m) => m.id).toSet();

    final pageCount = MainFeatureIconCatalog.pageCount;
    if (pageCount <= 0) return;

    for (final a in AccountService().accounts) {
      final accountName = a.name;

      // Collect all asset ids that exist in any page for this account.
      final found = <String>{};
      final currentPages = <int, List<String>>{};

      for (var i = 0; i < pageCount; i++) {
        final slots = await UserPrefService.getPageIconSlots(
          accountName: accountName,
          pageIndex: i,
        );
        currentPages[i] = List<String>.from(slots);
        for (final s in slots) {
          if (s.isNotEmpty && assetIcons.contains(s)) found.add(s);
        }
      }

      if (found.isEmpty) continue;

      // Ensure target page slots exist and are mutable.
      final targetSlots =
          currentPages[targetPageIndex] ??
          List<String>.filled(Page1BottomQuickIcons.slotCount, '');
      final nextTarget = List<String>.from(targetSlots);

      // Fill target with any missing asset ids.
      for (final id in found) {
        if (nextTarget.contains(id)) continue;
        final emptyIndex = nextTarget.indexWhere((e) => e.isEmpty);
        if (emptyIndex != -1) {
          nextTarget[emptyIndex] = id;
        }
      }

      var changed = false;

      // If target changed, persist it.
      if (!_listEquals(nextTarget, targetSlots)) {
        await UserPrefService.setPageIconSlots(
          accountName: accountName,
          pageIndex: targetPageIndex,
          slots: nextTarget,
        );
        changed = true;
      }

      // Remove moved ids from other pages.
      for (var i = 0; i < pageCount; i++) {
        if (i == targetPageIndex) continue;
        final orig = currentPages[i]!;
        final next = orig.map((s) => assetIcons.contains(s) ? '' : s).toList();
        if (!_listEquals(orig, next)) {
          await UserPrefService.setPageIconSlots(
            accountName: accountName,
            pageIndex: i,
            slots: next,
          );
          changed = true;
        }
      }

      if (changed) {
        // best-effort short pause to avoid hogging I/O in tight loops.
        await Future.delayed(const Duration(milliseconds: 5));
      }
    }
  }

  /// Ensure the integrated server-sync settings icon is visible on settings page
  /// (page index 6) for every account.
  ///
  /// This is best-effort and non-destructive:
  /// - If already present, no change.
  /// - If there is an empty slot on page 6, it inserts the icon there.
  /// - If no empty slot exists, it falls back to replacing one generic
  ///   `settings` icon slot so the new entry is still discoverable.
  static Future<void> ensureServerSyncIconOnSettingsPageForAllAccounts({
    int settingsPageIndex = 6,
    String iconId = 'server_sync_settings',
  }) async {
    await AccountService().loadAccounts();

    final pageCount = MainFeatureIconCatalog.pageCount;
    if (pageCount <= settingsPageIndex) return;

    for (final account in AccountService().accounts) {
      final accountName = account.name;
      final slots = await UserPrefService.getPageIconSlots(
        accountName: accountName,
        pageIndex: settingsPageIndex,
      );

      if (slots.contains(iconId)) continue;

      final next = List<String>.from(slots);
      final emptyIndex = next.indexWhere((s) => s.isEmpty);

      if (emptyIndex != -1) {
        next[emptyIndex] = iconId;
      } else {
        final replaceIndex = next.indexWhere((s) => s == 'settings');
        if (replaceIndex == -1) {
          continue;
        }
        next[replaceIndex] = iconId;
      }

      if (!_listEquals(next, slots)) {
        await UserPrefService.setPageIconSlots(
          accountName: accountName,
          pageIndex: settingsPageIndex,
          slots: next,
        );
      }
    }
  }

  /// Ensure the database-encryption icon is visible on settings page
  /// (page index 6) for every account.
  ///
  /// This is best-effort and non-destructive:
  /// - If already present, no change.
  /// - If there is an empty slot on page 6, it inserts the icon there.
  /// - If no empty slot exists, it falls back to replacing one generic
  ///   `settings` icon slot so the entry is discoverable.
  static Future<void> ensureDatabaseEncryptionIconOnSettingsPageForAllAccounts({
    int settingsPageIndex = 6,
    String iconId = 'database_encryption',
  }) async {
    await AccountService().loadAccounts();

    final pageCount = MainFeatureIconCatalog.pageCount;
    if (pageCount <= settingsPageIndex) return;

    for (final account in AccountService().accounts) {
      final accountName = account.name;
      final slots = await UserPrefService.getPageIconSlots(
        accountName: accountName,
        pageIndex: settingsPageIndex,
      );

      if (slots.contains(iconId)) continue;

      final next = List<String>.from(slots);
      final emptyIndex = next.indexWhere((s) => s.isEmpty);

      if (emptyIndex != -1) {
        next[emptyIndex] = iconId;
      } else {
        final replaceIndex = next.indexWhere((s) => s == 'settings');
        if (replaceIndex == -1) {
          continue;
        }
        next[replaceIndex] = iconId;
      }

      if (!_listEquals(next, slots)) {
        await UserPrefService.setPageIconSlots(
          accountName: accountName,
          pageIndex: settingsPageIndex,
          slots: next,
        );
      }
    }
  }

  /// Ensure the unified security settings icon is visible on settings page
  /// (page index 6) for every account.
  ///
  /// Best-effort and non-destructive; follows the same slot policy as other
  /// settings-icon migrations.
  static Future<void> ensureSecuritySettingsIconOnSettingsPageForAllAccounts({
    int settingsPageIndex = 6,
    String iconId = 'security_settings',
  }) async {
    await AccountService().loadAccounts();

    final pageCount = MainFeatureIconCatalog.pageCount;
    if (pageCount <= settingsPageIndex) return;

    for (final account in AccountService().accounts) {
      final accountName = account.name;
      final slots = await UserPrefService.getPageIconSlots(
        accountName: accountName,
        pageIndex: settingsPageIndex,
      );

      if (slots.contains(iconId)) continue;

      final next = List<String>.from(slots);
      final emptyIndex = next.indexWhere((s) => s.isEmpty);

      if (emptyIndex != -1) {
        next[emptyIndex] = iconId;
      } else {
        final replaceIndex = next.indexWhere((s) => s == 'settings');
        if (replaceIndex == -1) {
          continue;
        }
        next[replaceIndex] = iconId;
      }

      if (!_listEquals(next, slots)) {
        await UserPrefService.setPageIconSlots(
          accountName: accountName,
          pageIndex: settingsPageIndex,
          slots: next,
        );
      }
    }
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
