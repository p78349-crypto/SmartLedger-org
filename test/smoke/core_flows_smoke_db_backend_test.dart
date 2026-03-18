import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/database/app_database.dart';
import 'package:smart_ledger/database/database_provider.dart';
import 'package:smart_ledger/screens/account_stats_screen.dart';
import 'package:smart_ledger/screens/transaction_add_screen.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/pref_keys.dart';
import 'package:smart_ledger/widgets/asset_route_auth_gate.dart';
import 'package:smart_ledger/widgets/root_auth_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SMOKE(DB+AUTH): RootAuthGate bypass opens child in DB mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PrefKeys.txStorageBackendV1: 'db',
      PrefKeys.bypassSecurityForTesting: true,
      PrefKeys.rootAuthEnabled: true,
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: RootAuthGate(child: Scaffold(body: Text('ROOT_DB_OPEN'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ROOT_DB_OPEN'), findsOneWidget);
  });

  testWidgets(
    'SMOKE(DB+AUTH): AssetRouteAuthGate bypass opens child in DB mode',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefKeys.txStorageBackendV1: 'db',
        PrefKeys.bypassSecurityForTesting: true,
        PrefKeys.assetAuthEnabled: true,
        PrefKeys.assetAuthRequired: true,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AssetRouteAuthGate(
            child: Scaffold(body: Text('ASSET_DB_OPEN')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ASSET_DB_OPEN'), findsOneWidget);
    },
  );

  testWidgets(
    'SMOKE(DB): Transaction save reflects in AccountStatsScreen summary',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefKeys.txStorageBackendV1: 'db',
      });

      // Use in-memory DB for tests to avoid platform-specific background open.
      DatabaseProvider.instance.overrideForTesting(
        AppDatabase.connect(NativeDatabase.memory()),
      );

      final service = TransactionService()..resetForTesting();
      await service.loadTransactions();
      final accountName =
          'smoke_db_stats_${DateTime.now().microsecondsSinceEpoch}';

      await tester.pumpWidget(
        MaterialApp(home: TransactionAddScreen(accountName: accountName)),
      );
      await tester.pumpAndSettle();

      Future<void> enterTextField(String key, String value) async {
        final field = find.byKey(Key(key));
        expect(field, findsOneWidget);
        final textField = find.descendant(
          of: field,
          matching: find.byType(TextFormField),
        );
        await tester.enterText(textField, value);
        await tester.pumpAndSettle();
      }

      await enterTextField('tx_desc', 'DB통계반영');
      await enterTextField('tx_unit', '1,300');
      await enterTextField('tx_qty', '2');
      await enterTextField('tx_payment', '카드');

      await tester.tap(find.byTooltip('저장').first);
      await tester.pumpAndSettle();

      // Ensure TransactionService sees the saved transaction.
      final saved = service.getTransactions(accountName);
      expect(saved, isNotEmpty);

      final expectedExpense = '-${NumberFormats.currency.format(2600)}원';

      await tester.pumpWidget(
        MaterialApp(home: AccountStatsScreen(accountName: accountName)),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      for (var i = 0; i < 20; i++) {
        if (find.text(expectedExpense).evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text(expectedExpense), findsWidgets);
    },
  );
}
