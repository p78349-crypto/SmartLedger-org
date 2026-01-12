import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/memo_stats_utils.dart';

void main() {
  Transaction createTransaction({
    required String id,
    required TransactionType type,
    required double amount,
    String memo = '',
    String mainCategory = '기타',
    String? subCategory,
    String? detailCategory,
  }) {
    return Transaction(
      id: id,
      type: type,
      description: 'test',
      amount: amount,
      date: DateTime(2026, 1, 11),
      memo: memo,
      mainCategory: mainCategory,
      subCategory: subCategory,
      detailCategory: detailCategory,
    );
  }

  group('MemoStatsUtils', () {
    group('memoStats', () {
      test('returns empty stats for empty list', () {
        final result = MemoStatsUtils.memoStats([]);

        expect(result.totalMemoAmount, 0);
        expect(result.memoTransactionCount, 0);
        expect(result.top10, isEmpty);
        expect(result.topCategoryInsight, isNull);
      });

      test('excludes transactions without memo', () {
        final txs = [
          createTransaction(
            id: '1',
            type: TransactionType.expense,
            amount: 10000,
          ),
        ];

        final result = MemoStatsUtils.memoStats(txs);

        expect(result.memoTransactionCount, 0);
      });

      test('excludes income transactions', () {
        final txs = [
          createTransaction(
            id: '1',
            type: TransactionType.income,
            amount: 10000,
            memo: '월급',
          ),
        ];

        final result = MemoStatsUtils.memoStats(txs);

        expect(result.memoTransactionCount, 0);
      });

      test('aggregates memo totals', () {
        final txs = [
          createTransaction(
            id: '1',
            type: TransactionType.expense,
            amount: 5000,
            memo: '커피',
          ),
          createTransaction(
            id: '2',
            type: TransactionType.expense,
            amount: 3000,
            memo: '커피',
          ),
        ];

        final result = MemoStatsUtils.memoStats(txs);

        expect(result.totalMemoAmount, 8000);
        expect(result.memoTransactionCount, 2);
        expect(result.top10.first.memo, '커피');
        expect(result.top10.first.totalAmount, 8000);
        expect(result.top10.first.count, 2);
      });

      test('sorts by total amount descending', () {
        final txs = [
          createTransaction(
            id: '1',
            type: TransactionType.expense,
            amount: 3000,
            memo: '간식',
          ),
          createTransaction(
            id: '2',
            type: TransactionType.expense,
            amount: 10000,
            memo: '점심',
          ),
        ];

        final result = MemoStatsUtils.memoStats(txs);

        expect(result.top10.first.memo, '점심');
        expect(result.top10.last.memo, '간식');
      });

      test('respects topN limit', () {
        final txs = List.generate(
          15,
          (i) => createTransaction(
            id: '$i',
            type: TransactionType.expense,
            amount: 1000,
            memo: '메모$i',
          ),
        );

        final result = MemoStatsUtils.memoStats(txs, topN: 5);

        expect(result.top10.length, 5);
      });

      test('calculates topCategoryInsight', () {
        final txs = [
          createTransaction(
            id: '1',
            type: TransactionType.expense,
            amount: 5000,
            memo: '커피',
            mainCategory: '식비',
          ),
          createTransaction(
            id: '2',
            type: TransactionType.expense,
            amount: 3000,
            memo: '라떼',
            mainCategory: '식비',
          ),
          createTransaction(
            id: '3',
            type: TransactionType.expense,
            amount: 10000,
            memo: '버스',
            mainCategory: '교통',
          ),
        ];

        final result = MemoStatsUtils.memoStats(txs);

        expect(result.topCategoryInsight, isNotNull);
        expect(result.topCategoryInsight!.mainCategory, '식비');
        expect(result.topCategoryInsight!.memoCount, 2);
      });

      test('calculates 3-tier category stats', () {
        final txs = [
          createTransaction(
            id: '1',
            type: TransactionType.expense,
            amount: 5000,
            memo: '메모',
            mainCategory: '식비',
            subCategory: '카페',
            detailCategory: '커피',
          ),
        ];

        final result = MemoStatsUtils.memoStats(txs);

        expect(result.topCategories3Tier.isNotEmpty, isTrue);
        expect(result.topCategories3Tier.first.label, '식비 > 카페 > 커피');
      });

      test('handles savings as outflow', () {
        final txs = [
          createTransaction(
            id: '1',
            type: TransactionType.savings,
            amount: 50000,
            memo: '저축',
          ),
        ];

        final result = MemoStatsUtils.memoStats(txs);

        expect(result.memoTransactionCount, 1);
        expect(result.totalMemoAmount, 50000);
      });
    });
  });

  group('MemoStatEntry', () {
    test('has correct properties', () {
      const entry = MemoStatEntry(
        memo: 'test',
        totalAmount: 10000,
        count: 5,
      );

      expect(entry.memo, 'test');
      expect(entry.totalAmount, 10000);
      expect(entry.count, 5);
    });
  });

  group('CategoryMemoInsight', () {
    test('has correct properties', () {
      const insight = CategoryMemoInsight(
        mainCategory: '식비',
        memoCount: 10,
        totalAmount: 50000,
      );

      expect(insight.mainCategory, '식비');
      expect(insight.memoCount, 10);
      expect(insight.totalAmount, 50000);
    });
  });

  group('Category3TierStatEntry', () {
    test('has correct properties', () {
      const entry = Category3TierStatEntry(
        label: '식비 > 카페 > 커피',
        totalAmount: 10000,
        count: 3,
      );

      expect(entry.label, '식비 > 카페 > 커피');
      expect(entry.totalAmount, 10000);
      expect(entry.count, 3);
    });
  });
}
