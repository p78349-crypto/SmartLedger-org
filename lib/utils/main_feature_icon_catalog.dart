import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/navigation/app_routes.dart';
import 'package:smart_ledger/services/account_service.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';

/// App feature icon catalog (data-only).
///
/// Purpose:
/// - Keep a single source of truth for feature icons/labels.
/// - Reuse across redesigned UIs (e.g., Smart Ledger main pages 1..6).
/// - Avoid coupling to bottom sheets / gesture-heavy widgets.
///
/// Notes:
/// - Some routes require arguments (e.g. accountName). This catalog only stores
///   the route name; the caller is responsible for supplying arguments.
@immutable
class MainFeatureIcon {
  final String id;
  final String label;
  final String? labelEn;
  final IconData icon;

  /// Optional route name to navigate to.
  final String? routeName;

  const MainFeatureIcon({
    required this.id,
    required this.label,
    this.labelEn,
    required this.icon,
    this.routeName,
  });

  /// Returns a locale-aware label.
  ///
  /// - Korean locale: show "Korean (English)" when [bilingualInKorean] is true
  ///   and [labelEn] exists.
  /// - English locale: show English when [labelEn] exists.
  /// - Otherwise: fallback to [label].
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
  /// 0-based page index.
  final int index;
  final List<MainFeatureIcon> items;

  const MainFeaturePage({required this.index, required this.items});
}

class MainFeatureIconCatalog {
  const MainFeatureIconCatalog._();

  // Expose pages; by default create 15 new empty pages.
  // The catalog is mutable to allow recreation of pages when we intentionally
  // remove old pages and create a fresh set.
  static bool _pagesBlocked = false;
  static int get pageCount => _pagesBlocked ? 0 : pages.length;

  /// Control whether main pages are blocked. Call with `false` to enable.
  static void setPagesBlocked(bool blocked) => _pagesBlocked = blocked;

