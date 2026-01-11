import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/stats_calculator.dart';

void main() {
  Transaction createTransaction({
    required String id,
    required TransactionType type,
    required double amount,
    required DateTime date,
    String mainCategory = '기타',
    String? subCategory,
  }) {
    return Transaction(
      id: id,
      type: type,
      description: 'test',
      amount: amount,
      date: date,
      mainCategory: mainCategory,
      subCategory: subCategory,
    );
  }

  group('StatsCalculator', () {
    group('filterByType', () {
      test('filters expenses only', () {
        final txs = [
          createTransaction(id: '1', type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 1)),
          createTransaction(id: '2', type: TransactionType.income, amount: 2000, date: DateTime(2026, 1, 1)),
          createTransaction(id: '3', type: TransactionType.expense, amount: 3000, date: DateTime(2026, 1, 1)),
        ];

        final result = StatsCalculator.filterByType(txs, TransactionType.expense);
        expect(result.length, 2);
      });

      test('returns empty for no matches', () {
        final txs = [
          createTransaction(id: '1', type: TransactionType.income, amount: 1000, date: DateTime(2026, 1, 1)),
        ];

        final result = StatsCalculator.filterByType(txs, TransactionType.expense);
        expect(result, isEmpty);
      });
    });

    group('filterByMonth', () {
      test('filters transactions by month', () {
        final txs = [
          createTransaction(id: '1', type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 15)),
          createTransaction(id: '2', type: TransactionType.expense, amount: 2000, date: DateTime(2026, 2, 15)),
        ];

        final result = StatsCalculator.filterByMonth(txs, DateTime(2026, 1, 1));
        expect(result.length, 1);
        expect(result.first.id, '1');
      });
    });

    group('filterByRange', () {
      test('filters transactions within range', () {
        final txs = [
          createTransaction(id: '1', type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 5)),
          createTransaction(id: '2', type: TransactionType.expense, amount: 2000, date: DateTime(2026, 1, 15)),
          createTransaction(id: '3', type: TransactionType.expense, amount: 3000, date: DateTime(2026, 1, 25)),
        ];

        final result = StatsCalculator.filterByRange(
          txs,
          DateTime(2026, 1, 10),
          DateTime(2026, 1, 20),
        );
        expect(result.length, 1);
        expect(result.first.id, '2');
      });

      test('includes boundary dates', () {
        final txs = [
          createTransaction(id: '1', type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 10)),
          createTransaction(id: '2', type: TransactionType.expense, amount: 2000, date: DateTime(2026, 1, 20)),
        ];

        final result = StatsCalculator.filterByRange(
          txs,
          DateTime(2026, 1, 10),
          DateTime(2026, 1, 20),
        );
        expect(result.length, 2);
      });
    });

    group('filterByCategory', () {
      test('filters by category and type', () {
        final txs = [
          createTransaction(id: '1', type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 1), mainCategory: '식비'),
          createTransaction(id: '2', type: TransactionType.expense, amount: 2000, date: DateTime(2026, 1, 1), mainCategory: '교통'),
          createTransaction(id: '3', type: TransactionType.income, amount: 3000, date: DateTime(2026, 1, 1), mainCategory: '식비'),
        ];

        final result = StatsCalculator.filterByCategory(txs, '식비', TransactionType.expense);
        expect(result.length, 1);
        expect(result.first.id, '1');
      });
    });

    group('calculateTotal', () {
      test('sums all amounts', () {
        final txs = [
          createTransaction(id: '1', type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 1)),
          createTransaction(id: '2', type: TransactionType.expense, amount: 2000, date: DateTime(2026, 1, 1)),
          createTransaction(id: '3', type: TransactionType.expense, amount: 3000, date: DateTime(2026, 1, 1)),
        ];

        expect(StatsCalculator.calculateTotal(txs), 6000);
      });

      test('returns 0 for empty list', () {
        expect(StatsCalculator.calculateTotal([]), 0);
      });
    });

    group('calculateMonthlyStats', () {
      test('groups by month', () {
        final txs = [
          createTransaction(id: '1', type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 15)),
          createTransaction(id: '2', type: TransactionType.expense, amount: 2000, date: DateTime(2026, 1, 20)),
          createTransaction(id: '3', type: TransactionType.expense, amount: 3000, date: DateTime(2026, 2, 15)),
        ];

        final result = StatsCalculator.calculateMonthlyStats(txs, TransactionType.expense);
        expect(result.length, 2);
        expect(result[0].total, 3000); // January
        expect(result[0].count, 2);
        expect(result[1].total, 3000); // February
        expect(result[1].count, 1);
      });

      test('sorts by month ascending', () {
        final txs = [
          createTransaction(id: '1', type: TransactionType.expense, amount: 1000, date: DateTime(2026, 3, 1)),
          createTransaction(id: '2', type: TransactionType.expense, amount: 2000, date: DateTime(2026, 1, 1)),
        ];

        final result = StatsCalculator.calculateMonthlyStats(txs, TransactionType.expense);
        expect(result[0].month.month, 1);
        expect(result[1].month.month, 3);
      });
    });

    group('calculateCategoryStats', () {
      test('groups by category', () {
        final txs = [
          createTransaction(id: '1', type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 1), mainCategory: '식비'),
          createTransaction(id: '2', type: TransactionType.expense, amount: 2000, date: DateTime(2026, 1, 1), mainCategory: '식비'),
          createTransaction(id: '3', type: TransactionType.expense, amount: 3000, date: DateTime(2026, 1, 1), mainCategory: '교통'),
        ];

        final result = StatsCalculator.calculateCategoryStats(txs, TransactionType.expense);
        expect(result.length, 2);
      });

      test('calculates percentage', () {
        final txs = [
          createTransaction(id: '1', type: TransactionType.expense, amount: 500, date: DateTime(2026, 1, 1), mainCategory: '식비'),
          createTransaction(id: '2', type: TransactionType.expense, amount: 500, date: DateTime(2026, 1, 1), mainCategory: '교통'),
        ];

        final result = StatsCalculator.calculateCategoryStats(txs, TransactionType.expense);
        expect(result[0].percentage, 50);
        expect(result[1].percentage, 50);
      });

      test('sorts by total descending', () {
        final txs = [
          createTransaction(id: '1', type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 1), mainCategory: '식비'),
          createTransaction(id: '2', type: TransactionType.expense, amount: 3000, date: DateTime(2026, 1, 1), mainCategory: '교통'),
        ];

        final result = StatsCalculator.calculateCategoryStats(txs, TransactionType.expense);
        expect(result[0].category, '교통');
        expect(result[1].category, '식비');
      });
    });

    group('calculateSubCategoryStats', () {
      test('groups by sub category', () {
        final txs = [
          createTransaction(id: '1', type: TransactionType.expense, amount: 1000, date: DateTime(2026, 1, 1), subCategory: '카페'),
          createTransaction(id: '2', type: TransactionType.expense, amount: 2000, date: DateTime(2026, 1, 1), subCategory: '식당'),
        ];

        final result = StatsCalculator.calculateSubCategoryStats(txs, TransactionType.expense);
        expect(result.length, 2);
      });
    });
  });

  group('MonthlyStats', () {
    test('has correct properties', () {
      final stats = MonthlyStats(
        month: DateTime(2026, 1),
        total: 10000,
        count: 5,
        transactions: [],
      );

      expect(stats.month.month, 1);
      expect(stats.total, 10000);
      expect(stats.count, 5);
    });
  });

  group('CategoryStats', () {
    test('has correct properties', () {
      const stats = CategoryStats(
        category: '식비',
        total: 10000,
        count: 5,
        percentage: 25,
        transactions: [],
      );

      expect(stats.category, '식비');
      expect(stats.total, 10000);
      expect(stats.percentage, 25);
    });
  });

  group('DailyStats', () {
    test('has correct properties', () {
      final stats = DailyStats(
        date: DateTime(2026, 1, 11),
        total: 5000,
        transactions: [],
      );

      expect(stats.date.day, 11);
      expect(stats.total, 5000);
    });
  });
}
