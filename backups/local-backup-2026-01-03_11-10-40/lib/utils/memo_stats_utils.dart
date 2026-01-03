import 'package:smart_ledger/models/transaction.dart';

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

class MemoStatsResult {
  final double totalMemoAmount;
  final int memoTransactionCount;
  final List<MemoStatEntry> top10;
  final CategoryMemoInsight? topCategoryInsight;

  const MemoStatsResult({
    required this.totalMemoAmount,
    required this.memoTransactionCount,
    required this.top10,
    required this.topCategoryInsight,
  });
}

class MemoStatsUtils {
  const MemoStatsUtils._();

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

    for (final tx in transactions) {
      final memo = tx.memo.trim();
      if (memo.isEmpty) continue;
      if (!tx.type.isOutflow) continue;

      final amountAbs = tx.amount.abs();
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

    return MemoStatsResult(
      totalMemoAmount: totalMemoAmount,
      memoTransactionCount: memoTxCount,
      top10: entries.take(topN).toList(),
      topCategoryInsight: topCategory,
    );
  }
}
