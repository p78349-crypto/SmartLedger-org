import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/utils_example.dart';

void main() {
  testWidgets('UtilsExampleScreen builds and shows title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UtilsExampleScreen(),
      ),
    );

    expect(find.text('Utils 사용 예시'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });
}
