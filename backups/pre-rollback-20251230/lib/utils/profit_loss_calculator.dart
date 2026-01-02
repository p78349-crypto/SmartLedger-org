import 'package:flutter/material.dart';
import 'package:smart_ledger/utils/currency_formatter.dart';

/// 손익 계산 유틸리티
class ProfitLossCalculator {
  /// 현재 자산 가치와 원가 기반으로 손익 계산
  static double calculateProfitLoss(double currentAmount, double? costBasis) {
    if (costBasis == null || costBasis == 0) return 0;
    return currentAmount - costBasis;
  }

  /// 손익률 계산 (%)
  static double calculateProfitLossRate(
    double currentAmount,
    double? costBasis,
  ) {
    if (costBasis == null || costBasis == 0) return 0;
    return ((currentAmount - costBasis) / costBasis) * 100;
  }

  /// 손익 상태 문자열 (통화 포맷 + 또는 -)
  static String formatProfitLoss(double profitLoss) {
    if (profitLoss > 0) {
      return '+${CurrencyFormatter.format(profitLoss, showUnit: true)}';
    } else if (profitLoss < 0) {
      return CurrencyFormatter.format(profitLoss, showUnit: true);
    } else {
      return CurrencyFormatter.format(0, showUnit: true);
    }
  }

  /// 손익률 문자열 (+ 또는 % - 소수점 2자리)
  static String formatProfitLossRate(double rate) {
    if (rate > 0) {
      return '+${rate.toStringAsFixed(2)}%';
    } else if (rate < 0) {
      return '${rate.toStringAsFixed(2)}%';
    } else {
      return '0%';
    }
  }

  /// 손익 색상 판정 (손실: 빨강, 이익: 초록, 중립: 회색)
  static Color getProfitLossColor(double profitLoss) {
    if (profitLoss > 0) {
      return const Color(0xFF4CAF50); // 초록 (이익)
    } else if (profitLoss < 0) {
      return const Color(0xFFE53935); // 빨강 (손실)
    } else {
      return const Color(0xFF9E9E9E); // 회색 (중립)
    }
  }

  /// 손익 상태 라벨
  static String getProfitLossLabel(double profitLoss) {
    if (profitLoss > 0) {
      return '이익';
    } else if (profitLoss < 0) {
      return '손실';
    } else {
      return '손익없음';
    }
  }
}

