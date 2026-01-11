import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/benefit_aggregation_utils.dart';

void main() {
  final now = DateTime(2026, 1, 11);

  Transaction createExpense({
    required String id,
    required double amount,
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
      date: now,
      cardChargedAmount: cardChargedAmount,
      benefitJson: benefitJson,
      memo: memo,
      isRefund: isRefund,
    );
  }

  Transaction createSavings({
    required String id,
    required double amount,
    required String memo,
    SavingsAllocation? allocation,
  }) {
    return Transaction(
      id: id,
      type: TransactionType.savings,
      description: 'test',
      amount: amount,
      date: now,
      memo: memo,
      savingsAllocation: allocation ?? SavingsAllocation.assetIncrease,
    );
  }

  group('BenefitAggregationUtils', () {
    group('memo tags', () {
      test('skippedSpendMemoTag is correct', () {
        expect(
          BenefitAggregationUtils.skippedSpendMemoTag,
          '#참은소비',
        );
      });

      test('savedPointsMemoTag is correct', () {
        expect(BenefitAggregationUtils.savedPointsMemoTag, '#포인트모으기');
      });

      test('roundUpMemoTag is correct', () {
        expect(BenefitAggregationUtils.roundUpMemoTag, '#잔돈모으기');
      });
    });

    group('isSkippedSpendRecord', () {
      test('returns true for valid skipped spend', () {
        final tx = createSavings(
          id: '1',
          amount: 10000,
          memo: '커피 #참은소비',
        );
        expect(BenefitAggregationUtils.isSkippedSpendRecord(tx), isTrue);
      });

      test('returns false for expense type', () {
        final tx = createExpense(id: '1', amount: 10000, memo: '#참은소비');
        expect(BenefitAggregationUtils.isSkippedSpendRecord(tx), isFalse);
      });

      test('returns false without memo tag', () {
        final tx = createSavings(id: '1', amount: 10000, memo: '그냥 저금');
        expect(BenefitAggregationUtils.isSkippedSpendRecord(tx), isFalse);
      });
    });

    group('benefitOf', () {
      test('returns 0 for income', () {
        final tx = Transaction(
          id: '1',
          type: TransactionType.income,
          description: 'test',
          amount: 10000,
          date: now,
        );
        expect(BenefitAggregationUtils.benefitOf(tx), 0);
      });

      test('returns 0 for refund', () {
        final tx = createExpense(id: '1', amount: 10000, isRefund: true);
        expect(BenefitAggregationUtils.benefitOf(tx), 0);
      });

      test('calculates benefit from cardChargedAmount', () {
        final tx = createExpense(
          id: '1',
          amount: 10000,
          cardChargedAmount: 8000,
        );
        // 10000 - 8000 = 2000 혜택
        expect(BenefitAggregationUtils.benefitOf(tx), 2000);
      });

      test('returns 0 when charged >= amount', () {
        final tx = createExpense(
          id: '1',
          amount: 10000,
          cardChargedAmount: 10000,
        );
        expect(BenefitAggregationUtils.benefitOf(tx), 0);
      });

      test('calculates benefit from benefitJson', () {
        final tx = createExpense(
          id: '1',
          amount: 10000,
          benefitJson: '{"카드":1000,"포인트":500}',
        );
        expect(BenefitAggregationUtils.benefitOf(tx), 1500);
      });

      test('calculates benefit from memo', () {
        final tx = createExpense(
          id: '1',
          amount: 10000,
          memo: '혜택:카드=2000',
        );
        expect(BenefitAggregationUtils.benefitOf(tx), 2000);
      });

      test('returns amount for skipped spend record', () {
        final tx = createSavings(id: '1', amount: 5000, memo: '#참은소비');
        expect(BenefitAggregationUtils.benefitOf(tx), 5000);
      });

      test('returns amount for saved points record', () {
        final tx = createSavings(id: '1', amount: 3000, memo: '#포인트모으기');
        expect(BenefitAggregationUtils.benefitOf(tx), 3000);
      });

      test('returns amount for round up record', () {
        final tx = createSavings(id: '1', amount: 200, memo: '#잔돈모으기');
        expect(BenefitAggregationUtils.benefitOf(tx), 200);
      });
    });

    group('sumBenefit', () {
      test('sums all benefits', () {
        final txs = [
          createExpense(id: '1', amount: 10000, cardChargedAmount: 8000),
          createExpense(id: '2', amount: 5000, cardChargedAmount: 4000),
        ];
        // 2000 + 1000 = 3000
        expect(BenefitAggregationUtils.sumBenefit(txs), 3000);
      });

      test('filters by date range', () {
        final txs = [
          Transaction(
            id: '1',
            type: TransactionType.expense,
            description: 'test',
            amount: 10000,
            date: DateTime(2026, 1, 5),
            cardChargedAmount: 8000,
          ),
          Transaction(
            id: '2',
            type: TransactionType.expense,
            description: 'test',
            amount: 5000,
            date: DateTime(2026, 1, 15),
            cardChargedAmount: 4000,
          ),
        ];

        final result = BenefitAggregationUtils.sumBenefit(
          txs,
          start: DateTime(2026, 1, 10),
        );
        expect(result, 1000); // 1월 15일 것만
      });
    });

    group('averageMonthlyBenefit', () {
      test('returns 0 for empty list', () {
        expect(BenefitAggregationUtils.averageMonthlyBenefit([]), 0);
      });

      test('calculates monthly average', () {
        final txs = [
          Transaction(
            id: '1',
            type: TransactionType.expense,
            description: 'test',
            amount: 10000,
            date: now.subtract(Duration(days: 15)),
            cardChargedAmount: 7000,
          ),
        ];
        // 3000 혜택, 90일 기준 = 3개월, 평균 = 1000
        final result = BenefitAggregationUtils.averageMonthlyBenefit(
          txs,
          now: now,
        );
        expect(result, 1000);
      });
    });
  });
}
