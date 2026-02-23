import '../navigation/app_routes.dart';
import '../config/ai_security_seal.dart';
import 'icon_catalog.dart';
import 'main_feature_icon_models.dart';

/// Page 3 – Statistics & report icons.
const List<MainFeatureIcon> kStatsPageItems = [
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
    id: 'spending_analysis',
    label: '지출 분석 & 절약 팁',
    labelEn: 'Spending Analysis',
    icon: IconCatalog.analytics,
    routeName: AppRoutes.spendingAnalysis,
  ),
  // 새로 구현된 고급 재무 분석 기능
  MainFeatureIcon(
    id: 'advanced_financial_analytics',
    label: '고급 재무분석',
    labelEn: 'Advanced Analytics',
    icon: IconCatalog.smartAnalysis,
    routeName: AppRoutes.advancedFinancialAnalytics,
  ),
  // CEO 대시보드 예측 분석 기능
  MainFeatureIcon(
    id: 'ceo_prediction_dashboard',
    label: 'CEO 예측 대시보드',
    labelEn: 'CEO Prediction Dashboard',
    icon: IconCatalog.ceoDashboard,
    routeName: AppRoutes.ceoPredictionDashboard,
  ),
];

/// Page 4 – Asset management icons.
const List<MainFeatureIcon> kAssetPageItems = [
  MainFeatureIcon(
    id: 'asset_simple_input',
    label: '간편 입력',
    labelEn: 'Simple Add',
    icon: IconCatalog.addCircle,
    routeName: AppRoutes.assetSimpleInput,
  ),
  MainFeatureIcon(
    id: 'asset_detailed_input',
    label: '상세 입력',
    labelEn: 'Detailed Add',
    icon: IconCatalog.add,
    routeName: AppRoutes.assetDetailInput,
  ),
  MainFeatureIcon(
    id: 'asset_statistics',
    label: '자산 배분',
    labelEn: 'Allocation',
    icon: IconCatalog.pieChart,
    routeName: AppRoutes.assetAllocation,
  ),
  MainFeatureIcon(
    id: 'asset_export',
    label: '내보내기',
    labelEn: 'Export',
    icon: IconCatalog.download,
    routeName: AppRoutes.assetExport,
  ),
  MainFeatureIcon(
    id: 'data_flexible_export',
    label: '유연한 추출',
    labelEn: 'Flexible Export',
    icon: IconCatalog.autoAwesome,
    routeName: AppRoutes.dataFlexibleExport,
  ),
  MainFeatureIcon(
    id: 'asset_list',
    label: '자산 목록',
    labelEn: 'Asset List',
    icon: IconCatalog.list,
    routeName: AppRoutes.assetList,
  ),
  MainFeatureIcon(
    id: 'asset_analysis',
    label: '자산 분석',
    labelEn: 'Analysis',
    icon: IconCatalog.analyticsOutlined,
    routeName: AppRoutes.assetPortfolioAnalysis,
  ),
  MainFeatureIcon(
    id: 'asset_investment_roadmap',
    label: '투자 로드맵',
    labelEn: 'Investment Roadmap',
    icon: IconCatalog.routeOutlined,
    routeName: AppRoutes.assetInvestmentRoadmap,
  ),
  // 새로 구현된 AI 투자 자문 기능
  MainFeatureIcon(
    id: 'ai_investment_advisor',
    label: 'AI 투자자문',
    labelEn: 'AI Investment Advisor',
    icon: IconCatalog.aiInvestment,
    routeName: AppRoutes.aiInvestmentAdvisor,
  ),
  MainFeatureIcon(
    id: 'asset_100m_project',
    label: '1억 프로젝트',
    labelEn: '100M Project',
    icon: IconCatalog.flagOutlined,
    routeName: AppRoutes.assetProject100m,
  ),
  MainFeatureIcon(
    id: 'icon_management_asset_entry',
    label: '아이콘 관리',
    labelEn: 'Icon Manager',
    icon: IconCatalog.gridView,
    routeName: AppRoutes.iconManagementAsset,
  ),
];

