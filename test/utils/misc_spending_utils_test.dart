import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/misc_spending_utils.dart';

void main() {
  Transaction createExpense({
    required String id,
    required double amount,
    required DateTime date,
    String mainCategory = '기타',
    String? subCategory,
  }) {
    return Transaction(
      id: id,
      type: TransactionType.expense,
      description: 'test',
      amount: amount,
      date: date,
      mainCategory: mainCategory,
      subCategory: subCategory,
    );
  }

  group('MiscSpendingUtils', () {
    group('analyze', () {
      test('returns empty for no transactions', () {
        final result = MiscSpendingUtils.analyze([]);
        expect(result, isEmpty);
      });

      test('filters by date range', () {
        final now = DateTime(2026, 1, 31);
        final txs = [
          createExpense(
            id: '1',
            amount: 5000,
            date: DateTime(2026, 1, 15),
          ),
          createExpense(
            id: '2',
            amount: 5000,
            date: DateTime(2025, 12, 1), // outside 1-month lookback
          ),
        ];

        final result = MiscSpendingUtils.analyze(
          txs,
          lookbackMonths: 1,
          anchor: now,
        );

        // Only January transaction should be counted
        expect(result.isNotEmpty, isTrue);
        expect(result.first.count, 1);
      });

      test('identifies misc categories by low average', () {
        final now = DateTime(2026, 1, 31);
        final txs = [
          createExpense(
            id: '1',
            amount: 3000, // Below 10000 threshold
            date: DateTime(2026, 1, 15),
            mainCategory: '간식',
          ),
        ];

        final result = MiscSpendingUtils.analyze(
          txs,
          lookbackMonths: 1,
          anchor: now,
        );

        expect(result.length, 1);
        expect(result.first.mainCategory, '간식');
        expect(result.first.avgPerTx, 3000);
      });

      test('identifies misc categories by high frequency', () {
        final now = DateTime(2026, 1, 31);
        final txs = List.generate(
          5,
          (i) => createExpense(
            id: '$i',
            amount: 20000, // Above 10000 threshold individually
            date: DateTime(2026, 1, 15),
            mainCategory: '커피',
          ),
        );

        final result = MiscSpendingUtils.analyze(
          txs,
          lookbackMonths: 1,
          anchor: now,
        );

        // Should be flagged as misc due to count >= 5
        expect(result.any((s) => s.mainCategory == '커피'), isTrue);
      });

      test('calculates monthly and annual projection', () {
        final now = DateTime(2026, 2, 28);
        final txs = [
          createExpense(
            id: '1',
            amount: 6000,
            date: DateTime(2026, 1, 15),
            mainCategory: '간식',
          ),
          createExpense(
            id: '2',
            amount: 6000,
            date: DateTime(2026, 2, 15),
            mainCategory: '간식',
          ),
        ];

        final result = MiscSpendingUtils.analyze(
          txs,
          lookbackMonths: 2,
          anchor: now,
        );

        final stat = result.firstWhere((s) => s.mainCategory == '간식');
        expect(stat.totalAmount, 12000);
        expect(stat.monthlyAmount, 6000); // 12000 / 2 months
        expect(stat.annualProjection, 72000); // 6000 * 12
      });

      test('groups by main and sub category', () {
        final now = DateTime(2026, 1, 31);
        final txs = [
          createExpense(
            id: '1',
            amount: 5000,
            date: DateTime(2026, 1, 15),
            mainCategory: '식비',
            subCategory: '카페',
          ),
          createExpense(
            id: '2',
            amount: 5000,
            date: DateTime(2026, 1, 16),
            mainCategory: '식비',
            subCategory: '식당',
          ),
        ];

        final result = MiscSpendingUtils.analyze(
          txs,
          lookbackMonths: 1,
          anchor: now,
        );

        expect(result.length, 2);
        expect(
          result.any((s) => s.mainCategory == '식비' && s.subCategory == '카페'),
          isTrue,
        );
        expect(
          result.any((s) => s.mainCategory == '식비' && s.subCategory == '식당'),
          isTrue,
        );
      });

      test('sorts by monthlyAmount descending', () {
        final now = DateTime(2026, 1, 31);
        final txs = [
          createExpense(
            id: '1',
            amount: 3000,
            date: DateTime(2026, 1, 15),
            mainCategory: '간식A',
          ),
          createExpense(
            id: '2',
            amount: 9000,
            date: DateTime(2026, 1, 16),
            mainCategory: '간식B',
          ),
        ];

        final result = MiscSpendingUtils.analyze(
          txs,
          lookbackMonths: 1,
          anchor: now,
        );

        expect(result.first.mainCategory, '간식B');
        expect(result.last.mainCategory, '간식A');
      });

      test('excludes non-expense transactions', () {
        final now = DateTime(2026, 1, 31);
        final txs = [
          Transaction(
            id: '1',
            type: TransactionType.income,
            description: 'income',
            amount: 5000,
            date: DateTime(2026, 1, 15),
          ),
        ];

        final result = MiscSpendingUtils.analyze(
          txs,
          lookbackMonths: 1,
          anchor: now,
        );

        expect(result, isEmpty);
      });
    });
  });

  group('MiscCategoryStat', () {
    test('icon getter returns category icon', () {
      final stat = MiscCategoryStat(
        mainCategory: '식비',
        subCategory: '',
        count: 1,
        totalAmount: 10000,
        avgPerTx: 10000,
        monthlyAmount: 10000,
        annualProjection: 120000,
      );

      expect(stat.icon, isNotNull);
    });
  });
}
