part of 'monthly_agg_cache_service.dart';

class _BucketAccumulator {
  final String yearMonth;

  double incomeAmount = 0;
  int incomeCount = 0;

  double refundAmount = 0;
  int refundCount = 0;

  double expenseAggAmount = 0;
  int expenseAggCount = 0;

  double expenseOnlyAmount = 0;
  int expenseOnlyCount = 0;

  double savingsTotalAmount = 0;
  int savingsTotalCount = 0;

  double savingsExpenseAmount = 0;
  int savingsExpenseCount = 0;

  double memoOutflowAmountAbs = 0;
  int memoOutflowCount = 0;

  double quickInputAmount = 0;
  int quickInputCount = 0;

  double cardDiscountAmount = 0;
  int cardDiscountCount = 0;

  _BucketAccumulator(this.yearMonth);

  bool _isSavingsCountedAsExpense(Transaction tx) {
    if (tx.type != TransactionType.savings) return false;
    final alloc = tx.savingsAllocation ?? SavingsAllocation.assetIncrease;
    return alloc == SavingsAllocation.expense;
  }

  void applyTransaction(Transaction tx) {
    switch (tx.type) {
      case TransactionType.income:
        incomeAmount += tx.amount;
        incomeCount += 1;
        break;
      case TransactionType.refund:
        refundAmount += tx.amount;
        refundCount += 1;
        incomeAmount += tx.amount;
        incomeCount += 1;
        break;
      case TransactionType.expense:
        expenseOnlyAmount += tx.amount;
        expenseOnlyCount += 1;
        expenseAggAmount += tx.amount;
        expenseAggCount += 1;

        final charged = tx.cardChargedAmount;
        if (charged != null) {
          final baseAbs = tx.amount.abs();
          final discount = baseAbs - charged.abs();
          if (discount > 0) {
            cardDiscountAmount += discount;
            cardDiscountCount += 1;
          }
        }
        break;
      case TransactionType.savings:
        savingsTotalAmount += tx.amount;
        savingsTotalCount += 1;
        if (_isSavingsCountedAsExpense(tx)) {
          savingsExpenseAmount += tx.amount;
          savingsExpenseCount += 1;
          expenseAggAmount += tx.amount;
          expenseAggCount += 1;
        }
        break;
    }

    final memo = tx.memo.trim();
    if (memo.isNotEmpty && tx.type.isOutflow) {
      memoOutflowCount += 1;
      memoOutflowAmountAbs += tx.amount.abs();
    }
  }

  MonthlyAggBucket build() {
    return MonthlyAggBucket(
      yearMonth: yearMonth,
      incomeAmount: incomeAmount,
      incomeCount: incomeCount,
      refundAmount: refundAmount,
      refundCount: refundCount,
      expenseAggAmount: expenseAggAmount,
      expenseAggCount: expenseAggCount,
      expenseOnlyAmount: expenseOnlyAmount,
      expenseOnlyCount: expenseOnlyCount,
      savingsTotalAmount: savingsTotalAmount,
      savingsTotalCount: savingsTotalCount,
      savingsExpenseAmount: savingsExpenseAmount,
      savingsExpenseCount: savingsExpenseCount,
      memoOutflowAmountAbs: memoOutflowAmountAbs,
      memoOutflowCount: memoOutflowCount,
      quickInputAmount: quickInputAmount,
      quickInputCount: quickInputCount,
      cardDiscountAmount: cardDiscountAmount,
      cardDiscountCount: cardDiscountCount,
    );
  }
}
