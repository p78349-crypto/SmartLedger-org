import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'l10n/app_localizations.dart';
import 'navigation/app_router.dart';
import 'navigation/global_navigator_key.dart';
import 'screens/launch_screen.dart';
import 'services/voice_assistant_settings.dart';
import 'theme/app_theme.dart';
import 'theme/app_theme_mode_controller.dart';
import 'theme/app_theme_seed_controller.dart';
import 'utils/app_locale_controller.dart';
import 'utils/constants.dart';
import 'config/feature_flags.dart';
import 'widgets/floating_voice_button.dart';

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
            Locale('en'),
            Locale('ko'),
            Locale('ja'),
            Locale('it'),
            Locale('fr'),
            Locale('es'),
            Locale('pl'),
            Locale('ru'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
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
    if (providers.isEmpty) {
      final runtimeVoiceEnabled = VoiceAssistantSettings.instance.enabled;
      return (AppConstants.voiceInputEnabled &&
              (kEnableVoice || runtimeVoiceEnabled))
          ? FloatingVoiceButton(child: app)
          : app;
    }

    final wrapped = MultiProvider(providers: providers, child: app);
    final runtimeVoiceEnabled = VoiceAssistantSettings.instance.enabled;
    return (AppConstants.voiceInputEnabled &&
            (kEnableVoice || runtimeVoiceEnabled))
        ? FloatingVoiceButton(child: wrapped)
        : wrapped;
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
