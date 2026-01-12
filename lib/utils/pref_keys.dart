/// Centralized SharedPreferences key constants.
class PrefKeys {
  PrefKeys._();

  // Transaction/account
  static const String transactions = 'transactions';
  static const String accounts = 'accounts';
  static const String accountsList = 'accounts_list';
  static const String txStorageBackendV1 = 'tx_storage_backend_v1';
  static const String txDbMigratedV1 = 'tx_db_migrated_v1';
  static const String txDbMigratedAtMsV1 = 'tx_db_migrated_at_ms_v1';

  // Income split
  static const String incomeSplits = 'income_splits';
  static const String incomeAccounts = 'income_accounts';

  // Budget
  static const String budgets = 'budgets';
  static const String categoryBudgets = 'category_budgets';

  // Fixed cost
  static const String fixedCosts = 'fixed_costs';

  // Savings plan
  static const String savingsPlans = 'savings_plans';
  static const String savingsPlansList = 'savings_plans_list';

  // Trash/backup
  static const String trash = 'trash';
  static const String trashBackup = 'trash_backup';

  // UI state
  static const String selectedAccount = 'selected_account';
  static const String selectedDate = 'selected_date';
  static const String viewPreferences = 'view_preferences';

  // Recent inputs
  static const String recentMemos = 'recent_memos';
  static const String recentPaymentMethods = 'recent_payment_methods';
  static const String recentCategories = 'recent_categories';
  static const String txRecentInputsEnabledV1 = 'tx_recent_inputs_enabled_v1';
  static const String txRecentInputsAutofillEnabledV1 =
      'tx_recent_inputs_autofill_enabled_v1';
  static const String txRecentInputsMaxCountV1 =
      'tx_recent_inputs_max_count_v1';

  // Stock use
  static const String stockUseAutoAddDepletionDaysV1 =
      'stock_use_auto_add_depletion_days_v1';
  static const String stockUseAutoAddDepletionDaysFoodV1 =
      'stock_use_auto_add_depletion_days_food_v1';
  static const String stockUseAutoAddDepletionDaysHouseholdV1 =
      'stock_use_auto_add_depletion_days_household_v1';
  static const String stockUsePredictedDepletionNotifyEnabledV1 =
      'stock_use_predicted_depletion_notify_enabled_v1';
  static const String countLikeUnitsV1 = 'count_like_units_v1';

  // Food expiry
  static const String foodExpirySavedFeedbackTemplateV1 =
      'food_expiry_saved_feedback_template_v1';

  // Category
  static const String categoryUsageCountsV1 = 'category_usage_counts_v1';

  // Settings
  static const String currency = 'currency';
  static const String language = 'language';
  static const String theme = 'theme';
  static const String roiDefaultPeriod = 'roi_default_period';
  static const String roiLookaheadMonths = 'roi_lookahead_months';
  static const String policyHolds = 'policy_holds';
  static const String policyBlockingRules = 'policy_blocking_rules';
  static const String ttsSpeechRate = 'tts_speech_rate';
  static const String ttsPitch = 'tts_pitch';
  static const String themePresetId = 'theme_preset_id_v1';
  static const String themeIconBgPresetId = 'theme_icon_bg_preset_id_v1';
  static const String themeWallpaperPresetId = 'theme_wallpaper_preset_id_v1';
  static const String themeUiStyle = 'theme_ui_style_v1';
  static const String themeWallpaperSyncScreenSaver =
      'theme_wallpaper_sync_screen_saver_v1';
  static const String themeLocalWallpaperPath = 'theme_local_wallpaper_path_v1';

  // Asset projection ("1억 프로젝트")
  static const String project100mYearsV1 = 'project_100m_years_v1';
  static const String project100mTargetAmountV1 =
      'project_100m_target_amount_v1';
  static const String project100mSafeRatePctV1 =
      'project_100m_safe_rate_pct_v1';
  static const String project100mInvestRatePctV1 =
      'project_100m_invest_rate_pct_v1';
  static const String project100mIncludeBenefitsV1 =
      'project_100m_include_benefits_v1';
  static const String project100mCashToInvestThresholdAmountV1 =
      'project_100m_cash_to_invest_threshold_amount_v1';

  // Security/auth
  static const String biometricAuthEnabled = 'biometric_auth_enabled';
  static const String privacyMaskSensitive = 'privacy_mask_sensitive_v1';
  static const String assetLockPrefix = 'asset_lock_v1';
  static const String assetAuthSessionUntilMs = 'asset_auth_session_until_ms';
  static const String rootAuthMode = 'root_auth_mode';
  static const String permissionGateBypassed = 'permission_gate_bypassed_v1';
  static const String rootAuthEnabled = 'root_auth_enabled';

