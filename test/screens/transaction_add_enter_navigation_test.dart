import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/screens/transaction_add_screen.dart';

void main() {
  testWidgets('Income: Enter moves desc->amount->payment->memo', (
    tester,
  ) async {
    final tx = Transaction(
      id: 't1',
      type: TransactionType.income,
      description: '',
      amount: 0,
      date: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionAddScreen(accountName: 'a', initialTransaction: tx),
      ),
    );
    await tester.pumpAndSettle();

    final descField = find.byKey(const Key('tx_desc'));
    final amountField = find.byKey(const Key('tx_amount'));
    final paymentField = find.byKey(const Key('tx_payment'));
    final memoField = find.byKey(const Key('tx_memo'));

    expect(descField, findsOneWidget);
    expect(amountField, findsOneWidget);
    expect(paymentField, findsOneWidget);
    expect(memoField, findsOneWidget);

    // Focus desc and press Next
    final descTextField = find.descendant(
      of: descField,
      matching: find.byType(TextFormField),
    );
    await tester.tap(descTextField);
    await tester.pumpAndSettle();
    await tester.enterText(descTextField, '월급');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    final amtEditable = find.descendant(
      of: amountField,
      matching: find.byType(EditableText),
    );
    final amtWidget = tester.widget<EditableText>(amtEditable);
    expect(amtWidget.focusNode.hasFocus, isTrue);

    // Press next from amount -> payment
    await tester.enterText(amtEditable, '1000000');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    final payEditable = find.descendant(
      of: paymentField,
      matching: find.byType(EditableText),
    );
    final payWidget = tester.widget<EditableText>(payEditable);
    expect(payWidget.focusNode.hasFocus, isTrue);

    // Press next from payment -> memo
    await tester.enterText(payEditable, '계좌');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    final memoEditable = find.descendant(
      of: memoField,
      matching: find.byType(EditableText),
    );
    final memoWidget = tester.widget<EditableText>(memoEditable);
    expect(memoWidget.focusNode.hasFocus, isTrue);
  });

  testWidgets('Expense: Enter moves desc->unit->qty->payment', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TransactionAddScreen(accountName: 'a')),
    );
    await tester.pumpAndSettle();

    final descField = find.byKey(const Key('tx_desc'));
    final unitField = find.byKey(const Key('tx_unit'));
    final qtyField = find.byKey(const Key('tx_qty'));
    final paymentField = find.byKey(const Key('tx_payment'));

    expect(descField, findsOneWidget);
    expect(unitField, findsOneWidget);
    expect(qtyField, findsOneWidget);
    expect(paymentField, findsOneWidget);

    final descTextField = find.descendant(
      of: descField,
      matching: find.byType(TextFormField),
    );
    await tester.tap(descTextField);
    await tester.pumpAndSettle();
    await tester.enterText(descTextField, '닭고기');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    final unitEditable = find.descendant(
      of: unitField,
      matching: find.byType(EditableText),
    );
    final unitWidget = tester.widget<EditableText>(unitEditable);
    expect(unitWidget.focusNode.hasFocus, isTrue);

    // Enter valid unit and press next -> qty should have focus
    await tester.enterText(unitEditable, '1200');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    final qtyEditable = find.descendant(
      of: qtyField,
      matching: find.byType(EditableText),
    );
    final qtyWidget = tester.widget<EditableText>(qtyEditable);
    expect(qtyWidget.focusNode.hasFocus, isTrue);

    // Enter qty and press next -> payment should have focus
    await tester.enterText(qtyEditable, '2');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();

    final payEditable = find.descendant(
      of: paymentField,
      matching: find.byType(EditableText),
    );
    final payWidget = tester.widget<EditableText>(payEditable);
    expect(payWidget.focusNode.hasFocus, isTrue);
  });
}
