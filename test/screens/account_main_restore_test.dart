import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/account_main_screen.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AccountMainScreen builds (no hide/restore feature)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AccountMainScreen(
          accountName: 'test_account_restore_removed',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AccountMainScreen), findsOneWidget);
  });
}