/// Page 5 – Root management icons.
const List<MainFeatureIcon> kRootPageItems = [
  MainFeatureIcon(
    id: 'root_summary',
    label: 'ROOT 요약',
    labelEn: 'ROOT Summary',
    icon: IconCatalog.dashboard,
    routeName: AppRoutes.rootSummary,
  ),
  MainFeatureIcon(
    id: 'root_account_summary',
    label: '계정별 현황',
    labelEn: 'Account Summary',
    icon: IconCatalog.accountBalance,
    routeName: AppRoutes.rootAccountSummary,
  ),
  MainFeatureIcon(
    id: 'root_expense_analysis',
    label: '지출 분석',
    labelEn: 'Expense Analysis',
    icon: IconCatalog.barChart,
    routeName: AppRoutes.rootExpenseAnalysis,
  ),
  MainFeatureIcon(
    id: 'ceo_assistant',
    label: 'CEO 비서',
    labelEn: 'CEO Assistant',
    icon: IconCatalog.insightsOutlined,
    routeName: AppRoutes.ceoAssistant,
  ),
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
    id: 'icon_management_root_entry',
    label: '아이콘 관리',
    labelEn: 'Icon Manager',
    icon: IconCatalog.gridView,
    routeName: AppRoutes.iconManagementRoot,
  ),
  // 새로 구현된 백업 시스템들
  MainFeatureIcon(
    id: 'incremental_backup_system',
    label: '점진적 백업',
    labelEn: 'Incremental Backup',
    icon: IconCatalog.incrementalBackup,
    routeName: AppRoutes.incrementalBackup,
  ),
  MainFeatureIcon(
    id: 'cloud_backup_automation',
    label: '클라우드 백업',
    labelEn: 'Cloud Backup',
    icon: IconCatalog.cloudBackup,
    routeName: AppRoutes.cloudBackupSettings,
  ),
  // 새로 구현된 백업 시스템들
  MainFeatureIcon(
    id: 'incremental_backup_system',
    label: '점진적 백업',
    labelEn: 'Incremental Backup',
    icon: IconCatalog.incrementalBackup,
    routeName: AppRoutes.incrementalBackup,
  ),
  MainFeatureIcon(
    id: 'cloud_backup_automation',
    label: '클라우드 백업',
    labelEn: 'Cloud Backup',
    icon: IconCatalog.cloudBackup,
    routeName: AppRoutes.cloudBackupSettings,
  ),
];

/// Builds page 0 quick-access items. Voice-dependent.
List<MainFeatureIcon> buildPageZeroItems({required bool voiceVisible}) {
  return <MainFeatureIcon>[
    const MainFeatureIcon(
      id: 'account_switch',
      label: '계정 전환',
      labelEn: 'Switch Account',
      icon: IconCatalog.switchAccount,
      routeName: '', // 특별 처리: icon_launch_utils에서 다이얼로그 표시
    ),
    const MainFeatureIcon(
      id: 'screen_saver_settings',
      label: '보호기 설정',
      labelEn: 'Screen Protection',
      icon: IconCatalog.shieldOutlined,
      routeName: AppRoutes.rootScreenSaverSettings,
    ),
    if (voiceVisible)
      const MainFeatureIcon(
        id: 'voice_shortcuts',
        label: '음성 단축어',
        labelEn: 'Voice Shortcuts',
        icon: IconCatalog.micOutlined,
        routeName: AppRoutes.voiceShortcuts,
      ),
    const MainFeatureIcon(
      id: 'emergency_services',
      label: '긴급 SOS',
      labelEn: 'Emergency SOS',
      icon: IconCatalog.emergency,
      routeName: AppRoutes.emergencyServices,
    ),
    const MainFeatureIcon(
      id: 'weather_manual_input',
      label: '날씨 입력',
      labelEn: 'Weather Input',
      icon: IconCatalog.weatherInput,
      routeName: AppRoutes.weatherManualInput,
    ),
  ];
}

/// Builds page 6 settings items. Voice-dependent.
List<MainFeatureIcon> buildSettingsItems({required bool voiceVisible}) {
  return <MainFeatureIcon>[
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
        icon: IconCatalog.recordVoiceOver,
        routeName: AppRoutes.voiceAssistantSettings,
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
    // � 개발자 모드에서만 보이는 커스텀 모델 테스트
    if (AiSecuritySeal.isDeveloperModeEnabled)
      const MainFeatureIcon(
        id: 'custom_gemma2_test',
        label: '🔬 Gemma2 테스트',
        labelEn: 'Gemma2 Test',
        icon: IconCatalog.science,
        routeName: AppRoutes.customGemma2Test,
      ),
    // �🔒 AI 모델 선택 기능 - 보안상 이유로 봉인됨 (2026-02-21)
    // const MainFeatureIcon(
    //   id: 'ai_model_selector',
    //   label: 'AI 모델 선택',
    //   labelEn: 'AI Model Selection',
    //   icon: IconCatalog.aiModelSelector,
    //   routeName: AppRoutes.aiModelSelector,
    // ),
    const MainFeatureIcon(
      id: 'trash',
      label: '휴지통',
      labelEn: 'Trash',
      icon: IconCatalog.deleteSweepOutlined,
      routeName: AppRoutes.trash,
    ),
  ];
}
