import '../models/transaction.dart';
import '../utils/benefit_memo_utils.dart';

/// 검색 쿼리의 파싱 결과.
class TxSearchPlan {
  final String ftsQuery;
  final TxSearchFilters filters;
  const TxSearchPlan({required this.ftsQuery, required this.filters});
}

/// 검색 필터 모델.
class TxSearchFilters {
  final Set<TransactionType> types = <TransactionType>{};
  final List<String> paymentContains = <String>[];
  final List<String> storeContains = <String>[];
  final List<String> categoryContains = <String>[];
  final List<String> descriptionContains = <String>[];
  final List<String> memoContains = <String>[];
  double? minAmountAbs;
  double? maxAmountAbs;
  DateTime? startDate;
  DateTime? endDate;
  bool benefitOnly = false;
  bool pointsOnly = false;
  double? minBenefit;
  double? maxBenefit;

  /// 시뮬레이션 표시 전용 (매칭에 영향 없음).
  double? annualRatePercent;

  bool get hasAny {
    return types.isNotEmpty ||
        paymentContains.isNotEmpty ||
        storeContains.isNotEmpty ||
        categoryContains.isNotEmpty ||
        descriptionContains.isNotEmpty ||
        memoContains.isNotEmpty ||
        minAmountAbs != null ||
        maxAmountAbs != null ||
        startDate != null ||
        endDate != null ||
        benefitOnly ||
        pointsOnly ||
        minBenefit != null ||
        maxBenefit != null ||
        annualRatePercent != null;
  }
}

/// 거래의 혜택별 금액 반환.
Map<String, double> benefitByTypeForSearch(Transaction tx) {
  final fromJson = tx.benefitByType;
  if (fromJson.isNotEmpty) return fromJson;
  return BenefitMemoUtils.parseBenefitByType(tx.memo);
}

/// [needles] 모두가 [haystack]에 포함되는지 확인.
bool matchesAllContains(String haystack, List<String> needles) {
  final lower = haystack.toLowerCase();
  for (final n in needles) {
    if (!lower.contains(n.toLowerCase().trim())) {
      return false;
    }
  }
  return true;
}

/// 거래가 검색 필터 조건에 맞는지 확인.
bool matchesTxFilters(Transaction tx, TxSearchFilters f) {
  if (f.types.isNotEmpty && !f.types.contains(tx.type)) {
    return false;
  }
  if (f.minAmountAbs != null || f.maxAmountAbs != null) {
    final v = tx.amount.abs();
    if (f.minAmountAbs != null && v < f.minAmountAbs!) {
      return false;
    }
    if (f.maxAmountAbs != null && v > f.maxAmountAbs!) {
      return false;
    }
  }
  if (f.startDate != null || f.endDate != null) {
    final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
    if (f.startDate != null) {
      final s = DateTime(
        f.startDate!.year,
        f.startDate!.month,
        f.startDate!.day,
      );
      if (day.isBefore(s)) return false;
    }
    if (f.endDate != null) {
      final e = DateTime(f.endDate!.year, f.endDate!.month, f.endDate!.day);
      if (day.isAfter(e)) return false;
    }
  }
  if (f.paymentContains.isNotEmpty &&
      !matchesAllContains(tx.paymentMethod, f.paymentContains)) {
    return false;
  }
  if (f.storeContains.isNotEmpty) {
    final storeText = '${tx.store ?? ''} ${tx.memo}';
    if (!matchesAllContains(storeText, f.storeContains)) {
      return false;
    }
  }
  if (f.categoryContains.isNotEmpty) {
    final catText = '${tx.mainCategory} ${tx.subCategory ?? ''}';
    if (!matchesAllContains(catText, f.categoryContains)) {
      return false;
    }
  }
  if (f.descriptionContains.isNotEmpty &&
      !matchesAllContains(tx.description, f.descriptionContains)) {
    return false;
  }
  if (f.memoContains.isNotEmpty &&
      !matchesAllContains(tx.memo, f.memoContains)) {
    return false;
  }
  if (f.benefitOnly ||
      f.pointsOnly ||
      f.minBenefit != null ||
      f.maxBenefit != null) {
    final byType = benefitByTypeForSearch(tx);
    final total = byType.values.fold<double>(0, (a, b) => a + b);
    if (f.benefitOnly && total <= 0) return false;
    if (f.pointsOnly) {
      final hasPoints = byType.keys.any((k) {
        final key = k.toLowerCase();
        return key.contains('포인트') ||
            key.contains('적립') ||
            key.contains('point');
      });
      if (!hasPoints) return false;
    }
    if (f.minBenefit != null && total < f.minBenefit!) {
      return false;
    }
    if (f.maxBenefit != null && total > f.maxBenefit!) {
      return false;
    }
  }
  return true;
}
