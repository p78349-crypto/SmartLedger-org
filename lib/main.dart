import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'navigation/app_router.dart';
import 'navigation/deep_link_handler.dart';
import 'navigation/global_navigator_key.dart';
import 'screens/launch_screen.dart';
import 'services/account_service.dart';
import 'services/asset_service.dart';
import 'services/budget_service.dart';
import 'services/fixed_cost_auto_record_service.dart';
import 'services/fixed_cost_service.dart';
import 'services/notification_service.dart';
import 'services/transaction_service.dart';
import 'services/user_pref_service.dart';
import 'services/food_expiry_service.dart';
import 'services/recipe_service.dart';
import 'services/recipe_knowledge_service.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_mode_controller.dart';
import 'theme/app_theme_seed_controller.dart';
import 'utils/app_locale_controller.dart';
import 'utils/currency_formatter.dart';
import 'utils/icon_catalog.dart';
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
    debugPrint('UNCAUGHT (PlatformDispatcher): $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

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
        FoodExpiryService.instance.load(),
        RecipeService.instance.load(),
        RecipeKnowledgeService.instance.loadData(),
      ]);

      // Monthly routine: auto-record fixed costs (local-only).
      // Note: runs when the app starts (or restarts). If the app isn't opened
      // on the due day, it will be recorded on the next launch after the date.
      try {
        await FixedCostAutoRecordService().runForAllAccounts(backfillMonths: 6);
      } catch (_) {
        // Best-effort; never block startup.
      }
      // One-off migration: move asset-related icons to the asset page.
      // This operation updates per-account persisted page slots so assets
      // appear consistently (default page index: 5).
      // Best-effort; non-destructive.
      try {
        // One-off migration: move asset-related icons into the asset page.
        await MainPageMigration.moveAssetIconsToPageForAllAccounts();
      } catch (_) {
        // ignore
      }
      // Maintenance: if compiled with `-DMAINTENANCE_RECREATE_PAGES=true`
      // then list page-related SharedPreferences keys and recreate pages
      // with a fresh 15 empty pages (clearing existing prefs first).
      const doMaintenance = bool.fromEnvironment('MAINTENANCE_RECREATE_PAGES');
      if (doMaintenance) {
        try {
          final keys = await MainFeatureIconCatalog.listPagePrefKeys();
          debugPrint('PAGE PREF KEYS (audit): ${keys.join(', ')}');
          await MainFeatureIconCatalog.recreatePages(
            15,
            clearExistingPrefs: true,
          );
          debugPrint('Main pages recreated (15) and prefs cleared.');
        } catch (e, st) {
          debugPrint('Maintenance error: $e');
          debugPrintStack(stackTrace: st);
        }
      }
      // (Removed) Forced main pages reset/create on startup.
      // FORCED POLICIES RESET: clear security/policy prefs on startup.
      // Toggle using the compile-time environment variable
      // `FORCE_RESET_POLICIES`. Default: true.
      const forceResetPolicies = bool.fromEnvironment(
        'FORCE_RESET_POLICIES',
        defaultValue: true,
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
        debugPrint('DeepLinkHandler init failed: $e');
      }
      runApp(const MyApp());
    },
    (Object error, StackTrace stack) {
      debugPrint('UNCAUGHT (Zone): $error');
      debugPrintStack(stackTrace: stack);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    const minimalUi = bool.fromEnvironment('MINIMAL_UI');
    final app = ListenableBuilder(
      listenable: Listenable.merge([
        AppThemeModeController.instance.themeMode,
        AppThemeSeedController.instance.presetId,
        AppThemeSeedController.instance.uiStyle,
        AppLocaleController.instance.locale,
      ]),
      builder: (context, _) {
        final presetId = AppThemeSeedController.instance.presetId.value;
        final uiStyle = AppThemeSeedController.instance.uiStyle.value;
        final localeOverride = AppLocaleController.instance.locale.value;

        // Resolve actual ThemeMode and Preset using the controller
        final resolution = AppThemeModeController.instance.resolve(presetId);
        final themeMode = resolution.mode;
        final preset = resolution.preset;

        // Keep Intl default locale in sync for any legacy Intl usages.
        final systemLocale = PlatformDispatcher.instance.locale;
        final intlLocaleName = (localeOverride ?? systemLocale)
            .toLanguageTag()
            .replaceAll('-', '_');
        Intl.defaultLocale = intlLocaleName;

        return MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'SmartLedger',
          debugShowCheckedModeBanner: false,
          locale: localeOverride,
          supportedLocales: const [
            Locale('en', 'US'),
            Locale('ko', 'KR'),
            Locale('ja', 'JP'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.buildSmartTheme(
            seedColor: preset.seedColor,
            brightness: Brightness.light,
            uiStyle: uiStyle,
          ),
          darkTheme: AppTheme.buildSmartTheme(
            seedColor: preset.seedColor,
            brightness: Brightness.dark,
            uiStyle: uiStyle,
            backgroundColor: preset.backgroundColor,
          ),
          themeMode: themeMode,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final textScaler = mediaQuery.textScaler.clamp(
              minScaleFactor: 1.0,
              maxScaleFactor: 1.15,
            );
            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: textScaler),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: minimalUi ? const _MinimalBootScreen() : const LaunchScreen(),
          onGenerateRoute: minimalUi ? null : AppRouter.onGenerateRoute,
        );
      },
    );

    // MultiProvider asserts when the provider list is empty.
    // Keep this guard so tests/builds don't crash when no providers are used.
    final providers = <SingleChildWidget>[];
    if (providers.isEmpty) return app;

    return MultiProvider(providers: providers, child: app);
  }
}

class _MinimalBootScreen extends StatelessWidget {
  const _MinimalBootScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('MINIMAL_UI'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'UI 연결 임시 차단 상태',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '빌드/설치 및 상태 점검용으로\nLaunchScreen/라우터를 우회했습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: .center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(IconCatalog.add),
      ),
    );
  }
}
