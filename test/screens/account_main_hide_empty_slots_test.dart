import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/account_main_screen.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';
import 'package:smart_ledger/utils/page1_bottom_quick_icons.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  const accountName = 'test_hide_empty_slots';

  testWidgets('hide empty slots when setting enabled', (
    WidgetTester tester,
  ) async {
    await UserPrefService.setPageTypes(
      accountName: accountName,
      types: const [
        'icons',
        'icons',
        'icons',
        'icons',
        'icons',
        'icons',
        'icons',
        'icons',
        'icons',
      ],
    );

    // Prepare slots: first three populated, rest empty
    final slots = List<String>.filled(Page1BottomQuickIcons.slotCount, '');
    slots[0] = 'accountStats';
    slots[1] = 'accountStatsSearch';
    slots[2] = 'period_stats_1m';

    await UserPrefService.setPageIconSlots(
      accountName: accountName,
      pageIndex: 3,
      slots: slots,
    );
    await UserPrefService.setHideEmptySlots(
      accountName: accountName,
      hide: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AccountMainScreen(
          accountName: accountName,
          initialIndex: 3,
        ),
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: SizedBox.shrink()),
            settings: settings,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final iconGridPage = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_IconGridPage',
    );

    // The known icon labels should be present
    expect(
      find.descendant(of: iconGridPage, matching: find.textContaining('통계')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: iconGridPage, matching: find.textContaining('검색')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: iconGridPage,
        matching: find.textContaining('월간 리포트'),
      ),
      findsOneWidget,
    );

    // Empty slot '+' icons should not be present
    expect(
      find.descendant(of: iconGridPage, matching: find.byIcon(IconCatalog.add)),
      findsNothing,
    );
  });

  testWidgets('empty slots visible in edit mode even when hide enabled', (
    WidgetTester tester,
  ) async {
    await UserPrefService.setPageTypes(
      accountName: accountName,
      types: const [
        'icons',
        'icons',
        'icons',
        'icons',
        'icons',
        'icons',
        'icons',
        'icons',
        'icons',
      ],
    );

    // Seed a few icons and keep the rest empty.
    // If all slots are empty, the app may auto-prefill reserved pages.
    final slots = List<String>.filled(Page1BottomQuickIcons.slotCount, '');
    slots[0] = 'accountStats';
    slots[1] = 'accountStatsSearch';
    slots[2] = 'period_stats_1m';
    await UserPrefService.setPageIconSlots(
      accountName: accountName,
      pageIndex: 3,
      slots: slots,
    );
    await UserPrefService.setHideEmptySlots(
      accountName: accountName,
      hide: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AccountMainScreen(
          accountName: accountName,
          initialIndex: 3,
        ),
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: SizedBox.shrink()),
            settings: settings,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    final iconGridPage = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_IconGridPage',
    );
    final dynamic iconGridState = tester.state(iconGridPage);
    iconGridState.toggleEditModePublic();
    await tester.pumpAndSettle();

    // Now empty slot '+' icons should be present
    expect(find.byIcon(IconCatalog.add), findsWidgets);
  });
}
