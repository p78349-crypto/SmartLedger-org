/// Centralized SharedPreferences key constants
class PrefKeys {
  PrefKeys._(); // Private constructor to prevent instantiation

  // Transaction and Account Keys
  static const String transactions = 'transactions';
  static const String accounts = 'accounts';
  static const String accountsList = 'accounts_list';

  /// Transaction storage backend selector.
  /// - 'prefs': legacy SharedPreferences JSON
  /// - 'db': Drift/SQLite
  static const String txStorageBackendV1 = 'tx_storage_backend_v1';

  /// Whether SharedPreferences transactions have been migrated into DB.
  static const String txDbMigratedV1 = 'tx_db_migrated_v1';

  /// Stamp to prevent repeated expensive migrations.
  /// Stored as millisecondsSinceEpoch.
  static const String txDbMigratedAtMsV1 = 'tx_db_migrated_at_ms_v1';

  // Income Split Keys
  static const String incomeSplits = 'income_splits';
  static const String incomeAccounts = 'income_accounts';

  // Budget Keys
  static const String budgets = 'budgets';
  static const String categoryBudgets = 'category_budgets';

  // Fixed Cost Keys
  static const String fixedCosts = 'fixed_costs';

  // Savings Plan Keys
  static const String savingsPlans = 'savings_plans';
  static const String savingsPlansList = 'savings_plans_list';

  // Trash/Backup Keys
  static const String trash = 'trash';
  static const String trashBackup = 'trash_backup';

  // UI State Keys
  static const String selectedAccount = 'selected_account';
  static const String selectedDate = 'selected_date';
  static const String viewPreferences = 'view_preferences';

  // Recent Input Keys
  static const String recentMemos = 'recent_memos';
  static const String recentPaymentMethods = 'recent_payment_methods';
  static const String recentCategories = 'recent_categories';

  /// Category usage counts (label -> count).
  ///
  /// Stored as JSON map string. Used for sorting category pickers by
  /// frequently-used categories.
  static const String categoryUsageCountsV1 = 'category_usage_counts_v1';

  // User Settings Keys
  static const String currency = 'currency';
  static const String language = 'language';
  static const String theme = 'theme';
  static const String themePresetId = 'theme_preset_id_v1';
  // Icon background preset id (separate from wallpaper)
  static const String themeIconBgPresetId = 'theme_icon_bg_preset_id_v1';
  // Wallpaper preset id (for mapping wallpapers to theme variants)
  static const String themeWallpaperPresetId = 'theme_wallpaper_preset_id_v1';
  // Local wallpaper path (device file) stored after processing. Intentionally excluded from backups.
  static const String themeLocalWallpaperPath = 'theme_local_wallpaper_path_v1';


    // Asset projection ("1억 프로젝트") settings
    static const String project100mYearsV1 = 'project_100m_years_v1';
    static const String project100mTargetAmountV1 =
      'project_100m_target_amount_v1';
    static const String project100mSafeRatePctV1 =
      'project_100m_safe_rate_pct_v1';
    static const String project100mInvestRatePctV1 =
      'project_100m_invest_rate_pct_v1';
    static const String project100mIncludeBenefitsV1 =
      'project_100m_include_benefits_v1';

      /// When monthly benefits (discount/points/skipped spend) are included,
      /// they are assumed to be parked in cash until reaching this threshold,
      /// then switched to invest rate.
      static const String project100mCashToInvestThresholdAmountV1 =
        'project_100m_cash_to_invest_threshold_amount_v1';

  // Security / authentication
  static const String biometricAuthEnabled = 'biometric_auth_enabled';

  /// Asset auth session expiry timestamp (millisecondsSinceEpoch).
  ///
  /// When set to a future time, the app may treat asset area as temporarily
  /// unlocked (after successful device authentication).
  static const String assetAuthSessionUntilMs = 'asset_auth_session_until_ms';

  /// ROOT auth mode.
  /// - 'integrated': ROOT access is allowed when asset auth session is active.
  /// - 'separate': ROOT access requires an additional device auth step.
  static const String rootAuthMode = 'root_auth_mode';

  /// Whether ROOT access requires authentication.
  ///
  /// When not set (null), the app falls back to [biometricAuthEnabled] for
  /// backward compatibility.
  static const String rootAuthEnabled = 'root_auth_enabled';

  /// Whether ROOT requires an additional PIN step.
  ///
  /// Intentionally excluded from backups together with PIN material.
  static const String rootPinEnabled = 'root_pin_enabled';

