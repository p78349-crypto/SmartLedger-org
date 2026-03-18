import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/screens/transaction_add_detailed_screen.dart';
import 'package:smart_ledger/services/transaction_service.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

Future<void> _enterByKey(WidgetTester tester, String key, String value) async {
  final field = find.byKey(Key(key));
  expect(field, findsOneWidget);
  final editable = find.descendant(
    of: field,
    matching: find.byType(EditableText),
  );
  expect(editable, findsOneWidget);
  await tester.enterText(editable, value);
  await tester.pumpAndSettle();
}

String _readTextByKey(WidgetTester tester, String key) {
  final field = find.byKey(Key(key));
  final editable = find.descendant(
    of: field,
    matching: find.byType(EditableText),
  );
  expect(editable, findsOneWidget);
  final widget = tester.widget<EditableText>(editable);
  return widget.controller.text;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'detailed expense comma unit input auto-calculates and saves consistently',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefKeys.txStorageBackendV1: 'prefs',
      });

      final service = TransactionService();
      await service.loadTransactions();
      final accountName =
          'detailed_parse_${DateTime.now().microsecondsSinceEpoch}';

      await tester.pumpWidget(
        MaterialApp(
          home: TransactionAddDetailedScreen(accountName: accountName),
        ),
      );
      await tester.pumpAndSettle();

      await _enterByKey(tester, 'tx_desc', '우유');
      await _enterByKey(tester, 'tx_unit_price', '1,300');
      await _enterByKey(tester, 'tx_qty', '3');
      await _enterByKey(tester, 'tx_payment', '카드');

      expect(_readTextByKey(tester, 'tx_amount'), '3900');

      await tester.tap(find.byTooltip('저장').first);
      await tester.pumpAndSettle();

      final saved = service.getTransactions(accountName);
      expect(saved.length, 1);
      expect(saved.first.amount, 3900);
      expect(saved.first.unitPrice, 1300);
      expect(saved.first.quantity, 3);
      expect(saved.first.paymentMethod, '카드');
    },
  );

  testWidgets('detailed draft card amount parses and saves consistently', (
    tester,
  ) async {
    final accountName =
        'detailed_card_${DateTime.now().microsecondsSinceEpoch}';
    final draftKey = PrefKeys.accountKey(accountName, 'tx_draft_v1');
    final draft = <String, dynamic>{
      'ts': DateTime.now().millisecondsSinceEpoch,
      'desc': '계란',
      'qty': '2',
      'unitPrice': '2,500',
      'amount': '5000',
      'card': '10,000',
      'payment': '카드',
      'type': 'expense',
    };

    SharedPreferences.setMockInitialValues(<String, Object>{
      PrefKeys.txStorageBackendV1: 'prefs',
      draftKey: jsonEncode(draft),
    });

    final service = TransactionService();
    await service.loadTransactions();

    await tester.pumpWidget(
      MaterialApp(home: TransactionAddDetailedScreen(accountName: accountName)),
    );
    await tester.pumpAndSettle();

    expect(_readTextByKey(tester, 'tx_desc'), '계란');
    expect(_readTextByKey(tester, 'tx_amount'), '5000');
    expect(_readTextByKey(tester, 'tx_payment'), '카드');

    await tester.tap(find.byTooltip('저장').first);
    await tester.pumpAndSettle();

    final saved = service.getTransactions(accountName);
    expect(saved.length, 1);
    expect(saved.first.amount, 5000);
    expect(saved.first.unitPrice, 2500);
    expect(saved.first.quantity, 2);
    expect(saved.first.cardChargedAmount, 10000);
  });

  testWidgets(
    'detailed draft card amount with currency symbols saves consistently',
    (tester) async {
      final accountName =
          'detailed_card_symbol_${DateTime.now().microsecondsSinceEpoch}';
      final draftKey = PrefKeys.accountKey(accountName, 'tx_draft_v1');
      final draft = <String, dynamic>{
        'ts': DateTime.now().millisecondsSinceEpoch,
        'desc': '치즈',
        'qty': '1',
        'unitPrice': '5,000',
        'amount': '5000',
        'card': '₩ 10,000원',
        'payment': '카드',
        'type': 'expense',
      };

      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefKeys.txStorageBackendV1: 'prefs',
        draftKey: jsonEncode(draft),
      });

      final service = TransactionService();
      await service.loadTransactions();

      await tester.pumpWidget(
        MaterialApp(
          home: TransactionAddDetailedScreen(accountName: accountName),
        ),
      );
      await tester.pumpAndSettle();

      expect(_readTextByKey(tester, 'tx_desc'), '치즈');
      expect(_readTextByKey(tester, 'tx_amount'), '5000');
      expect(_readTextByKey(tester, 'tx_payment'), '카드');

      await tester.tap(find.byTooltip('저장').first);
      await tester.pumpAndSettle();

      final saved = service.getTransactions(accountName);
      expect(saved.length, 1);
      expect(saved.first.amount, 5000);
      expect(saved.first.unitPrice, 5000);
      expect(saved.first.quantity, 1);
      expect(saved.first.cardChargedAmount, 10000);
    },
  );

  testWidgets('detailed draft invalid card amounts block save', (tester) async {
    for (final invalidCard in ['0', '-100', 'abc']) {
      final accountName =
          'detailed_card_invalid_${invalidCard}_${DateTime.now().microsecondsSinceEpoch}';
      final draftKey = PrefKeys.accountKey(accountName, 'tx_draft_v1');
      final draft = <String, dynamic>{
        'ts': DateTime.now().millisecondsSinceEpoch,
        'desc': '빵',
        'qty': '1',
        'unitPrice': '2,000',
        'amount': '2000',
        'card': invalidCard,
        'payment': '카드',
        'type': 'expense',
      };

      SharedPreferences.setMockInitialValues(<String, Object>{
        PrefKeys.txStorageBackendV1: 'prefs',
        draftKey: jsonEncode(draft),
      });

      final service = TransactionService();
      await service.loadTransactions();

      await tester.pumpWidget(
        MaterialApp(
          home: TransactionAddDetailedScreen(accountName: accountName),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('저장').first);
      await tester.pumpAndSettle();

      final saved = service.getTransactions(accountName);
      expect(
        saved,
        isEmpty,
        reason: 'invalid card=$invalidCard should block save',
      );
    }
  });
}
