import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/roi_utils.dart';

void main() {
  Transaction createTransaction({
    required String id,
    required TransactionType type,
    required double amount,
    required DateTime date,
    String description = 'test',
    String memo = '',
    String? store,
    String? supplier,
    String? originalTransactionId,
  }) {
    return Transaction(
      id: id,
      type: type,
      description: description,
      amount: amount,
      date: date,
      memo: memo,
      store: store,
      supplier: supplier,
      originalTransactionId: originalTransactionId,
    );
  }

  group('RoiUtils', () {
    group('computeOverallRoi', () {
      test('returns 0 totals for empty list', () {
        final result = RoiUtils.computeOverallRoi(
          [],
          start: DateTime(2026),
          end: DateTime(2026, 2),
        );

        expect(result['totalSpent'], 0.0);
        expect(result['totalReturn'], 0.0);
        expect(result['overallRoi'], isNull);
      });

      test('calculates spent from expenses in range', () {
        final txs = [
          createTransaction(
            id: '1',
            type: TransactionType.expense,
            amount: 10000,
            date: DateTime(2026, 1, 15),
          ),
          createTransaction(
            id: '2',
            type: TransactionType.expense,
            amount: 5000,
            date: DateTime(2026, 1, 20),
          ),
        ];

        final result = RoiUtils.computeOverallRoi(
          txs,
          start: DateTime(2026),
          end: DateTime(2026, 2),
        );

        expect(result['totalSpent'], 15000.0);
      });

      test('excludes expenses outside date range', () {
        final txs = [
          createTransaction(
            id: '1',
            type: TransactionType.expense,
            amount: 10000,
            date: DateTime(2026, 1, 15),
          ),
          createTransaction(
            id: '2',
            type: TransactionType.expense,
            amount: 5000,
            date: DateTime(2026, 3), // outside range
          ),
        ];

        final result = RoiUtils.computeOverallRoi(
          txs,
          start: DateTime(2026),
          end: DateTime(2026, 2),
        );

        expect(result['totalSpent'], 10000.0);
      });

      test('matches income by originalTransactionId', () {
        final txs = [
          createTransaction(
            id: 'exp1',
            type: TransactionType.expense,
            amount: 10000,
            date: DateTime(2026, 1, 15),
          ),
          createTransaction(
            id: 'inc1',
            type: TransactionType.income,
            amount: 5000,
            date: DateTime(2026, 2),
            originalTransactionId: 'exp1',
          ),
        ];

        final result = RoiUtils.computeOverallRoi(
          txs,
          start: DateTime(2026),
          end: DateTime(2026, 2),
        );

        expect(result['totalSpent'], 10000.0);
        expect(result['totalReturn'], 5000.0); // weight 1.0
      });

      test('matches income by store', () {
        final txs = [
          createTransaction(
            id: '1',
            type: TransactionType.expense,
            amount: 10000,
            date: DateTime(2026, 1, 15),
            store: '마트A',
          ),
          createTransaction(
            id: '2',
            type: TransactionType.income,
            amount: 2000,
            date: DateTime(2026, 1, 20),
            store: '마트A',
          ),
        ];

        final result = RoiUtils.computeOverallRoi(
          txs,
          start: DateTime(2026),
          end: DateTime(2026, 2),
        );

        expect(result['totalReturn'], closeTo(1800, 1)); // weight 0.9
      });

      test('matches income by supplier', () {
        final txs = [
          createTransaction(
            id: '1',
            type: TransactionType.expense,
            amount: 10000,
            date: DateTime(2026, 1, 15),
            supplier: '공급업체A',
          ),
          createTransaction(
            id: '2',
            type: TransactionType.income,
            amount: 2000,
            date: DateTime(2026, 1, 20),
            supplier: '공급업체A',
          ),
        ];

        final result = RoiUtils.computeOverallRoi(
          txs,
          start: DateTime(2026),
          end: DateTime(2026, 2),
        );

        expect(result['totalReturn'], closeTo(1600, 1)); // weight 0.8
      });

      test('calculates ROI percentage', () {
        final txs = [
          createTransaction(
            id: 'exp1',
            type: TransactionType.expense,
            amount: 10000,
            date: DateTime(2026, 1, 15),
          ),
          createTransaction(
            id: 'inc1',
            type: TransactionType.income,
            amount: 12000,
            date: DateTime(2026, 2),
            originalTransactionId: 'exp1',
          ),
        ];

        final result = RoiUtils.computeOverallRoi(
          txs,
          start: DateTime(2026),
          end: DateTime(2026, 2),
        );

        // ROI = (12000 - 10000) / 10000 = 0.2 = 20%
        expect(result['overallRoi'], closeTo(0.2, 0.01));
      });

      test('groups ROI by category', () {
        final txs = [
          createTransaction(
            id: 'exp1',
            type: TransactionType.expense,
            amount: 10000,
            date: DateTime(2026, 1, 15),
            description: '식비',
          ),
          createTransaction(
            id: 'inc1',
            type: TransactionType.income,
            amount: 5000,
            date: DateTime(2026, 2),
            originalTransactionId: 'exp1',
          ),
        ];

        final result = RoiUtils.computeOverallRoi(
          txs,
          start: DateTime(2026),
          end: DateTime(2026, 2),
        );

        final byCategory = result['byCategory'] as Map<String, dynamic>;
        expect(byCategory.isNotEmpty, isTrue);
      });

      test('respects lookahead months limit', () {
        final txs = [
          createTransaction(
            id: 'exp1',
            type: TransactionType.expense,
            amount: 10000,
            date: DateTime(2026, 1, 15),
          ),
          createTransaction(
            id: 'inc1',
            type: TransactionType.income,
            amount: 5000,
            date: DateTime(2026, 6), // 5 months later
            originalTransactionId: 'exp1',
          ),
        ];

        final result = RoiUtils.computeOverallRoi(
          txs,
          start: DateTime(2026),
          end: DateTime(2026, 2),
        );

        // Income should not be matched (beyond lookahead)
        expect(result['totalReturn'], 0.0);
      });
    });
  });
}
