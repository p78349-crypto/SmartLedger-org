import '../services/account_service.dart';
import '../services/user_pref_service.dart';
import 'main_feature_icon_catalog.dart';
import 'page1_bottom_quick_icons.dart';

class MainPageMigration {
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

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
