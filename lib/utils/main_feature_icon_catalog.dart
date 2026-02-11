import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/feature_flags.dart';
import '../navigation/app_routes.dart';
import '../services/account_service.dart';
import '../services/user_pref_service.dart';
import '../services/voice_assistant_settings.dart';
import 'constants.dart';
import 'icon_catalog.dart';

part 'main_feature_icon_catalog_purchase_income.dart';
part 'main_feature_icon_catalog_stats_assets.dart';

/// App feature icon catalog (data-only) with optional voice UI exposure.
@immutable
class MainFeatureIcon {
  final String id;
  final String label;
  final String? labelEn;
  final IconData icon;
  final String? routeName;

  const MainFeatureIcon({
    required this.id,
    required this.label,
    this.labelEn,
    required this.icon,
    this.routeName,
  });

  /// Returns a locale-aware label. Shows bilingual labels for Korean locale
  /// when [bilingualInKorean] is true and an English label exists.
  String labelFor(BuildContext context, {bool bilingualInKorean = true}) {
    final locale = Localizations.localeOf(context);
    final en = labelEn?.trim();
    final hasEn = en != null && en.isNotEmpty;

    if (locale.languageCode == 'en' && hasEn) return en;
    if (locale.languageCode == 'ko' && bilingualInKorean && hasEn) {
      return '$label ($en)';
    }
    return label;
  }
}

@immutable
class MainFeaturePage {
  final int index;
  final List<MainFeatureIcon> items;

  const MainFeaturePage({required this.index, required this.items});
}

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
      case 'dashboard':
      case 'page0':
        return at(0);
      case 'purchase':
      case 'page1':
      case 'page2': // Legacy Purchase at index 1
        return at(1);
      case 'income':
      case 'page3': // Legacy Income at index 2
        return at(2);
      case 'stats':
      case 'page4': // Legacy Stats at index 3
        return at(3);
      case 'asset':
      case 'page5': // Legacy Asset at index 4
        return at(4);
      case 'root':
      case 'page6': // Legacy Root at index 5
        return at(5);
      case 'settings':
      case 'page7': // Legacy Settings index
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
    final pageZeroItems = <MainFeatureIcon>[
      if (voiceVisible)
        const MainFeatureIcon(
          id: 'voice_shortcuts',
          label: '음성 단축어',
          labelEn: 'Voice Shortcuts',
          icon: Icons.mic_outlined,
          routeName: AppRoutes.voiceShortcuts,
        ),
      const MainFeatureIcon(
        id: 'emergency_services',
        label: '긴급 SOS',
        labelEn: 'Emergency SOS',
        icon: Icons.emergency,
        routeName: AppRoutes.emergencyServices,
      ),
    ];

    final settingsItems = <MainFeatureIcon>[
      const MainFeatureIcon(
        id: 'application_settings',
        label: '애플리케이션 설정',
        labelEn: 'App Settings',
        icon: IconCatalog.tune,
        routeName: AppRoutes.applicationSettings,
      ),
      const MainFeatureIcon(
        id: 'settings',
        label: '설정',
        labelEn: 'Settings',
        icon: IconCatalog.settings,
        routeName: AppRoutes.settings,
      ),
      if (voiceVisible)
        const MainFeatureIcon(
          id: 'voice_assistant_settings',
          label: '음성비서 설정',
          labelEn: 'Voice Assistant',
          icon: Icons.record_voice_over,
          routeName: AppRoutes.voiceAssistantSettings,
        ),
      const MainFeatureIcon(
        id: 'settings_screen_saver_settings',
        label: '보호기 설정',
        labelEn: 'Screen Protection',
        icon: IconCatalog.shieldOutlined,
        routeName: AppRoutes.rootScreenSaverSettings,
      ),
      const MainFeatureIcon(
        id: 'theme_settings',
        label: '테마',
        labelEn: 'Theme',
        icon: IconCatalog.paletteOutlined,
        routeName: AppRoutes.themeSettings,
      ),
      const MainFeatureIcon(
        id: 'display_settings',
        label: '표시/폰트',
        labelEn: 'Display/Font',
        icon: IconCatalog.displaySettings,
        routeName: AppRoutes.displaySettings,
      ),
      const MainFeatureIcon(
        id: 'language_settings',
        label: '언어 설정',
        labelEn: 'Language',
        icon: IconCatalog.language,
        routeName: AppRoutes.languageSettings,
      ),
      const MainFeatureIcon(
        id: 'currency_settings',
        label: '통화 설정',
        labelEn: 'Currency',
        icon: IconCatalog.attachMoney,
        routeName: AppRoutes.currencySettings,
      ),
      const MainFeatureIcon(
        id: 'backup',
        label: '백업',
        labelEn: 'Backup',
        icon: IconCatalog.backup,
        routeName: AppRoutes.backup,
      ),
      const MainFeatureIcon(
        id: 'trash',
        label: '휴지통',
        labelEn: 'Trash',
        icon: IconCatalog.deleteSweepOutlined,
        routeName: AppRoutes.trash,
      ),
    ];

    return [
      MainFeaturePage(index: 0, items: pageZeroItems),
      const MainFeaturePage(index: 1, items: kPurchasePageItems),
      const MainFeaturePage(index: 2, items: kIncomePageItems),
      const MainFeaturePage(index: 3, items: kStatsPageItems),
      const MainFeaturePage(index: 4, items: kAssetPageItems),
      const MainFeaturePage(index: 5, items: kRootPageItems),
      MainFeaturePage(index: 6, items: settingsItems),
      ...List<MainFeaturePage>.generate(
        8,
        (i) => MainFeaturePage(index: 7 + i, items: const []),
      ),
    ];
  }
}
