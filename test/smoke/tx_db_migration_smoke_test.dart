import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/database/app_database.dart';
import 'package:smart_ledger/database/database_provider.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/screens/account_stats_screen.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/number_formats.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SMOKE(MIG): legacy prefs JSON migrates into DB on load', (
    tester,
  ) async {
    // Use in-memory DB for tests.
    DatabaseProvider.instance.overrideForTesting(
      AppDatabase.connect(NativeDatabase.memory()),
    );

    final accountName = 'mig_${DateTime.now().microsecondsSinceEpoch}';
    final tx = Transaction(
      id: 'm1',
      type: TransactionType.expense,
      description: 'legacy',
      amount: 2600,
      date: DateTime.now(),
      unitPrice: 1300,
      quantity: 2,
      paymentMethod: '카드',
    );

    SharedPreferences.setMockInitialValues(<String, Object>{
      // Force DB backend so TransactionService triggers migration.
      PrefKeys.txStorageBackendV1: 'db',
      // Legacy prefs payload.
      PrefKeys.transactions: jsonEncode(<String, Object>{
        accountName: <Object>[tx.toJson()],
      }),
      // Ensure migration will run.
      PrefKeys.txDbMigratedV1: false,
    });

    final service = TransactionService()..resetForTesting();
    await service.loadTransactions();

    final migrated = service.getTransactions(accountName);
    expect(migrated.length, 1);
    expect(migrated.first.amount, 2600);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PrefKeys.txDbMigratedV1), isTrue);

    // Optional UI verification: stats summary reflects the migrated amount.
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
  });
}
