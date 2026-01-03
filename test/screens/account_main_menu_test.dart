import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/account_main_screen.dart';
import 'package:smart_ledger/screens/icon_management_screen.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/page1_bottom_quick_icons.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  const account = 'test_menu';

  testWidgets('banner does not expose icon management actions', (
    WidgetTester tester,
  ) async {
    await UserPrefService.setHideEmptySlots(accountName: account, hide: true);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ko'),
        supportedLocales: const [Locale('ko'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const AccountMainScreen(accountName: account, initialIndex: 1),
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: SizedBox.shrink()),
            settings: settings,
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    // Icon management is consolidated into Settings -> IconManagementScreen.
    expect(find.byIcon(Icons.add_box_outlined), findsNothing);
    expect(find.byIcon(Icons.restore), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
  });

  testWidgets('long-press on icon does not show icon actions menu', (
    WidgetTester tester,
  ) async {
    await UserPrefService.setPageTypes(
      accountName: account,
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
    final slots = List<String>.filled(Page1BottomQuickIcons.slotCount, '');
    slots[0] = 'accountStats';
    await UserPrefService.setPageIconSlots(
      accountName: account,
      pageIndex: 3,
      slots: slots,
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
        home: const AccountMainScreen(accountName: account, initialIndex: 3),
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

    // Press-and-hold without releasing (avoid triggering onTap navigation).
    final target = find.descendant(
      of: iconGridPage,
      matching: find.textContaining('통계'),
    );
    expect(target, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(target));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.cancel();
    await tester.pumpAndSettle();

    // Long-press icon actions menu should not appear from the main screen.
    expect(find.text('이동'), findsNothing);
    expect(find.text('숨기기'), findsNothing);
  });

  testWidgets('icon management screen does not show photo toggle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: IconManagementScreen(accountName: account)),
    );
    await tester.pumpAndSettle();

    expect(find.text('사진 표시'), findsNothing);
    expect(find.text('사진 숨기기'), findsNothing);
  });
}