  /// Mutable list of pages. Includes predefined icons for various features.
  static List<MainFeaturePage> pages = [
    // Page 0: 홈/보호기 (Home/ScreenSaver)
    const MainFeaturePage(index: 0, items: []),

    // Page 1: 거래 (Purchase/Expense)
    const MainFeaturePage(
      index: 1,
      items: [
        MainFeatureIcon(
          id: 'transactionAdd',
          label: '거래 입력',
          labelEn: 'Add Transaction',
          icon: IconCatalog.payments,
          routeName: AppRoutes.transactionAdd,
        ),
        MainFeatureIcon(
          id: 'quick_simple_expense_input',
          label: '간편 지출(1줄)',
          labelEn: 'Quick Expense (1-line)',
          icon: IconCatalog.quickreplyOutlined,
          routeName: AppRoutes.quickSimpleExpenseInput,
        ),
        MainFeatureIcon(
          id: 'food_expiry',
          label: '식재료 재고/유통기한',
          labelEn: 'Food Inventory',
          icon: IconCatalog.inventory2,
          routeName: AppRoutes.foodExpiry,
        ),
        MainFeatureIcon(
          id: 'nutrition_report',
          label: '요리 레시피/식재료 검색',
          labelEn: 'Recipe/Ingredient Search',
          icon: IconCatalog.articleOutlined,
          routeName: AppRoutes.nutritionReport,
        ),
        MainFeatureIcon(
          id: 'shopping_prep',
          label: '쇼핑준비',
          labelEn: 'Shopping Prep',
          icon: IconCatalog.factCheckOutlined,
          routeName: AppRoutes.shoppingPrep,
        ),
        MainFeatureIcon(
          id: 'shopping_cart',
          label: '장바구니',
          labelEn: 'Cart',
          icon: IconCatalog.shoppingCart,
          routeName: AppRoutes.shoppingCart,
        ),
        MainFeatureIcon(
          id: 'shopping_points_input',
          label: '포인트 입력',
          labelEn: 'Points Input',
          icon: IconCatalog.localOffer,
          routeName: AppRoutes.shoppingPointsInput,
        ),
        MainFeatureIcon(
          id: 'daily_transactions',
          label: '오늘의 지출',
          labelEn: 'Today',
          icon: IconCatalog.calendarToday,
          routeName: AppRoutes.dailyTransactions,
        ),
      ],
    ),

    // Page 2: 수입 (Income)
    const MainFeaturePage(
      index: 2,
      items: [
        MainFeatureIcon(
          id: 'transaction_add_detailed',
          label: '지출입력(상세)',
          labelEn: 'Add Detailed',
          icon: IconCatalog.postAdd,
          routeName: AppRoutes.transactionAddDetailed,
        ),
        MainFeatureIcon(
          id: 'income_add',
          label: '수입 입력',
          labelEn: 'Add Income',
          icon: IconCatalog.addCircle,
          routeName: AppRoutes.transactionAddIncome,
        ),
        MainFeatureIcon(
          id: 'income_detail',
          label: '수입 상세',
          labelEn: 'Income Detail',
          icon: IconCatalog.receiptLongOutlined,
          routeName: AppRoutes.transactionDetailIncome,
        ),
        MainFeatureIcon(
          id: 'income_split',
          label: '수입배분',
          labelEn: 'Income Split',
          icon: IconCatalog.compareArrows,
          routeName: AppRoutes.incomeSplit,
        ),
        MainFeatureIcon(
          id: 'refund_menu',
          label: '반품',
          labelEn: 'Refunds',
          icon: IconCatalog.refund,
          routeName: AppRoutes.refundTransactions,
        ),
      ],
    ),

    // Page 3: 통계 (Statistics)
    const MainFeaturePage(
      index: 3,
      items: [
        MainFeatureIcon(
          id: 'accountStats',
          label: '통계',
          labelEn: 'Stats',
          icon: IconCatalog.barChart,
          routeName: AppRoutes.accountStats,
        ),
        MainFeatureIcon(
          id: 'fixed_cost_stats',
          label: '고정비 통계',
          labelEn: 'Fixed Costs',
          icon: IconCatalog.payments,
          routeName: AppRoutes.fixedCostStats,
        ),
        MainFeatureIcon(
          id: 'period_stats_7d',
          label: '주간 리포트',
          labelEn: 'Weekly Report',
          icon: IconCatalog.calendarToday,
          routeName: AppRoutes.periodStatsWeek,
        ),
        MainFeatureIcon(
          id: 'period_stats_1m',
          label: '월간 리포트',
          labelEn: 'Monthly Report',
          icon: IconCatalog.calendarViewMonth,
          routeName: AppRoutes.periodStatsMonth,
        ),
        MainFeatureIcon(
          id: 'period_stats_3m',
          label: '분기 리포트',
          labelEn: 'Quarterly Report',
          icon: IconCatalog.timeline,
          routeName: AppRoutes.periodStatsQuarter,
        ),
        MainFeatureIcon(
          id: 'period_stats_6m',
          label: '반기 리포트',
          labelEn: 'Half-year Report',
          icon: IconCatalog.calendarViewMonth,
          routeName: AppRoutes.periodStatsHalfYear,
        ),
        MainFeatureIcon(
          id: 'period_stats_1y',
          label: '연간 리포트',
          labelEn: 'Annual Report',
          icon: IconCatalog.dateRange,
          routeName: AppRoutes.periodStatsYear,
        ),
        MainFeatureIcon(
          id: 'period_stats_10y',
          label: '10년',
          labelEn: '10 Years',
          icon: IconCatalog.autoGraph,
          routeName: AppRoutes.periodStatsDecade,
        ),
        MainFeatureIcon(
          id: 'accountStatsSearch',
          label: '검색',
          labelEn: 'Search',
          icon: IconCatalog.search,
          routeName: AppRoutes.accountStatsSearch,
        ),
        MainFeatureIcon(
          id: 'shopping_cheapest_month',
          label: '최저가 달',
          labelEn: 'Cheapest Month',
          icon: IconCatalog.insightsOutlined,
          routeName: AppRoutes.shoppingCheapestMonth,
        ),
        MainFeatureIcon(
          id: 'card_discount_stats',
          label: '카드 할인',
          labelEn: 'Card Discounts',
          icon: IconCatalog.creditCard,
          routeName: AppRoutes.cardDiscountStats,
        ),
        MainFeatureIcon(
          id: 'points_motivation_stats',
          label: '포인트',
          labelEn: 'Points',
          icon: IconCatalog.localOffer,
          routeName: AppRoutes.pointsMotivationStats,
        ),
      ],
    ),

    // Page 4: 자산 (Asset)
    const MainFeaturePage(
      index: 4,
      items: [
        MainFeatureIcon(
          id: 'asset_dashboard',
          label: '자산 대시보드',
          labelEn: 'Asset Dashboard',
          icon: IconCatalog.dashboard,
          routeName: AppRoutes.assetDashboard,
        ),
        MainFeatureIcon(
          id: 'asset_input',
          label: '자산 입력',
          labelEn: 'Add Asset',
          icon: IconCatalog.addBusiness,
          routeName: AppRoutes.assetSimpleInput,
        ),
        MainFeatureIcon(
          id: 'asset_trending_up',
          label: '상승 자산',
          labelEn: 'Allocation',
          icon: IconCatalog.trendingUp,
          routeName: AppRoutes.assetAllocation,
        ),
        MainFeatureIcon(
          id: 'asset_assessment',
          label: '자산 평가',
          labelEn: 'Assessment',
          icon: IconCatalog.assessment,
          routeName: AppRoutes.assetManagement,
        ),
        MainFeatureIcon(
          id: 'icon_management_asset_entry',
          label: '아이콘 관리',
          labelEn: 'Icon Manager',
          icon: IconCatalog.gridView,
          routeName: AppRoutes.iconManagementAsset,
        ),
      ],
    ),

    // Page 5: ROOT (루트 관리)
    const MainFeaturePage(
      index: 5,
      items: [
        MainFeatureIcon(
          id: 'root_transactions',
          label: '전체 거래',
          labelEn: 'All Transactions',
          icon: IconCatalog.list,
          routeName: AppRoutes.rootTransactions,
        ),
        MainFeatureIcon(
          id: 'root_search',
          label: '검색',
          labelEn: 'Search',
          icon: IconCatalog.search,
          routeName: AppRoutes.rootSearch,
        ),
        MainFeatureIcon(
          id: 'root_account_manage',
          label: '계정 관리',
          labelEn: 'Account Manager',
          icon: IconCatalog.accountBalanceWallet,
          routeName: AppRoutes.rootAccountManage,
        ),
        MainFeatureIcon(
          id: 'root_month_end',
          label: '월말 정산',
          labelEn: 'Month-end Close',
          icon: IconCatalog.eventAvailable,
          routeName: AppRoutes.rootMonthEnd,
        ),
        MainFeatureIcon(
          id: 'root_screen_saver_settings',
          label: '보호기 설정',
          labelEn: 'Screen Protection',
          icon: IconCatalog.shieldOutlined,
          routeName: AppRoutes.rootScreenSaverSettings,
        ),
        MainFeatureIcon(
          id: 'icon_management_root_entry',
          label: '아이콘 관리',
          labelEn: 'Icon Manager',
          icon: IconCatalog.gridView,
          routeName: AppRoutes.iconManagementRoot,
        ),
      ],
    ),

    // Page 6: 설정 (Settings)
    const MainFeaturePage(
      index: 6,
      items: [
        MainFeatureIcon(
          id: 'settings',
          label: '설정',
          labelEn: 'Settings',
          icon: IconCatalog.settings,
          routeName: AppRoutes.settings,
        ),
        MainFeatureIcon(
          id: 'settings_screen_saver_settings',
          label: '보호기 설정',
          labelEn: 'Screen Protection',
          icon: IconCatalog.shieldOutlined,
          routeName: AppRoutes.rootScreenSaverSettings,
        ),
        MainFeatureIcon(
          id: 'theme_settings',
          label: '테마',
          labelEn: 'Theme',
          icon: IconCatalog.paletteOutlined,
          routeName: AppRoutes.themeSettings,
        ),
        MainFeatureIcon(
          id: 'display_settings',
          label: '표시/폰트',
          labelEn: 'Display/Font',
          icon: IconCatalog.displaySettings,
          routeName: AppRoutes.displaySettings,
        ),
        MainFeatureIcon(
          id: 'language_settings',
          label: '언어 설정',
          labelEn: 'Language',
          icon: IconCatalog.language,
          routeName: AppRoutes.languageSettings,
        ),
        MainFeatureIcon(
          id: 'currency_settings',
          label: '통화 설정',
          labelEn: 'Currency',
          icon: IconCatalog.attachMoney,
          routeName: AppRoutes.currencySettings,
        ),
        MainFeatureIcon(
          id: 'backup',
          label: '백업',
          labelEn: 'Backup',
          icon: IconCatalog.backup,
          routeName: AppRoutes.backup,
        ),
        MainFeatureIcon(
          id: 'trash',
          label: '휴지통',
          labelEn: 'Trash',
          icon: IconCatalog.deleteSweepOutlined,
          routeName: AppRoutes.trash,
        ),
      ],
    ),

    // Pages 7-14: 예비
    ...List<MainFeaturePage>.generate(
      8,
      (i) => MainFeaturePage(index: 7 + i, items: const []),
    ),
  ];

