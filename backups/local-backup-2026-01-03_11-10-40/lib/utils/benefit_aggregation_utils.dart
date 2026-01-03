import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/benefit_memo_utils.dart';

/// Utility to aggregate "benefit" (discount/saving) amounts from transactions.
///
/// Priority (no double counting):
/// 1) cardChargedAmount => benefit = amount - charged
/// 2) benefitJson       => benefit = sum(benefitJson)
/// 3) memo "혜택:"      => benefit = sum(parsed memo)
class BenefitAggregationUtils {
  const BenefitAggregationUtils._();

  /// Memo tag used to mark manual "skipped spend" records.
  ///
  /// These are stored as `TransactionType.savings` with
  /// `SavingsAllocation.assetIncrease`.
  static const String skippedSpendMemoTag = '#참은소비';

  /// Memo tag used to mark manual "saved points" (do-not-spend points) records.
  ///
  /// These are stored as `TransactionType.savings` with
  /// `SavingsAllocation.assetIncrease`.
  static const String savedPointsMemoTag = '#포인트모으기';

  /// Memo tag used to mark manual "round-up" savings records.
  ///
  /// These are stored as `TransactionType.savings` with
  /// `SavingsAllocation.assetIncrease`.
  static const String roundUpMemoTag = '#잔돈모으기';

  static bool isSkippedSpendRecord(Transaction t) {
    if (t.type != TransactionType.savings) return false;
    final alloc = t.savingsAllocation ?? SavingsAllocation.assetIncrease;
    if (alloc != SavingsAllocation.assetIncrease) return false;
    return t.memo.contains(skippedSpendMemoTag);
  }

  static bool isSavedPointsRecord(Transaction t) {
    if (t.type != TransactionType.savings) return false;
    final alloc = t.savingsAllocation ?? SavingsAllocation.assetIncrease;
    if (alloc != SavingsAllocation.assetIncrease) return false;
    return t.memo.contains(savedPointsMemoTag);
  }

  static bool isRoundUpRecord(Transaction t) {
    if (t.type != TransactionType.savings) return false;
    final alloc = t.savingsAllocation ?? SavingsAllocation.assetIncrease;
    if (alloc != SavingsAllocation.assetIncrease) return false;
    return t.memo.contains(roundUpMemoTag);
  }

  static double benefitOf(Transaction t) {
    // Manual "skipped spend" records should be treated as monthly benefits
    // for the 1억 프로젝트 projection.
    if (isSkippedSpendRecord(t)) {
      return t.amount > 0 ? t.amount : 0;
    }

    // Manual "saved points" records should be treated as monthly benefits.
    if (isSavedPointsRecord(t)) {
      return t.amount > 0 ? t.amount : 0;
    }

    // Manual "round-up" records should be treated as monthly benefits.
    if (isRoundUpRecord(t)) {
      return t.amount > 0 ? t.amount : 0;
    }

    if (t.type != TransactionType.expense) return 0;
    if (t.isRefund) return 0;

    final charged = t.cardChargedAmount;
    if (charged != null && charged > 0) {
      final diff = t.amount - charged;
      return diff > 0 ? diff : 0;
    }

    final structured = BenefitMemoUtils.decodeBenefitJson(t.benefitJson);
    if (structured.isNotEmpty) {
      final sum = structured.values.fold<double>(0, (s, v) => s + v);
      return sum > 0 ? sum : 0;
    }

    final memoMap = BenefitMemoUtils.parseBenefitByType(t.memo);
    if (memoMap.isNotEmpty) {
      final sum = memoMap.values.fold<double>(0, (s, v) => s + v);
      return sum > 0 ? sum : 0;
    }

    return 0;
  }

  static double sumBenefit(
    Iterable<Transaction> transactions, {
    DateTime? start,
    DateTime? end,
  }) {
    double total = 0;
    for (final t in transactions) {
      if (start != null && t.date.isBefore(start)) continue;
      if (end != null && t.date.isAfter(end)) continue;
      total += benefitOf(t);
    }
    return total;
  }

  /// Estimates average monthly benefit from a recent lookback window.
  ///
  /// - `lookbackDays`: default 90 days.
  /// - Returns 0 when there is no data.
  static double averageMonthlyBenefit(
    Iterable<Transaction> transactions, {
    int lookbackDays = 90,
    DateTime? now,
  }) {
    final anchor = now ?? DateTime.now();
    final start = anchor.subtract(Duration(days: lookbackDays));

    final total = sumBenefit(transactions, start: start, end: anchor);
    if (total <= 0) return 0;

    final months = (lookbackDays / 30.0).clamp(1.0, double.infinity);
    return total / months;
  }
}
