import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/account_main_screen.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/page1_bottom_quick_icons.dart';
import 'package:smart_ledger/utils/screen_saver_ids.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  const account = 'test_move_icon';

  testWidgets('move icon to empty slot via drag & drop in edit mode', (
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
    slots[0] = 'transactionAdd';
    slots[1] = ScreenSaverIds.shortcutIconId;
    await UserPrefService.setPageIconSlots(
      accountName: account,
      pageIndex: 0,
      slots: slots,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: const AccountMainScreen(accountName: account, initialIndex: 0),
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

    final src = find.byKey(const ValueKey('main_icon_slot_0_0'));
    final dst = find.byKey(const ValueKey('main_icon_slot_0_2'));
    expect(src, findsOneWidget);
    expect(dst, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(src));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(dst));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    final newSlots = await UserPrefService.getPageIconSlots(
      accountName: account,
      pageIndex: 0,
    );
    expect(newSlots[2], 'transactionAdd');
    expect(newSlots[0], isNot('transactionAdd'));
  });

  testWidgets('move icon to occupied slot swaps via drag & drop', (
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
    slots[0] = 'transactionAdd';
    slots[1] = 'daily_transactions';
    slots[2] = ScreenSaverIds.shortcutIconId;
    await UserPrefService.setPageIconSlots(
      accountName: account,
      pageIndex: 0,
      slots: slots,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: const AccountMainScreen(accountName: account, initialIndex: 0),
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

    final src = find.byKey(const ValueKey('main_icon_slot_0_0'));
    final dst = find.byKey(const ValueKey('main_icon_slot_0_1'));
    expect(src, findsOneWidget);
    expect(dst, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(src));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(tester.getCenter(dst));
    await tester.pumpAndSettle();
    await gesture.up();
    await tester.pumpAndSettle();

    final newSlots = await UserPrefService.getPageIconSlots(
      accountName: account,
      pageIndex: 0,
    );
    expect(newSlots[1], 'transactionAdd');
    expect(newSlots[0], 'daily_transactions');
  });
}
