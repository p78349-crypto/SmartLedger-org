import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/utils/backup_password_bootstrapper.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

void main() {
  testWidgets('ensureBackupPasswordConfiguredOnEntry returns early when encryption disabled', (tester) async {
    SharedPreferences.setMockInitialValues({
      PrefKeys.backupEncryptionEnabled: false,
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.shrink(),
        ),
      ),
    );

    final context = tester.element(find.byType(SizedBox));
    await BackupPasswordBootstrapper.ensureBackupPasswordConfiguredOnEntry(context);
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
