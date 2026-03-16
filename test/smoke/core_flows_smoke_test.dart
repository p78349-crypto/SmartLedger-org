import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/account_main_screen.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/page1_bottom_quick_icons.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Route<dynamic> stubRoute(RouteSettings settings) {
    return MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: SizedBox.shrink()),
      settings: settings,
    );
  }

  Future<void> pumpMain(
    WidgetTester tester, {
    required String accountName,
    required int pageIndex,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AccountMainScreen(
          accountName: accountName,
          initialIndex: pageIndex,
        ),
        onGenerateRoute: stubRoute,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> setSingleSlotConfig({
    required String accountName,
    required int pageIndex,
    required int slot,
    required String iconId,
  }) async {
    final slots = List<String>.filled(Page1BottomQuickIcons.slotCount, '');
    slots[slot] = iconId;
    await UserPrefService.setPageIconSlots(
      accountName: accountName,
      pageIndex: pageIndex,
      slots: slots,
    );
    await UserPrefService.setPageIconSettings(
      accountName: accountName,
      pageIndex: pageIndex,
      order: const <String>[],
    );
  }

  testWidgets('SMOKE: Home (page 0) slot update reflects in main grid', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PrefKeys.bypassSecurityForTesting: true,
    });

    const accountName = 'smoke_home_p0';
    const pageIndex = 0;

    await setSingleSlotConfig(
      accountName: accountName,
      pageIndex: pageIndex,
      slot: 0,
      iconId: 'account_switch',
    );

    await pumpMain(tester, accountName: accountName, pageIndex: pageIndex);
    expect(find.text('Switch Account'), findsOneWidget);

    final updated = List<String>.filled(Page1BottomQuickIcons.slotCount, '');
    updated[0] = 'account_switch';
    updated[1] = 'page0_monthly_stats';
    await UserPrefService.setPageIconSlots(
      accountName: accountName,
      pageIndex: pageIndex,
      slots: updated,
    );

    await pumpMain(tester, accountName: accountName, pageIndex: pageIndex);
    expect(find.byKey(const ValueKey<String>('main_icon_slot_0_1')), findsOneWidget);
  });

  testWidgets('SMOKE: Reserved pages (3,6) render safely with slot configs', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PrefKeys.bypassSecurityForTesting: true,
    });

    final scenarios = <({
      String account,
      int page,
      String first,
      String second,
    })>[
      (account: 'smoke_stats_p3', page: 3, first: 'accountStats', second: 'reward_system_stats'),
      (account: 'smoke_settings_p6', page: 6, first: 'application_settings', second: 'theme_settings'),
    ];

    for (final scenario in scenarios) {
      await setSingleSlotConfig(
        accountName: scenario.account,
        pageIndex: scenario.page,
        slot: 0,
        iconId: scenario.first,
      );

      final slots = List<String>.filled(Page1BottomQuickIcons.slotCount, '');
      slots[0] = scenario.first;
      slots[1] = scenario.second;
      await UserPrefService.setPageIconSlots(
        accountName: scenario.account,
        pageIndex: scenario.page,
        slots: slots,
      );

      await pumpMain(
        tester,
        accountName: scenario.account,
        pageIndex: scenario.page,
      );
      expect(find.byType(AccountMainScreen), findsOneWidget);
    }
  });

  for (final emptyPageIndex in <int>[7, 8, 9, 10, 11, 12, 13, 14]) {
    testWidgets('SMOKE: Empty page $emptyPageIndex renders slot shell', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefKeys.bypassSecurityForTesting: true,
      });

      final accountName = 'smoke_empty_$emptyPageIndex';
      await setSingleSlotConfig(
        accountName: accountName,
        pageIndex: emptyPageIndex,
        slot: 0,
        iconId: '',
      );

      await pumpMain(
        tester,
        accountName: accountName,
        pageIndex: emptyPageIndex,
      );

      expect(
        find.byKey(ValueKey<String>('main_icon_slot_${emptyPageIndex}_0')),
        findsOneWidget,
      );
    });
  }
}
