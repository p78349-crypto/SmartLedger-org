import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/transaction_aggregation_utils.dart';

void main() {
  group('TransactionAggregationUtils', () {
    Transaction tx({
      required String id,
      required TransactionType type,
      required double amount,
      SavingsAllocation? savingsAllocation,
      bool isRefund = false,
    }) {
      return Transaction(
        id: id,
        type: type,
        description: id,
        amount: amount,
        date: DateTime(2026),
        savingsAllocation: savingsAllocation,
        isRefund: isRefund,
      );
    }

    test(
      'isSavingsCountedAsExpense respects allocation with default fallback',
      () {
        final assetSaving = tx(
          id: 's1',
          type: TransactionType.savings,
          amount: 100,
          savingsAllocation: SavingsAllocation.assetIncrease,
        );
        final expenseSaving = tx(
          id: 's2',
          type: TransactionType.savings,
          amount: 100,
          savingsAllocation: SavingsAllocation.expense,
        );
        final defaultSaving = tx(
          id: 's3',
          type: TransactionType.savings,
          amount: 100,
        );

        expect(
          TransactionAggregationUtils.isSavingsCountedAsExpense(assetSaving),
          isFalse,
        );
        expect(
          TransactionAggregationUtils.isSavingsCountedAsExpense(expenseSaving),
          isTrue,
        );
        expect(
          TransactionAggregationUtils.isSavingsCountedAsExpense(defaultSaving),
          isFalse,
        );
      },
    );

    test('outflowAmount follows expense-like classification', () {
      expect(
        TransactionAggregationUtils.outflowAmount(
          tx(id: 'e1', type: TransactionType.expense, amount: 250),
        ),
        250,
      );

      expect(
        TransactionAggregationUtils.outflowAmount(
          tx(
            id: 'e2',
            type: TransactionType.expense,
            amount: 80,
            isRefund: true,
          ),
        ),
        -80,
      );

      expect(
        TransactionAggregationUtils.outflowAmount(
          tx(
            id: 's1',
            type: TransactionType.savings,
            amount: 60,
            savingsAllocation: SavingsAllocation.expense,
          ),
        ),
        60,
      );

      expect(
        TransactionAggregationUtils.outflowAmount(
          tx(
            id: 's2',
            type: TransactionType.savings,
            amount: 60,
            savingsAllocation: SavingsAllocation.assetIncrease,
          ),
        ),
        0,
      );
    });

    test('shouldAggregateForType supports income-refund option', () {
      final refundTx = tx(id: 'r1', type: TransactionType.refund, amount: 20);

      expect(
        TransactionAggregationUtils.shouldAggregateForType(
          refundTx,
          TransactionType.income,
        ),
        isFalse,
      );

      expect(
        TransactionAggregationUtils.shouldAggregateForType(
          refundTx,
          TransactionType.income,
          includeRefundInIncome: true,
        ),
        isTrue,
      );
    });
  });
}
