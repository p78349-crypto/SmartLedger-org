import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/localization.dart';

void main() {
  group('AppStrings', () {
    test('basic labels are stable', () {
      expect(AppStrings.buttonAdd, isNotEmpty);
      expect(AppStrings.buttonDelete, isNotEmpty);
      expect(AppStrings.buttonCancel, isNotEmpty);
      expect(AppStrings.messageEmpty, isNotEmpty);
    });

    test('transaction type strings are defined', () {
      expect(AppStrings.transactionTypeExpense, isNotEmpty);
      expect(AppStrings.transactionTypeIncome, isNotEmpty);
      expect(AppStrings.transactionTypeSavings, isNotEmpty);
    });
  });
}
