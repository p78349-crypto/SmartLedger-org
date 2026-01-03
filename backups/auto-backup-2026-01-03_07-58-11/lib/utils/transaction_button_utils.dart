import 'package:smart_ledger/models/transaction.dart';

class TransactionButtonUtils {
  static void handleTransactionTypeToggle<T>({
    required TransactionType type,
    required T Function(TransactionType) detailViewForTransaction,
    required void Function(TransactionType, T) toggleDetailState,
    required Function(int) setTypeIndex,
    required Function(DateTime) setCurrentMonth,
    required List<TransactionType> typeOrder,
  }) {
    final index = typeOrder.indexOf(type);
    if (index == -1) return;

    setTypeIndex(index);
    setCurrentMonth(DateTime(DateTime.now().year, DateTime.now().month));
    toggleDetailState(type, detailViewForTransaction(type));
  }

  static T handleGraphToggle<T>({
    required bool isSelected,
    required T? selectedRangeView,
    required T monthView,
    required T chartView,
  }) {
    return isSelected ? (selectedRangeView ?? monthView) : chartView;
  }
}

