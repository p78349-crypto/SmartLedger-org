import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/transaction_button_utils.dart';

void main() {
  group('TransactionButtonUtils', () {
    test('handleGraphToggle returns selectedRangeView when selected', () {
      final r = TransactionButtonUtils.handleGraphToggle<String>(
        isSelected: true,
        selectedRangeView: 'range',
        monthView: 'month',
        chartView: 'chart',
      );
      expect(r, 'range');
    });

    test('handleGraphToggle falls back to monthView when selectedRangeView is null', () {
      final r = TransactionButtonUtils.handleGraphToggle<String>(
        isSelected: true,
        selectedRangeView: null,
        monthView: 'month',
        chartView: 'chart',
      );
      expect(r, 'month');
    });

    test('handleGraphToggle returns chartView when not selected', () {
      final r = TransactionButtonUtils.handleGraphToggle<String>(
        isSelected: false,
        selectedRangeView: 'range',
        monthView: 'month',
        chartView: 'chart',
      );
      expect(r, 'chart');
    });

    test('handleTransactionTypeToggle sets index/month and toggles state', () {
      final typeOrder = <TransactionType>[TransactionType.expense, TransactionType.income];

      int? setIndex;
      DateTime? setMonth;
      TransactionType? toggledType;
      String? toggledView;

      TransactionButtonUtils.handleTransactionTypeToggle<String>(
        type: TransactionType.income,
        typeOrder: typeOrder,
        detailViewForTransaction: (t) => 'view_${t.name}',
        toggleDetailState: (t, v) {
          toggledType = t;
          toggledView = v;
        },
        setTypeIndex: (i) => setIndex = i,
        setCurrentMonth: (d) => setMonth = d,
      );

      expect(setIndex, 1);
      expect(setMonth, isNotNull);
      expect(setMonth!.day, 1);
      expect(toggledType, TransactionType.income);
      expect(toggledView, 'view_income');
    });
  });
}
