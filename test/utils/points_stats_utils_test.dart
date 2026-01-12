import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/points_stats_utils.dart';

void main() {
  Transaction createExpense({
    required String id,
    required double amount,
    required DateTime date,
    double? cardChargedAmount,
    String? benefitJson,
    String memo = '',
    bool isRefund = false,
  }) {
    return Transaction(
      id: id,
      type: TransactionType.expense,
      description: 'test',
      amount: amount,
      date: date,
      cardChargedAmount: cardChargedAmount,
      benefitJson: benefitJson,
      memo: memo,
      isRefund: isRefund,
    );
  }

  Transaction createSavings({
    required String id,
    required double amount,
    required DateTime date,
    String memo = '',
  }) {
    return Transaction(
      id: id,
      type: TransactionType.savings,
      description: 'test',
      amount: amount,
      date: date,
      memo: memo,
      savingsAllocation: SavingsAllocation.assetIncrease,
    );
  }

  group('PointsStatsUtils', () {
    group('categories', () {
      test('has 4 categories', () {
        expect(PointsStatsUtils.categories.length, 4);
      });

      test('includes catCard', () {
        expect(PointsStatsUtils.categories.contains(PointsStatsUtils.catCard), isTrue);
      });

      test('includes catOther', () {
        expect(PointsStatsUtils.categories.contains(PointsStatsUtils.catOther), isTrue);
      });
    });

    group('normalizeCategoryKey', () {
      test('returns catOther for empty', () {
        expect(PointsStatsUtils.normalizeCategoryKey(''), PointsStatsUtils.catOther);
      });

      test('normalizes 카드 to catCard', () {
        expect(PointsStatsUtils.normalizeCategoryKey('신한카드'), PointsStatsUtils.catCard);
      });

      test('normalizes 마트 to catSupplier', () {
        expect(PointsStatsUtils.normalizeCategoryKey('이마트'), PointsStatsUtils.catSupplier);
      });

      test('normalizes 쇼핑 to catSupplier', () {
        expect(PointsStatsUtils.normalizeCategoryKey('온라인쇼핑'), PointsStatsUtils.catSupplier);
      });

      test('normalizes 편의점 to catConvenience', () {
        expect(PointsStatsUtils.normalizeCategoryKey('편의점'), PointsStatsUtils.catConvenience);
      });

      test('returns catOther for unknown', () {
        expect(PointsStatsUtils.normalizeCategoryKey('unknown'), PointsStatsUtils.catOther);
      });
    });

    group('savedByCategory', () {
      test('returns empty for income', () {
        final tx = Transaction(
          id: '1',
          type: TransactionType.income,
          description: 'test',
          amount: 10000,
          date: DateTime(2026, 1, 11),
        );
        expect(PointsStatsUtils.savedByCategory(tx), isEmpty);
      });

      test('returns empty for refund', () {
        final tx = createExpense(
          id: '1',
          amount: 10000,
          date: DateTime(2026, 1, 11),
          isRefund: true,
        );
        expect(PointsStatsUtils.savedByCategory(tx), isEmpty);
      });

      test('calculates card discount', () {
        final tx = createExpense(
          id: '1',
          amount: 10000,
          date: DateTime(2026, 1, 11),
          cardChargedAmount: 8000,
        );
        final result = PointsStatsUtils.savedByCategory(tx);
        expect(result[PointsStatsUtils.catCard], 2000);
      });

      test('handles saved points record', () {
        final tx = createSavings(
          id: '1',
          amount: 5000,
          date: DateTime(2026, 1, 11),
          memo: '#포인트모으기',
        );
        final result = PointsStatsUtils.savedByCategory(tx);
        expect(result[PointsStatsUtils.catOther], 5000);
      });
    });

    group('sumByCategory', () {
      test('sums within date range', () {
        final txs = [
          createExpense(
            id: '1',
            amount: 10000,
            date: DateTime(2026, 1, 5),
            cardChargedAmount: 8000,
          ),
          createExpense(
            id: '2',
            amount: 5000,
            date: DateTime(2026, 1, 15),
            cardChargedAmount: 4000,
          ),
        ];

        final result = PointsStatsUtils.sumByCategory(
          txs,
          start: DateTime(2026),
          end: DateTime(2026, 1, 31),
        );

        expect(result[PointsStatsUtils.catCard], 3000); // 2000 + 1000
      });

      test('excludes transactions outside range', () {
        final txs = [
          createExpense(
            id: '1',
            amount: 10000,
            date: DateTime(2026, 2, 5), // outside range
            cardChargedAmount: 8000,
          ),
        ];

        final result = PointsStatsUtils.sumByCategory(
          txs,
          start: DateTime(2026),
          end: DateTime(2026, 1, 31),
        );

        expect(result[PointsStatsUtils.catCard], 0);
      });
    });

    group('sumTotal', () {
      test('sums all category values', () {
        final byCategory = {
          PointsStatsUtils.catCard: 1000.0,
          PointsStatsUtils.catSupplier: 500.0,
          PointsStatsUtils.catOther: 200.0,
        };
        expect(PointsStatsUtils.sumTotal(byCategory), 1700);
      });

      test('returns 0 for empty', () {
        expect(PointsStatsUtils.sumTotal({}), 0);
      });
    });

    group('ratios', () {
      test('calculates ratios', () {
        final byCategory = {
          PointsStatsUtils.catCard: 500.0,
          PointsStatsUtils.catSupplier: 300.0,
          PointsStatsUtils.catConvenience: 100.0,
          PointsStatsUtils.catOther: 100.0,
        };
        final result = PointsStatsUtils.ratios(byCategory);
        expect(result[PointsStatsUtils.catCard], 0.5);
        expect(result[PointsStatsUtils.catSupplier], 0.3);
      });

      test('returns empty for zero total', () {
        final byCategory = {
          PointsStatsUtils.catCard: 0.0,
        };
        expect(PointsStatsUtils.ratios(byCategory), isEmpty);
      });
    });

    group('projectByCategory', () {
      test('projects based on daily average', () {
        final recentByCategory = {
          PointsStatsUtils.catCard: 1000.0,
          PointsStatsUtils.catSupplier: 500.0,
          PointsStatsUtils.catConvenience: 0.0,
          PointsStatsUtils.catOther: 500.0,
        };

        final result = PointsStatsUtils.projectByCategory(
          recentByCategory,
          lookbackDays: 10,
          horizonDays: 30,
        );

        // Daily total: 2000/10 = 200
        // Projected total: 200 * 30 = 6000
        expect(result.values.fold<double>(0, (a, b) => a + b), closeTo(6000, 1));
      });

      test('returns zeros for invalid lookback', () {
        final result = PointsStatsUtils.projectByCategory(
          {},
          lookbackDays: 0,
          horizonDays: 30,
        );
        expect(result.values.every((v) => v == 0), isTrue);
      });
    });
  });
}
