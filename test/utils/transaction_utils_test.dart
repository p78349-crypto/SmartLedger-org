import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/transaction.dart';
import 'package:smart_ledger/utils/transaction_utils.dart';

void main() {
  final now = DateTime(2026, 1, 11);

  group('getNetExpense', () {
    test('returns original amount when no refunds', () {
      final original = Transaction(
        id: 'tx-1',
        type: TransactionType.expense,
        description: '신발',
        amount: 89000,
        date: now,
      );

      final result = getNetExpense(original, []);
      expect(result, 89000);
    });

    test('subtracts expense refund from original', () {
      final original = Transaction(
        id: 'tx-1',
        type: TransactionType.expense,
        description: '옷',
        amount: 50000,
        date: now,
      );

      final refund = Transaction(
        id: 'ref-1',
        type: TransactionType.expense,
        description: '옷 반품',
        amount: -20000, // 환불 금액 (음수)
        date: now,
        isRefund: true,
        originalTransactionId: 'tx-1',
      );

      final result = getNetExpense(original, [refund]);
      expect(result, 30000); // 50000 - 20000
    });

    test('handles income type refund when no prior adjustments', () {
      final original = Transaction(
        id: 'tx-1',
        type: TransactionType.expense,
        description: '가전',
        amount: 100000,
        date: now,
      );

      final refund = Transaction(
        id: 'ref-1',
        type: TransactionType.income,
        description: '환불',
        amount: 30000,
        date: now,
        isRefund: true,
        originalTransactionId: 'tx-1',
      );

      final result = getNetExpense(original, [refund]);
      expect(result, 70000); // 100000 - 30000
    });

    test('ignores income refund when original has 반품 in memo', () {
      final original = Transaction(
        id: 'tx-1',
        type: TransactionType.expense,
        description: '가방',
        amount: 80000,
        date: now,
        memo: '반품 예정',
      );

      final refund = Transaction(
        id: 'ref-1',
        type: TransactionType.income,
        description: '환불',
        amount: 40000,
        date: now,
      );

      final result = getNetExpense(original, [refund]);
      expect(result, 80000); // 원본 유지 (memo에 반품 있음)
    });

    test('returns 0 when refund exceeds original', () {
      final original = Transaction(
        id: 'tx-1',
        type: TransactionType.expense,
        description: '테스트',
        amount: 10000,
        date: now,
      );

      final refund = Transaction(
        id: 'ref-1',
        type: TransactionType.expense,
        description: '과다환불',
        amount: -15000,
        date: now,
      );

      final result = getNetExpense(original, [refund]);
      expect(result, 0); // 음수가 되면 0 반환
    });

    test('handles multiple refunds', () {
      final original = Transaction(
        id: 'tx-1',
        type: TransactionType.expense,
        description: '쇼핑',
        amount: 100000,
        date: now,
      );

      final refunds = [
        Transaction(
          id: 'ref-1',
          type: TransactionType.expense,
          description: '부분환불1',
          amount: -30000,
          date: now,
        ),
        Transaction(
          id: 'ref-2',
          type: TransactionType.expense,
          description: '부분환불2',
          amount: -20000,
          date: now,
        ),
      ];

      final result = getNetExpense(original, refunds);
      expect(result, 50000); // 100000 - 30000 - 20000
    });
  });

  group('refundDestinationLabel', () {
    test('returns 결제 취소 for expense refund', () {
      final refund = Transaction(
        id: 'ref-1',
        type: TransactionType.expense,
        description: '환불',
        amount: -10000,
        date: now,
        isRefund: true,
      );

      expect(refundDestinationLabel(refund), '결제 취소');
    });

    test('returns 자산 for assetIncrease allocation', () {
      final refund = Transaction(
        id: 'ref-1',
        type: TransactionType.income,
        description: '환불',
        amount: 10000,
        date: now,
        savingsAllocation: SavingsAllocation.assetIncrease,
      );

      expect(refundDestinationLabel(refund), '자산');
    });

    test('returns 지출 예산 for expense allocation', () {
      final refund = Transaction(
        id: 'ref-1',
        type: TransactionType.income,
        description: '환불',
        amount: 10000,
        date: now,
        savingsAllocation: SavingsAllocation.expense,
      );

      expect(refundDestinationLabel(refund), '지출 예산');
    });

    test('detects destination from memo - 지출 예산', () {
      final refund = Transaction(
        id: 'ref-1',
        type: TransactionType.income,
        description: '환불',
        amount: 10000,
        date: now,
        memo: '지출 예산으로 환불',
      );

      expect(refundDestinationLabel(refund), '지출 예산');
    });

    test('detects destination from memo - 비상금', () {
      final refund = Transaction(
        id: 'ref-1',
        type: TransactionType.income,
        description: '환불',
        amount: 10000,
        date: now,
        memo: '비상금으로 입금',
      );

      expect(refundDestinationLabel(refund), '비상금');
    });

    test('detects destination from memo - 자산', () {
      final refund = Transaction(
        id: 'ref-1',
        type: TransactionType.income,
        description: '환불',
        amount: 10000,
        date: now,
        memo: '자산 증가',
      );

      expect(refundDestinationLabel(refund), '자산');
    });

    test('returns 기타 when no match', () {
      final refund = Transaction(
        id: 'ref-1',
        type: TransactionType.income,
        description: '환불',
        amount: 10000,
        date: now,
      );

      expect(refundDestinationLabel(refund), '기타');
    });
  });
}
