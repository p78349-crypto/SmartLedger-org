import 'dart:async';
import 'app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation/deep_link_handler.dart';
import 'services/account_service.dart';
import 'services/asset_service.dart';
import 'services/budget_service.dart';
import 'services/fixed_cost_auto_record_service.dart';
import 'services/fixed_cost_service.dart';
import 'services/notification_service.dart';
import 'services/transaction_service.dart';
import 'services/user_pref_service.dart';
import 'services/consumable_inventory_service.dart';
import 'services/recipe_service.dart';
import 'services/recipe_knowledge_service.dart';
import 'services/backup_service.dart';
import 'services/integrity_hash_chain_service.dart';
import 'services/voice_assistant_settings.dart';
import 'theme/app_theme_mode_controller.dart';
import 'theme/app_theme_seed_controller.dart';
import 'utils/app_locale_controller.dart';
import 'utils/currency_formatter.dart';
import 'utils/main_feature_icon_catalog.dart';
import 'utils/main_page_migration.dart';
import 'widgets/background_widget.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    // Note: native crashes (e.g. OOM / SIGSEGV inside ML Kit) won't be caught.
    if (kDebugMode) {
      debugPrint('UNCAUGHT (PlatformDispatcher): $error');
      debugPrintStack(stackTrace: stack);
    }
    return true;
  };

  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      // Release can be passed via --dart-define=SENTRY_RELEASE=<id> or CI uses commit SHA
      const releaseFromEnv = String.fromEnvironment('SENTRY_RELEASE');
      if (releaseFromEnv.isNotEmpty) options.release = releaseFromEnv;
      // Environment (production, staging) can be set via --dart-define=FLAVOR=<env>
      const envName = String.fromEnvironment(
        'FLAVOR',
        defaultValue: 'production',
      );
      options.environment = envName;
      const double tracesSampleRate = 0.0; // adjust as needed
      options.tracesSampleRate = tracesSampleRate;
    },
    appRunner: () async {
      await runZonedGuarded(
        () async {
          WidgetsFlutterBinding.ensureInitialized();

          final prefs = await SharedPreferences.getInstance();

          // Optional: enable family sharing backend when compiled with
          // `--dart-define=ENABLE_FAMILY_SHARING=true` and an active family
          // id is set.

          // Locale policy (정석): default follow system; optional override via prefs.
          await AppLocaleController.instance.loadFromPrefs(prefs);

          // Ensure date symbols exist for supported locales.
          await Future.wait([
            initializeDateFormatting('en_US'),
            initializeDateFormatting('ko_KR'),
            initializeDateFormatting('ja_JP'),
          ]);

          await AppThemeModeController.instance.loadFromPrefs(prefs);
          await AppThemeSeedController.instance.loadFromPrefs(prefs);
          await BackgroundHelper.initialize();

          await Future.wait([
            AccountService().loadAccounts(),
            TransactionService().loadTransactions(),
            BudgetService().loadBudgets(),
            AssetService().loadAssets(),
            FixedCostService().loadFixedCosts(),
            CurrencyFormatter.initCurrencyUnit(),
            NotificationService().initialize(),
            ConsumableInventoryService.instance.load(),
            RecipeService.instance.load(),
            RecipeKnowledgeService.instance.loadData(),
            VoiceAssistantSettings.instance.initialize(),
          ]);

          // R3-4: 백업 디렉토리 내 .tmp 잔류 파일 정리 (non-blocking)
          unawaited(BackupService.cleanupStaleTmpFiles());

          // R4-4: 해시 체인 무결성 검증 (non-blocking)
          unawaited(
            IntegrityHashChainService.instance.runStartupVerification(),
          );

          // Monthly routine: auto-record fixed costs (local-only).
          // Note: runs when the app starts (or restarts). If the app isn't opened
          // on the due day, it will be recorded on the next launch after the date.
          try {
            await FixedCostAutoRecordService().runForAllAccounts(
              backfillMonths: 6,
            );
          } catch (_) {
            // Best-effort; never block startup.
          }

          // One-off forced relayout (2026-02-23) per updated page policy.
          try {
            await MainPageMigration.applyRelayout20260223IfNeeded();
          } catch (_) {
            // ignore
          }
          // Fix-up: split ROOT and Settings (ROOT -> index 4, Settings -> index 5).
          try {
            await MainPageMigration.applyRelayout20260223SplitRootToPage4IfNeeded();
          } catch (_) {
            // ignore
          }
          // Main-page icon placement policy is unified: no forced startup re-layout.
          // Maintenance: if compiled with `-DMAINTENANCE_RECREATE_PAGES=true`
          // then list page-related SharedPreferences keys and recreate pages
          // with a fresh 15 empty pages (clearing existing prefs first).
          const doMaintenance = bool.fromEnvironment(
            'MAINTENANCE_RECREATE_PAGES',
          );
          if (doMaintenance) {
            try {
              final keys = await MainFeatureIconCatalog.listPagePrefKeys();
              if (kDebugMode) {
                debugPrint('PAGE PREF KEYS (audit): ${keys.join(', ')}');
              }
              await MainFeatureIconCatalog.recreatePages(
                15,
                clearExistingPrefs: true,
              );
              if (kDebugMode) {
                debugPrint('Main pages recreated (15) and prefs cleared.');
              }
            } catch (e, st) {
              if (kDebugMode) {
                debugPrint('Maintenance error: $e');
                debugPrintStack(stackTrace: st);
              }
            }
          }
          // (Removed) Forced main pages reset/create on startup.
          // FORCED POLICIES RESET: clear security/policy prefs on startup.
          // Toggle using the compile-time environment variable
          // `FORCE_RESET_POLICIES`. Default: false.
          const forceResetPolicies = bool.fromEnvironment(
            'FORCE_RESET_POLICIES',
          );
          if (forceResetPolicies) {
            try {
              await UserPrefService.resetAllPolicies();
            } catch (_) {
              // ignore
            }
          }
          // Initialize deep link handler for App Actions / Bixby integration
          try {
            await DeepLinkHandler.instance.init();
          } catch (e) {
            if (kDebugMode) debugPrint('DeepLinkHandler init failed: $e');
          }
          runApp(const MyApp());

          // Optional: send a test Sentry event when explicitly requested via dart-define
          const sendTest = String.fromEnvironment(
            'SENTRY_SEND_TEST_EVENT',
            defaultValue: 'false',
          );
          if (sendTest.toLowerCase() == 'true') {
            try {
              await Sentry.captureMessage(
                'Sentry test event from CI/local (SENTRY_SEND_TEST_EVENT)',
              );
            } catch (_) {}
          }
        },
        (Object error, StackTrace stack) {
          if (kDebugMode) {
            debugPrint('UNCAUGHT (Zone): $error');
            debugPrintStack(stackTrace: stack);
          }
          // Report to Sentry as well
          try {
            Sentry.captureException(error, stackTrace: stack);
          } catch (_) {}
        },
      );
    },
  );
}