  /// Recreate the main pages with `count` empty pages.
  ///
  /// If [clearExistingPrefs] is true, this will attempt to clear persisted
  /// per-account page state for the previous page count before recreating.
  static Future<void> recreatePages(
    int count, {
    bool clearExistingPrefs = false,
  }) async {
    final oldCount = pages.length;
    if (clearExistingPrefs) {
      // Load accounts and clear per-account page prefs for the old count.
      await AccountService().loadAccounts();
      for (final a in AccountService().accounts) {
        await UserPrefService.resetAccountMainPages(
          accountName: a.name,
          pageCount: oldCount,
        );
      }
    }

    pages = List<MainFeaturePage>.generate(
      count,
      (i) => MainFeaturePage(index: i, items: const <MainFeatureIcon>[]),
    );

    // Ensure pages are enabled after recreation.
    _pagesBlocked = false;
  }

  /// Return a list of preference keys that look like page-related keys.
  /// Useful for auditing before clearing persisted page data.
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

  /// Returns curated icons for a logical module.
  ///
  /// This is the preferred access pattern for new code to avoid coupling
  /// persistence/behavior to a specific page index.
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
        return at(5);
      case 'root':
        return at(6);
      case 'settings':
        return at(8);
      case 'reserved':
        return const [];
      default:
        return pages.expand((p) => p.items).toList();
    }
  }
}
