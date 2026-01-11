import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_ledger/utils/screen_saver_launcher.dart';
import 'package:smart_ledger/widgets/in_app_screen_saver.dart';

void main() {
  testWidgets('ScreenSaverLauncher.show displays InAppScreenSaver dialog', (tester) async {
    await initializeDateFormatting('ko_KR');

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () {
                  ScreenSaverLauncher.show(
                    context: context,
                    accountName: 'acc1',
                    title: 't',
                  );
                },
                child: const Text('open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    // InAppScreenSaver updates time periodically, so the tree may never fully
    // settle. Pump a few frames to allow the dialog animation to appear.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(InAppScreenSaver), findsOneWidget);

    // Dismiss via navigator pop (acts like barrier dismiss in tests).
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(InAppScreenSaver), findsNothing);
  });
}
