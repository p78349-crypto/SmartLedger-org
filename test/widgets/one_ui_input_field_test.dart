import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/widgets/one_ui_input_field.dart';

void main() {
  testWidgets('OneUiInputField renders label and hint', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OneUiInputField(
            label: 'Amount',
            hint: 'Enter amount',
          ),
        ),
      ),
    );

    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Enter amount'), findsOneWidget);
  });
}

