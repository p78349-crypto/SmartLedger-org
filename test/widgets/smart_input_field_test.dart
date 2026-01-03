import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/widgets/smart_input_field.dart';

void main() {
  testWidgets('SmartInputField renders label and hint', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SmartInputField(label: 'Amount', hint: 'Enter amount'),
        ),
      ),
    );

    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Enter amount'), findsOneWidget);
  });
}
