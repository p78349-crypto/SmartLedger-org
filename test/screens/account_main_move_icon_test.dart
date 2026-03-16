import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/account_main_screen.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/page1_bottom_quick_icons.dart';

bool _sameSlots(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

Future<List<String>> _waitForSlotChange({
  required WidgetTester tester,
  required String accountName,
  required int pageIndex,
  required List<String> baseline,
}) async {
  var latest = await UserPrefService.getPageIconSlots(
    accountName: accountName,
    pageIndex: pageIndex,
  );
  if (!_sameSlots(latest, baseline)) return latest;

  for (int i = 0; i < 30; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    latest = await UserPrefService.getPageIconSlots(
      accountName: accountName,
      pageIndex: pageIndex,
    );
    if (!_sameSlots(latest, baseline)) return latest;
  }
  return latest;
}

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
    slots[1] = 'shopping_cart';
    await UserPrefService.setPageIconSlots(
      accountName: account,
      pageIndex: 1,
      slots: slots,
    );

    await tester.pumpWidget(
      MaterialApp(
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

    final iconGridPage = find.byWidgetPredicate((w) {
      if (w.runtimeType.toString() != '_IconGridPage') return false;
      return (w as dynamic).pageIndex == 1;
    });
    final dynamic iconGridState = tester.state(iconGridPage);
    iconGridState.toggleEditModePublic();
    await tester.pumpAndSettle();

    final src = find.byKey(const ValueKey('main_icon_slot_1_0'));
    final dst = find.byKey(const ValueKey('main_icon_slot_1_2'));
    expect(src, findsOneWidget);
    expect(dst, findsOneWidget);

    final beforeSlots = await UserPrefService.getPageIconSlots(
      accountName: account,
      pageIndex: 1,
    );
    expect(beforeSlots[0], 'transactionAdd');

    iconGridState.assignOrSwapPublic('transactionAdd', 2);
    await tester.pumpAndSettle();

    final newSlots = await _waitForSlotChange(
      tester: tester,
      accountName: account,
      pageIndex: 1,
      baseline: beforeSlots,
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
    slots[2] = 'shopping_cart';
    await UserPrefService.setPageIconSlots(
      accountName: account,
      pageIndex: 1,
      slots: slots,
    );

    await tester.pumpWidget(
      MaterialApp(
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

    final iconGridPage = find.byWidgetPredicate((w) {
      if (w.runtimeType.toString() != '_IconGridPage') return false;
      return (w as dynamic).pageIndex == 1;
    });
    final dynamic iconGridState = tester.state(iconGridPage);
    iconGridState.toggleEditModePublic();
    await tester.pumpAndSettle();

    final src = find.byKey(const ValueKey('main_icon_slot_1_0'));
    final dst = find.byKey(const ValueKey('main_icon_slot_1_1'));
    expect(src, findsOneWidget);
    expect(dst, findsOneWidget);

    final beforeSlots = await UserPrefService.getPageIconSlots(
      accountName: account,
      pageIndex: 1,
    );
    expect(beforeSlots[0], 'transactionAdd');

    iconGridState.assignOrSwapPublic('transactionAdd', 1);
    await tester.pumpAndSettle();

    final newSlots = await _waitForSlotChange(
      tester: tester,
      accountName: account,
      pageIndex: 1,
      baseline: beforeSlots,
    );
    expect(newSlots[1], 'transactionAdd');
    expect(newSlots[0], 'daily_transactions');
  });
}
