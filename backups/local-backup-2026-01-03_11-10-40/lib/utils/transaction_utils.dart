/// 거래 및 환불 관련 유틸리티 함수
///
/// - getNetExpense: 환불 내역을 반영한 실제 지출금액 계산
library;

import 'package:smart_ledger/models/transaction.dart';

/// 환불 내역을 반영한 실제 지출금액 계산
/// [original] : 원본 거래
/// [refunds] : 해당 거래의 환불(반품) 거래 리스트
/// 반환값: 환불 후 실제 지출금액 (0 이상)
double getNetExpense(Transaction original, List<Transaction> refunds) {
  final originalAmount = original.amount.abs();
  if (refunds.isEmpty) {
    return originalAmount;
  }

  double netExpense = originalAmount;

  final expenseRefundTotal = refunds
      .where((refund) => refund.type == TransactionType.expense)
      .fold<double>(0, (double sum, refund) => sum + refund.amount.abs());

  if (expenseRefundTotal > 0) {
    netExpense -= expenseRefundTotal;
  }

  final incomeRefundTotal = refunds
      .where((refund) => refund.type == TransactionType.income)
      .fold<double>(0, (double sum, refund) => sum + refund.amount.abs());

  if (incomeRefundTotal > 0) {
    final memoLower = original.memo.toLowerCase();
    final containsReturn = memoLower.contains('반품');
    final containsRefund = memoLower.contains('환불');
    final originalIndicatesAdjustment = containsReturn || containsRefund;

    // 원본 거래가 조정된 흔적이 없고, 지출 형태의 환불도 없다면 수입 환불을 차감
    if (expenseRefundTotal == 0 && !originalIndicatesAdjustment) {
      netExpense -= incomeRefundTotal;
    }
  }

  return netExpense < 0 ? 0 : netExpense;
}

/// 환불 목적지를 사람이 읽기 쉬운 라벨로 변환합니다.
String refundDestinationLabel(Transaction refund) {
  if (refund.type == TransactionType.expense) {
    return '결제 취소';
  }

  switch (refund.savingsAllocation) {
    case SavingsAllocation.assetIncrease:
      return '자산';
    case SavingsAllocation.expense:
      return '지출 예산';
    case null:
      break;
  }

  final memo = refund.memo.toLowerCase();
  if (memo.contains('지출') && memo.contains('예산')) {
    return '지출 예산';
  }
  if (memo.contains('비상금')) {
    return '비상금';
  }
  if (memo.contains('자산')) {
    return '자산';
  }
  return '기타';
}
