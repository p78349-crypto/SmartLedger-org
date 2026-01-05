import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/account_main_screen.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AccountMainScreen shows slot grid keys', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AccountMainScreen(
          accountName: 'test_account_slots_removed',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final slot0Finder = find.byKey(
      const ValueKey('main_icon_slot_0_0'),
      skipOffstage: false,
    );
    final slot11Finder = find.byKey(
      const ValueKey('main_icon_slot_0_11'),
      skipOffstage: false,
    );

    expect(slot0Finder, findsOneWidget);
    expect(slot11Finder, findsOneWidget);
  });
}
