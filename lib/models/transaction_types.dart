enum TransactionType { expense, income, savings, refund }

enum SavingsAllocation { assetIncrease, expense }

extension TransactionTypeX on TransactionType {
  String get label {
    switch (this) {
      case TransactionType.expense:
        return '지출';
      case TransactionType.income:
        return '수입';
      case TransactionType.savings:
        return '예금';
      case TransactionType.refund:
        return '반품';
    }
  }

  String get longLabel {
    switch (this) {
      case TransactionType.expense:
        return '지출';
      case TransactionType.income:
        return '수입';
      case TransactionType.savings:
        return '예금(저금통)';
      case TransactionType.refund:
        return '반품';
    }
  }

  bool get isInflow =>
      this == TransactionType.income || this == TransactionType.refund;

  bool get isOutflow => !isInflow;

  String get sign {
    switch (this) {
      case TransactionType.expense:
        return '-';
      case TransactionType.income:
        return '+';
      case TransactionType.savings:
        return '-';
      case TransactionType.refund:
        return '+';
    }
  }
}

extension SavingsAllocationX on SavingsAllocation {
  String get label {
    switch (this) {
      case SavingsAllocation.assetIncrease:
        return '자산 증가';
      case SavingsAllocation.expense:
        return '지출';
    }
  }

  String get helperText {
    switch (this) {
      case SavingsAllocation.assetIncrease:
        return '정해진 날짜에 자동 반영됩니다.';
      case SavingsAllocation.expense:
        return '해당 금액이 지출 통계에 포함됩니다.';
    }
  }

  String get snackBarDetail {
    switch (this) {
      case SavingsAllocation.assetIncrease:
        return '자산 증가로 반영';
      case SavingsAllocation.expense:
        return '지출로 반영';
    }
  }
}