  /// Whether user/account access requires a PIN.
  ///
  /// Intentionally excluded from backups together with PIN material.
  static const String userPinEnabled = 'user_pin_enabled';

  /// Whether user/account access requires a password.
  ///
  /// Intentionally excluded from backups together with password material.
  static const String userPasswordEnabled = 'user_password_enabled';

  /// Whether user/account access requires device auth (e.g., fingerprint).
  ///
  /// Intentionally excluded from backups.
  static const String userBiometricEnabled = 'user_biometric_enabled';

  /// ROOT PIN salt (base64).
  ///
  /// Sensitive: intentionally excluded from backups.
  static const String rootPinSaltB64 = 'root_pin_salt_b64';

  /// User PIN salt (base64).
  ///
  /// Sensitive: intentionally excluded from backups.
  static const String userPinSaltB64 = 'user_pin_salt_b64';

  /// User password salt (base64).
  ///
  /// Sensitive: intentionally excluded from backups.
  static const String userPasswordSaltB64 = 'user_password_salt_b64';

  /// ROOT PIN hash/derived key (base64).
  ///
  /// Sensitive: intentionally excluded from backups.
  static const String rootPinHashB64 = 'root_pin_hash_b64';

  /// User PIN hash/derived key (base64).
  ///
  /// Sensitive: intentionally excluded from backups.
  static const String userPinHashB64 = 'user_pin_hash_b64';

  /// User password hash/derived key (base64).
  ///
  /// Sensitive: intentionally excluded from backups.
  static const String userPasswordHashB64 = 'user_password_hash_b64';

  /// ROOT PIN derivation iterations.
  ///
  /// Sensitive-adjacent: excluded from backups.
  static const String rootPinIterations = 'root_pin_iterations';

  /// User PIN derivation iterations.
  ///
  /// Sensitive-adjacent: excluded from backups.
  static const String userPinIterations = 'user_pin_iterations';

  /// User password derivation iterations.
  ///
  /// Sensitive-adjacent: excluded from backups.
  static const String userPasswordIterations = 'user_password_iterations';

  /// User PIN failed attempt count (for lockout).
  ///
  /// Sensitive-adjacent: excluded from backups.
  static const String userPinFailedAttempts = 'user_pin_failed_attempts';

  /// User password failed attempt count (for lockout).
  ///
  /// Sensitive-adjacent: excluded from backups.
  static const String userPasswordFailedAttempts =
      'user_password_failed_attempts';

  /// User PIN lockout expiry timestamp (millisecondsSinceEpoch).
  ///
  /// Sensitive-adjacent: excluded from backups.
  static const String userPinLockedUntilMs = 'user_pin_locked_until_ms';

  /// User password lockout expiry timestamp (millisecondsSinceEpoch).
  ///
  /// Sensitive-adjacent: excluded from backups.
  static const String userPasswordLockedUntilMs =
      'user_password_locked_until_ms';

  /// ROOT PIN failed attempt count (for lockout).
  ///
  /// Sensitive-adjacent: excluded from backups.
  static const String rootPinFailedAttempts = 'root_pin_failed_attempts';

  /// ROOT PIN lockout expiry timestamp (millisecondsSinceEpoch).
  ///
  /// Sensitive-adjacent: excluded from backups.
  static const String rootPinLockedUntilMs = 'root_pin_locked_until_ms';

  /// Screen saver exit auth failed attempt count (for lockout).
  ///
  /// Sensitive-adjacent: excluded from backups.
  static const String screenSaverExitAuthFailedAttempts =
      'screen_saver_exit_auth_failed_attempts';

  /// Screen saver exit auth lockout expiry timestamp.
  ///
  /// Stored as millisecondsSinceEpoch.
  /// Sensitive-adjacent: excluded from backups.
  static const String screenSaverExitAuthLockedUntilMs =
      'screen_saver_exit_auth_locked_until_ms';

  /// ROOT auth session expiry timestamp (millisecondsSinceEpoch).
  ///
  /// Used when rootAuthMode == 'separate'.
  static const String rootAuthSessionUntilMs = 'root_auth_session_until_ms';

  /// Icon policy: allow asset/income icons on non-asset pages when asset is
  /// unlocked (and user explicitly enables this option).
  static const String iconAllowAssetIconsOutsideAssetWhenUnlocked =
      'icon_allow_asset_outside_when_unlocked';

