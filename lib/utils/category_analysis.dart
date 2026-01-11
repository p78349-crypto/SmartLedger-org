import '../models/transaction.dart';

/// Simple category tendency analysis utilities.
/// Provides aggregated totals and counts per main/sub category.
class CategoryAnalysis {
  final Map<String, _CategoryStats> _stats = {};

  void ingest(List<Transaction> txs) {
    _stats.clear();
    for (final t in txs) {
      final key = t.mainCategory.isEmpty
          ? Transaction.defaultMainCategory
          : t.mainCategory;
      final sub = t.subCategory ?? '';
      final id = sub.isEmpty ? key : '$key·$sub';
      final s = _stats.putIfAbsent(id, () => _CategoryStats(key, sub));
      s.count += 1;
      s.amount += t.amount;
      if (t.isRefund) s.refundCount += 1;
      if (t.isRefund) s.refundAmount += t.amount;
    }
  }

  /// Returns map of category id -> stats
  Map<String, CategoryStats> result() {
    return _stats.map((k, v) => MapEntry(k, v.toPublic()));
  }
}

class _CategoryStats {
  final String main;
  final String sub;
  int count = 0;
  double amount = 0;
  int refundCount = 0;
  double refundAmount = 0;

  _CategoryStats(this.main, this.sub);

  CategoryStats toPublic() => CategoryStats(
    mainCategory: main,
    subCategory: sub,
    count: count,
    totalAmount: amount,
    refundCount: refundCount,
    refundAmount: refundAmount,
  );
}

class CategoryStats {
  final String mainCategory;
  final String subCategory;
  final int count;
  final double totalAmount;
  final int refundCount;
  final double refundAmount;

  CategoryStats({
    required this.mainCategory,
    required this.subCategory,
    required this.count,
    required this.totalAmount,
    required this.refundCount,
    required this.refundAmount,
  });
}
