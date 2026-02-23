import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/transaction_add_screen.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

Future<void> _enterByKey(
  WidgetTester tester,
  String key,
  String value,
) async {
  final field = find.byKey(Key(key));
  expect(field, findsOneWidget);
  final textField = find.descendant(
    of: field,
    matching: find.byType(TextFormField),
  );
  await tester.enterText(textField, value);
  await tester.pumpAndSettle();
}

String _readTextByKey(WidgetTester tester, String key) {
  final field = find.byKey(Key(key));
  final textField = find.descendant(
    of: field,
    matching: find.byType(TextFormField),
  );
  final widget = tester.widget<TextFormField>(textField);
  return widget.controller?.text ?? '';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('expense comma unit input auto-calculates and saves consistently', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PrefKeys.txStorageBackendV1: 'prefs',
    });

    final service = TransactionService();
    await service.loadTransactions();
    final accountName =
        'parse_account_${DateTime.now().microsecondsSinceEpoch}';

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionAddScreen(accountName: accountName),
      ),
    );
    await tester.pumpAndSettle();

    await _enterByKey(tester, 'tx_desc', '닭고기');
    await _enterByKey(tester, 'tx_unit', '1,200');
    await _enterByKey(tester, 'tx_qty', '2');
    await _enterByKey(tester, 'tx_payment', '카드');

    expect(_readTextByKey(tester, 'tx_amount'), '2400');

    await tester.tap(find.byTooltip('저장').first);
    await tester.pumpAndSettle();

    final saved = service.getTransactions(accountName);
    expect(saved.length, 1);
    expect(saved.first.amount, 2400);
    expect(saved.first.unitPrice, 1200);
    expect(saved.first.quantity, 2);
    expect(saved.first.paymentMethod, '카드');
  });

  testWidgets('expense currency-symbol unit input auto-calculates and saves consistently', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PrefKeys.txStorageBackendV1: 'prefs',
    });

    final service = TransactionService();
    await service.loadTransactions();
    final accountName =
        'parse_symbol_account_${DateTime.now().microsecondsSinceEpoch}';

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionAddScreen(accountName: accountName),
      ),
    );
    await tester.pumpAndSettle();

    await _enterByKey(tester, 'tx_desc', '소고기');
    await _enterByKey(tester, 'tx_unit', '₩ 1,200원');
    await _enterByKey(tester, 'tx_qty', '3');
    await _enterByKey(tester, 'tx_payment', '카드');

    expect(_readTextByKey(tester, 'tx_amount'), '3600');

    await tester.tap(find.byTooltip('저장').first);
    await tester.pumpAndSettle();

    final saved = service.getTransactions(accountName);
    expect(saved.length, 1);
    expect(saved.first.amount, 3600);
    expect(saved.first.unitPrice, 1200);
    expect(saved.first.quantity, 3);
    expect(saved.first.paymentMethod, '카드');
  });
}
