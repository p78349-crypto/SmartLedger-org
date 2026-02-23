import 'package:shared_preferences/shared_preferences.dart';

import '../config/feature_flags.dart';
import '../services/account_service.dart';
import '../services/user_pref_service.dart';
import '../services/voice_assistant_settings.dart';
import 'constants.dart';
import 'main_feature_icon_catalog_purchase_income.dart';
import 'main_feature_icon_catalog_stats_settings.dart';
import 'main_feature_icon_models.dart';

export 'main_feature_icon_models.dart';

class MainFeatureIconCatalog {
  MainFeatureIconCatalog._();

  static bool _pagesBlocked = false;
  static List<MainFeaturePage>? _pagesOverride;

  static int get pageCount => _pagesBlocked ? 0 : pages.length;
  static void setPagesBlocked(bool blocked) => _pagesBlocked = blocked;

  /// Recreate the main pages with `count` empty pages.
  static Future<void> recreatePages(
    int count, {
    bool clearExistingPrefs = false,
  }) async {
    final oldCount = pages.length;
    if (clearExistingPrefs) {
      await AccountService().loadAccounts();
      for (final account in AccountService().accounts) {
        await UserPrefService.resetAccountMainPages(
          accountName: account.name,
          pageCount: oldCount,
        );
      }
    }

    _pagesOverride = List<MainFeaturePage>.generate(
      count,
      (i) => MainFeaturePage(index: i, items: const <MainFeatureIcon>[]),
    );
    _pagesBlocked = false;
  }

  /// Return a list of preference keys that look like page-related keys.
  static Future<List<String>> listPagePrefKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    return keys.where((k) {
      final low = k.toLowerCase();
      return low.contains('_page_') ||
          low.contains('main_page') ||
          low.contains('pageid_') ||
          low.contains('page_types') ||
          low.contains('page_');
    }).toList();
  }

  /// Returns curated icons for a logical module key.
  static List<MainFeatureIcon> iconsForModuleKey(String moduleKey) {
    List<MainFeatureIcon> at(int idx) {
      if (idx < 0 || idx >= pages.length) return const <MainFeatureIcon>[];
      return pages[idx].items;
    }

    switch (moduleKey) {
      case 'page1':
        return at(0);
      case 'purchase':
        return at(1);
      case 'income':
        return at(2);
      case 'stats':
        return at(3);
      case 'asset':
        return at(4);
      case 'root':
        return at(5);
      case 'settings':
        return at(6);
      case 'reserved':
        return const [];
      default:
        return pages.expand((p) => p.items).toList();
    }
  }

  static List<MainFeaturePage> get pages {
    if (_pagesBlocked) return const [];
    if (_pagesOverride != null) return _pagesOverride!;

    final voiceVisible =
        AppConstants.voiceInputEnabled &&
        (kEnableVoice || VoiceAssistantSettings.instance.enabled);
    return _buildDefaultPages(voiceVisible: voiceVisible);
  }

  static List<MainFeaturePage> _buildDefaultPages({
    required bool voiceVisible,
  }) {
    return [
      MainFeaturePage(
        index: 0,
        items: buildPageZeroItems(voiceVisible: voiceVisible),
      ),
      const MainFeaturePage(index: 1, items: kPurchasePageItems),
      const MainFeaturePage(index: 2, items: kIncomePageItems),
      const MainFeaturePage(index: 3, items: kStatsPageItems),
      const MainFeaturePage(index: 4, items: kAssetPageItems),
      const MainFeaturePage(index: 5, items: kRootPageItems),
      MainFeaturePage(
        index: 6,
        items: buildSettingsItems(voiceVisible: voiceVisible),
      ),
      ...List<MainFeaturePage>.generate(
        8,
        (i) => MainFeaturePage(index: 7 + i, items: const []),
      ),
    ];
  }
}
