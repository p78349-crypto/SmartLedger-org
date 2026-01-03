import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/icon_management_screen.dart';
import 'package:smart_ledger/services/user_pref_service.dart';
import 'package:smart_ledger/utils/page1_bottom_quick_icons.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  const accountName = 'test_account_picker';

  testWidgets(
    'tapping empty slot in icon management assigns multiple icons (apply)',
    (WidgetTester tester) async {
      // Start with all empty slots, and mark target icons as hidden.
      await UserPrefService.setPageIconSlots(
        accountName: accountName,
        pageIndex: 0,
        slots: List<String>.filled(Page1BottomQuickIcons.slotCount, ''),
      );

      await UserPrefService.setPageIconSettings(
        accountName: accountName,
        pageIndex: 0,
        order: const <String>[],
      );

      await tester.pumpWidget(
        const MaterialApp(home: IconManagementScreen(accountName: accountName)),
      );
      await tester.pumpAndSettle();

      // Select two icons from the catalog grid.
      // Icon catalog is inside a ListView, so we must scroll to build it.

      final icon1 = find.byKey(
        const ValueKey('icon_mgmt_catalog_transactionAdd'),
      );
      final icon2 = find.byKey(
        const ValueKey('icon_mgmt_catalog_accountStats'),
      );
      await tester.scrollUntilVisible(
        icon1,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(icon1, findsOneWidget);
      expect(icon2, findsOneWidget);

      await tester.scrollUntilVisible(
        icon1,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(icon1, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        icon2,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(icon2, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Apply selection.
      await tester.tap(find.text('ENT'));
      await tester.pumpAndSettle();

      // Slots should now contain at least two non-empty (batch apply)
      final slots = await UserPrefService.getPageIconSlots(
        accountName: accountName,
        pageIndex: 0,
      );
      expect(slots.where((s) => s.isNotEmpty).length, greaterThanOrEqualTo(2));
    },
  );

  testWidgets('icon management ENT is disabled until selection', (
    WidgetTester tester,
  ) async {
    await UserPrefService.setPageIconSlots(
      accountName: accountName,
      pageIndex: 0,
      slots: List<String>.filled(Page1BottomQuickIcons.slotCount, ''),
    );
    await UserPrefService.setPageIconSettings(
      accountName: accountName,
      pageIndex: 0,
      order: const <String>[],
    );

    await tester.pumpWidget(
      const MaterialApp(home: IconManagementScreen(accountName: accountName)),
    );
    await tester.pumpAndSettle();

    final entFinder = find.widgetWithText(OutlinedButton, 'ENT');
    expect(entFinder, findsOneWidget);

    final entButton = tester.widget<OutlinedButton>(entFinder);
    expect(entButton.onPressed, isNull);

    final icon = find.byKey(const ValueKey('icon_mgmt_catalog_transactionAdd'));
    await tester.scrollUntilVisible(
      icon,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(icon, findsOneWidget);
    await tester.tap(icon, warnIfMissed: false);
    await tester.pumpAndSettle();

    final entButtonAfter = tester.widget<OutlinedButton>(entFinder);
    expect(entButtonAfter.onPressed, isNotNull);
  });
}
