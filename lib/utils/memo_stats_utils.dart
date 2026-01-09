import '../models/transaction.dart';

class MemoStatEntry {
  final String memo;
  final double totalAmount;
  final int count;

  const MemoStatEntry({
    required this.memo,
    required this.totalAmount,
    required this.count,
  });
}

class CategoryMemoInsight {
  final String mainCategory;
  final int memoCount;
  final double totalAmount;

  const CategoryMemoInsight({
    required this.mainCategory,
    required this.memoCount,
    required this.totalAmount,
  });
}

class Category3TierStatEntry {
  final String label; // "Main > Sub > Detail"
  final double totalAmount;
  final int count;

  const Category3TierStatEntry({
    required this.label,
    required this.totalAmount,
    required this.count,
  });
}

class MemoStatsResult {
  final double totalMemoAmount;
  final int memoTransactionCount;
  final List<MemoStatEntry> top10;
  final CategoryMemoInsight? topCategoryInsight;
  final List<Category3TierStatEntry> topCategories3Tier;

  const MemoStatsResult({
    required this.totalMemoAmount,
    required this.memoTransactionCount,
    required this.top10,
    required this.topCategoryInsight,
    this.topCategories3Tier = const [],
  });
}

class MemoStatsUtils {
  const MemoStatsUtils._();

  static String _labelFor(Transaction tx) {
    final parts = [
      tx.mainCategory,
      if (tx.subCategory != null && tx.subCategory!.isNotEmpty) tx.subCategory,
      if (tx.detailCategory != null && tx.detailCategory!.isNotEmpty)
        tx.detailCategory,
    ];
    return parts.join(' > ');
  }

  /// memoStats: 메모가 있는 거래들을 가격(총액) 기준으로 내림차순 정렬하여 TOP N을 계산.
  ///
  /// 기본 정책:
  /// - memo가 비어있으면 제외
  /// - 지출/예금은 outflow로 간주 (TransactionTypeX.isOutflow)
  /// - 금액은 절대값(규모) 기준으로 합산
  static MemoStatsResult memoStats(
    Iterable<Transaction> transactions, {
    int topN = 10,
  }) {
    final memoTotals = <String, double>{};
    final memoCounts = <String, int>{};

    double totalMemoAmount = 0;
    int memoTxCount = 0;

    final categoryCounts = <String, int>{};
    final categoryTotals = <String, double>{};

    final cat3Totals = <String, double>{};
    final cat3Counts = <String, int>{};

    for (final tx in transactions) {
      final memo = tx.memo.trim();
      final isOutflow = tx.type.isOutflow;

      final amountAbs = tx.amount.abs();

      if (isOutflow) {
        final cat3Label = _labelFor(tx);
        cat3Totals[cat3Label] = (cat3Totals[cat3Label] ?? 0) + amountAbs;
        cat3Counts[cat3Label] = (cat3Counts[cat3Label] ?? 0) + 1;
      }

      if (memo.isEmpty) continue;
      if (!isOutflow) continue;

      totalMemoAmount += amountAbs;
      memoTxCount += 1;

      memoTotals[memo] = (memoTotals[memo] ?? 0) + amountAbs;
      memoCounts[memo] = (memoCounts[memo] ?? 0) + 1;

      final cat = tx.mainCategory.trim().isEmpty
          ? Transaction.defaultMainCategory
          : tx.mainCategory.trim();
      categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + amountAbs;
    }

    final entries =
        memoTotals.entries
            .map(
              (e) => MemoStatEntry(
                memo: e.key,
                totalAmount: e.value,
                count: memoCounts[e.key] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    CategoryMemoInsight? topCategory;
    if (categoryCounts.isNotEmpty) {
      final cats =
          categoryCounts.entries
              .map(
                (e) => CategoryMemoInsight(
                  mainCategory: e.key,
                  memoCount: e.value,
                  totalAmount: categoryTotals[e.key] ?? 0,
                ),
              )
              .toList()
            ..sort((a, b) {
              final byCount = b.memoCount.compareTo(a.memoCount);
              if (byCount != 0) return byCount;
              return b.totalAmount.compareTo(a.totalAmount);
            });
      topCategory = cats.first;
    }

    final cat3Entries =
        cat3Totals.entries
            .map(
              (e) => Category3TierStatEntry(
                label: e.key,
                totalAmount: e.value,
                count: cat3Counts[e.key] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    return MemoStatsResult(
      totalMemoAmount: totalMemoAmount,
      memoTransactionCount: memoTxCount,
      top10: entries.take(topN).toList(),
      topCategoryInsight: topCategory,
      topCategories3Tier: cat3Entries.take(topN).toList(),
    );
  }
}
