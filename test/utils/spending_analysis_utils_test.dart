import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/spending_analysis_utils.dart';

void main() {
  Transaction createExpense({
    required String id,
    required double amount,
    required DateTime date,
    String description = 'test',
    String mainCategory = '기타',
    String? store,
  }) {
    return Transaction(
      id: id,
      type: TransactionType.expense,
      description: description,
      amount: amount,
      date: date,
      mainCategory: mainCategory,
      store: store,
    );
  }

  group('SpendingAnalysisUtils', () {
    group('getTopSpendingItems', () {
      test('returns empty for no transactions', () {
        final result = SpendingAnalysisUtils.getTopSpendingItems(
          transactions: [],
        );
        expect(result, isEmpty);
      });

      test('groups by description', () {
        final txs = [
          createExpense(id: '1', amount: 5000, date: DateTime(2026, 1, 10), description: '커피'),
          createExpense(id: '2', amount: 3000, date: DateTime(2026, 1, 11), description: '커피'),
          createExpense(id: '3', amount: 10000, date: DateTime(2026, 1, 12), description: '점심'),
        ];

        final result = SpendingAnalysisUtils.getTopSpendingItems(
          transactions: txs,
        );

        expect(result.length, 2);
      });

      test('sorts by total amount descending', () {
        final txs = [
          createExpense(id: '1', amount: 5000, date: DateTime(2026, 1, 10), description: '커피'),
          createExpense(id: '2', amount: 10000, date: DateTime(2026, 1, 11), description: '점심'),
        ];

        final result = SpendingAnalysisUtils.getTopSpendingItems(
          transactions: txs,
        );

        expect(result.first.name, '점심');
      });

      test('respects topN limit', () {
        final txs = List.generate(
          10,
          (i) => createExpense(
            id: '$i',
            amount: 1000,
            date: DateTime(2026, 1, 10),
            description: '항목$i',
          ),
        );

        final result = SpendingAnalysisUtils.getTopSpendingItems(
          transactions: txs,
          topN: 3,
        );

        expect(result.length, 3);
      });

      test('filters by date range', () {
        final txs = [
          createExpense(id: '1', amount: 5000, date: DateTime(2026, 1, 5), description: '커피'),
          createExpense(id: '2', amount: 10000, date: DateTime(2026, 2, 15), description: '점심'),
        ];

        final result = SpendingAnalysisUtils.getTopSpendingItems(
          transactions: txs,
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 31),
        );

        expect(result.length, 1);
        expect(result.first.name, '커피');
      });

      test('excludes non-expense transactions', () {
        final txs = [
          createExpense(id: '1', amount: 5000, date: DateTime(2026, 1, 10), description: '커피'),
          Transaction(
            id: '2',
            type: TransactionType.income,
            description: '월급',
            amount: 1000000,
            date: DateTime(2026, 1, 10),
          ),
        ];

        final result = SpendingAnalysisUtils.getTopSpendingItems(
          transactions: txs,
        );

        expect(result.length, 1);
      });
    });

    group('getTopSpendingCategories', () {
      test('returns empty for no transactions', () {
        final result = SpendingAnalysisUtils.getTopSpendingCategories(
          transactions: [],
        );
        expect(result, isEmpty);
      });

      test('groups by category', () {
        final txs = [
          createExpense(id: '1', amount: 5000, date: DateTime(2026, 1, 10), mainCategory: '식비'),
          createExpense(id: '2', amount: 3000, date: DateTime(2026, 1, 11), mainCategory: '식비'),
          createExpense(id: '3', amount: 10000, date: DateTime(2026, 1, 12), mainCategory: '교통'),
        ];

        final result = SpendingAnalysisUtils.getTopSpendingCategories(
          transactions: txs,
          currentMonth: DateTime(2026, 1, 15),
        );

        expect(result.isNotEmpty, isTrue);
      });
    });

    group('detectRecurringPatterns', () {
      test('returns empty for insufficient occurrences', () {
        final txs = [
          createExpense(id: '1', amount: 5000, date: DateTime(2026, 1, 1), description: '커피'),
          createExpense(id: '2', amount: 5000, date: DateTime(2026, 1, 8), description: '커피'),
        ];

        final result = SpendingAnalysisUtils.detectRecurringPatterns(
          transactions: txs,
          minOccurrences: 3,
        );

        expect(result, isEmpty);
      });

      test('detects recurring pattern', () {
        final txs = [
          createExpense(id: '1', amount: 5000, date: DateTime(2026, 1, 1), description: '커피'),
          createExpense(id: '2', amount: 5000, date: DateTime(2026, 1, 8), description: '커피'),
          createExpense(id: '3', amount: 5000, date: DateTime(2026, 1, 15), description: '커피'),
          createExpense(id: '4', amount: 5000, date: DateTime(2026, 1, 22), description: '커피'),
        ];

        final result = SpendingAnalysisUtils.detectRecurringPatterns(
          transactions: txs,
          minOccurrences: 3,
        );

        expect(result.isNotEmpty, isTrue);
        expect(result.first.avgInterval, closeTo(7, 1));
      });

      test('excludes patterns with long intervals', () {
        final txs = [
          createExpense(id: '1', amount: 5000, date: DateTime(2026, 1, 1), description: '커피'),
          createExpense(id: '2', amount: 5000, date: DateTime(2026, 3, 1), description: '커피'),
          createExpense(id: '3', amount: 5000, date: DateTime(2026, 5, 1), description: '커피'),
        ];

        final result = SpendingAnalysisUtils.detectRecurringPatterns(
          transactions: txs,
          minOccurrences: 3,
          maxIntervalDays: 45,
        );

        expect(result, isEmpty);
      });
    });
  });

  group('ItemSpendingAnalysis', () {
    test('monthlyAverage calculates correctly', () {
      final analysis = ItemSpendingAnalysis(
        name: 'test',
        totalAmount: 12000,
        count: 12,
        avgAmount: 1000,
        percentage: 10,
        transactions: [
          createExpense(id: '1', amount: 6000, date: DateTime(2026, 1, 1)),
          createExpense(id: '2', amount: 6000, date: DateTime(2026, 2, 1)),
        ],
      );

      expect(analysis.monthlyAverage, 12000); // 1 month span
    });
  });

  group('RecurringSpendingPattern', () {
    test('predictionConfidence returns 0 for insufficient data', () {
      final pattern = RecurringSpendingPattern(
        name: 'test',
        avgAmount: 1000,
        frequency: 4,
        avgInterval: 7,
        purchaseDates: [DateTime(2026, 1, 1), DateTime(2026, 1, 8)],
      );

      expect(pattern.predictionConfidence, 0);
    });
  });
}