  // Release/entitlement and feature flags
  static const String isOfficialUser = 'is_official_user';
  static const String page1FullScreenAdEnabled = 'page1_fullscreen_ad_enabled';

  /// UI option: show numeric quick buttons (0/00/000) near number inputs.
  ///
  /// Default: false (OFF) for safety/usability.
  static const String zeroQuickButtonsEnabled = 'zero_quick_buttons_enabled';

  // Backup and Sync Keys
  static const String lastBackup = 'last_backup';
  static const String autoBackupEnabled = 'auto_backup_enabled';
  static const String syncEnabled = 'sync_enabled';

  /// Backup encryption: encrypt backup payload using a user-provided password.
  ///
  /// When enabled, backups require a password prompt and auto-backup should be
  /// skipped.
  static const String backupEncryptionEnabled = 'backup_encryption_enabled';

  /// Backup protection: require device auth + password (and encrypt backup).
  static const String backupTwoFactorEnabled = 'backup_two_factor_enabled';

  // Backup UI helpers
  static const String backupRegisteredEmail = 'backup_registered_email';

  // Privacy policy consent (agree / disagree)
  static const String privacyPolicyConsentChoice =
      'privacy_policy_consent_choice';

  // Debug and Logging Keys
  static const String debugMode = 'debug_mode';
  static const String logLevel = 'log_level';

  /// Developer/testing: when true, skip asset/root authentication gates.
  /// WARNING: this should never be enabled in production data/exported prefs.
  static const String bypassSecurityForTesting = 'bypass_security_for_testing';

  // In-app screen saver (idle summary overlay)
  static const String screenSaverEnabled = 'screen_saver_enabled';

  /// Idle timeout seconds before showing the screen saver.
  static const String screenSaverIdleSeconds = 'screen_saver_idle_seconds';

  /// Screen saver exposure controls.
  ///
  /// These settings allow users to decide what cards are shown while in
  /// screen saver mode. Defaults should be safe and consistent.
  static const String screenSaverShowAssetSummary =
      'screen_saver_show_asset_summary';
  static const String screenSaverShowCharts = 'screen_saver_show_charts';
  static const String screenSaverShowBudget = 'screen_saver_show_budget';
  static const String screenSaverShowEmergency = 'screen_saver_show_emergency';
  static const String screenSaverShowSpending = 'screen_saver_show_spending';
  static const String screenSaverShowRecent = 'screen_saver_show_recent';
  static const String screenSaverShowAssetFlow = 'screen_saver_show_asset_flow';

  /// Local-only background image file path for screen saver.
  ///
  /// Intentionally excluded from backups (do NOT add to [settingKeys]) because
  /// it points to a device-local file and may contain personal content.
  static const String screenSaverLocalBackgroundImagePath =
      'screen_saver_local_background_image_path';

  // Main UI Keys
  static const String mainPageIndexSuffix = 'main_page_index';

  // Month-end carryover keys
  static const String accountMonthEnd = 'account_month_end';

  // Emergency fund keys
  static const String emergencyFundTransactions = 'emergency_fund_transactions';

  /// Derived data: monthly total asset snapshots (used for trends/charts).
  ///
  /// Stored as JSON map: { accountName: { "yyyy-MM": totalAssetsDouble } }
  static const String assetMonthlySnapshots = 'asset_monthly_snapshots';

  /// Account-scoped store alias -> canonical mapping (v1).
  ///
  /// Stored per account via [accountKey].
  static const String storeAliasMapV1Suffix = 'store_alias_map_v1';

  /// Get a prefixed key for account-specific data
  static String accountKey(String accountName, String suffix) {
    return '${accountName}_$suffix';
  }

  /// Get a prefixed key for user-specific data
  static String userKey(String userId, String suffix) {
    return 'user_${userId}_$suffix';
  }

  /// Get a list of all transaction-related keys
  static const List<String> transactionKeys = [
    transactions,
    accounts,
    accountsList,
  ];

  /// Get a list of all budget-related keys
  static const List<String> budgetKeys = [budgets, categoryBudgets];

  /// Get a list of all savings-related keys
  static const List<String> savingsKeys = [savingsPlans, savingsPlansList];

  /// Get a list of all recent input keys
  static const List<String> recentInputKeys = [
    recentMemos,
    recentPaymentMethods,
    recentCategories,
  ];

  /// Get a list of all settings keys
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
  ];

  /// Get a list of all backup-related keys
  static const List<String> backupKeys = [
    trash,
    trashBackup,
    lastBackup,
    autoBackupEnabled,
  ];
}

