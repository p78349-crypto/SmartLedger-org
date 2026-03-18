import '../models/transaction.dart';

class TransactionAggregationUtils {
  static SavingsAllocation savingsAllocationOf(Transaction tx) {
    return tx.savingsAllocation ?? SavingsAllocation.assetIncrease;
  }

  static bool isSavingsCountedAsExpense(Transaction tx) {
    if (tx.type != TransactionType.savings) return false;
    return savingsAllocationOf(tx) == SavingsAllocation.expense;
  }

  static double outflowAmount(Transaction tx) {
    switch (tx.type) {
      case TransactionType.expense:
        final amount = tx.amount.abs();
        return tx.isRefund ? -amount : amount;
      case TransactionType.savings:
        return isSavingsCountedAsExpense(tx) ? tx.amount.abs() : 0;
      case TransactionType.income:
      case TransactionType.refund:
        return 0;
    }
  }

  static bool isExpenseLikeOutflow(Transaction tx) {
    return outflowAmount(tx) > 0;
  }

  static bool shouldAggregateForType(
    Transaction tx,
    TransactionType type, {
    bool includeRefundInIncome = false,
  }) {
    switch (type) {
      case TransactionType.expense:
        return tx.type == TransactionType.expense ||
            isSavingsCountedAsExpense(tx);
      case TransactionType.income:
        return tx.type == TransactionType.income ||
            (includeRefundInIncome && tx.type == TransactionType.refund);
      case TransactionType.refund:
        return tx.type == TransactionType.refund;
      case TransactionType.savings:
        return tx.type == TransactionType.savings &&
            !isSavingsCountedAsExpense(tx);
    }
  }
}