  // Sensitive: intentionally excluded from backups with PIN/password material.
  static const String rootPinEnabled = 'root_pin_enabled';
  static const String userPinEnabled = 'user_pin_enabled';
  static const String userPasswordEnabled = 'user_password_enabled';
  static const String userBiometricEnabled = 'user_biometric_enabled';
  static const String rootPinSaltB64 = 'root_pin_salt_b64';
  static const String userPinSaltB64 = 'user_pin_salt_b64';
  static const String userPasswordSaltB64 = 'user_password_salt_b64';
  static const String rootPinHashB64 = 'root_pin_hash_b64';
  static const String userPinHashB64 = 'user_pin_hash_b64';
  static const String userPasswordHashB64 = 'user_password_hash_b64';
  static const String rootPinIterations = 'root_pin_iterations';
  static const String userPinIterations = 'user_pin_iterations';
  static const String userPasswordIterations = 'user_password_iterations';
  static const String userPinFailedAttempts = 'user_pin_failed_attempts';
  static const String userPasswordFailedAttempts =
      'user_password_failed_attempts';
  static const String userPinLockedUntilMs = 'user_pin_locked_until_ms';
  static const String userPasswordLockedUntilMs =
      'user_password_locked_until_ms';
  static const String rootPinFailedAttempts = 'root_pin_failed_attempts';
  static const String rootPinLockedUntilMs = 'root_pin_locked_until_ms';
  static const String screenSaverExitAuthFailedAttempts =
      'screen_saver_exit_auth_failed_attempts';
  static const String screenSaverExitAuthLockedUntilMs =
      'screen_saver_exit_auth_locked_until_ms';
  static const String rootAuthSessionUntilMs = 'root_auth_session_until_ms';
  static const String iconAllowAssetIconsOutsideAssetWhenUnlocked =
      'icon_allow_asset_outside_when_unlocked';

  // Release/feature flags
  static const String isOfficialUser = 'is_official_user';
  static const String page1FullScreenAdEnabled = 'page1_fullscreen_ad_enabled';
  static const String zeroQuickButtonsEnabled = 'zero_quick_buttons_enabled';

  // Backup/sync
  static const String lastBackup = 'last_backup';
  static const String autoBackupEnabled = 'auto_backup_enabled';
  static const String syncEnabled = 'sync_enabled';
  static const String backupEncryptionEnabled = 'backup_encryption_enabled';
  static const String backupTwoFactorEnabled = 'backup_two_factor_enabled';
  static const String backupRegisteredEmail = 'backup_registered_email';
    static const String privacyPolicyConsentChoice =
            'privacy_policy_consent_choice';

  // Debug/logging
  static const String debugMode = 'debug_mode';
  static const String logLevel = 'log_level';
  static const String bypassSecurityForTesting = 'bypass_security_for_testing';

  // In-app screen saver
  static const String screenSaverEnabled = 'screen_saver_enabled';
  static const String screenSaverIdleSeconds = 'screen_saver_idle_seconds';
  static const String screenSaverShowAssetSummary =
      'screen_saver_show_asset_summary';
  static const String screenSaverShowCharts = 'screen_saver_show_charts';
  static const String screenSaverShowBudget = 'screen_saver_show_budget';
  static const String screenSaverShowEmergency = 'screen_saver_show_emergency';
  static const String screenSaverShowSpending = 'screen_saver_show_spending';
  static const String screenSaverShowRecent = 'screen_saver_show_recent';
  static const String screenSaverShowAssetFlow = 'screen_saver_show_asset_flow';
  static const String screenSaverLocalBackgroundImagePath =
      'screen_saver_local_background_image_path';

  // Main UI
  static const String mainPageIndexSuffix = 'main_page_index';
  static const String accountMonthEnd = 'account_month_end';

  // Emergency fund
  static const String emergencyFundTransactions = 'emergency_fund_transactions';

  // Derived
  static const String assetMonthlySnapshots = 'asset_monthly_snapshots';
  static const String storeAliasMapV1Suffix = 'store_alias_map_v1';

  static String accountKey(String accountName, String suffix) {
    return '${accountName}_$suffix';
  }

  static String userKey(String userId, String suffix) {
    return 'user_${userId}_$suffix';
  }

  static const List<String> transactionKeys = [
    transactions,
    accounts,
    accountsList,
  ];

  static const List<String> budgetKeys = [budgets, categoryBudgets];
  static const List<String> savingsKeys = [savingsPlans, savingsPlansList];
  static const List<String> recentInputKeys = [
    recentMemos,
    recentPaymentMethods,
    recentCategories,
  ];

  static const List<String> settingKeys = [
    currency,
    language,
    theme,
    biometricAuthEnabled,
    rootAuthMode,
    rootAuthEnabled,
    backupEncryptionEnabled,
    backupTwoFactorEnabled,
    isOfficialUser,
    page1FullScreenAdEnabled,
    zeroQuickButtonsEnabled,
    screenSaverEnabled,
    screenSaverIdleSeconds,
    screenSaverShowAssetSummary,
    screenSaverShowCharts,
    screenSaverShowBudget,
    screenSaverShowEmergency,
    screenSaverShowSpending,
    screenSaverShowRecent,
    screenSaverShowAssetFlow,
    themeWallpaperSyncScreenSaver,
    roiDefaultPeriod,
    roiLookaheadMonths,
  ];

  static const List<String> backupKeys = [
    trash,
    trashBackup,
    lastBackup,
    autoBackupEnabled,
  ];
}
