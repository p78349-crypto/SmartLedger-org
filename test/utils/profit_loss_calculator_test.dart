import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/profit_loss_calculator.dart';

void main() {
  group('ProfitLossCalculator', () {
    group('calculateProfitLoss', () {
      test('calculates profit correctly', () {
        final result = ProfitLossCalculator.calculateProfitLoss(150.0, 100.0);
        expect(result, 50.0);
      });

      test('calculates loss correctly', () {
        final result = ProfitLossCalculator.calculateProfitLoss(80.0, 100.0);
        expect(result, -20.0);
      });

      test('returns 0 when costBasis is null', () {
        final result = ProfitLossCalculator.calculateProfitLoss(100.0, null);
        expect(result, 0.0);
      });

      test('returns 0 when costBasis is 0', () {
        final result = ProfitLossCalculator.calculateProfitLoss(100.0, 0.0);
        expect(result, 0.0);
      });
    });

    group('calculateProfitLossRate', () {
      test('calculates profit rate correctly', () {
        final result =
            ProfitLossCalculator.calculateProfitLossRate(150.0, 100.0);
        expect(result, 50.0); // 50% 이익
      });

      test('calculates loss rate correctly', () {
        final result =
            ProfitLossCalculator.calculateProfitLossRate(75.0, 100.0);
        expect(result, -25.0); // 25% 손실
      });

      test('returns 0 when costBasis is null', () {
        final result =
            ProfitLossCalculator.calculateProfitLossRate(100.0, null);
        expect(result, 0.0);
      });

      test('returns 0 when costBasis is 0', () {
        final result = ProfitLossCalculator.calculateProfitLossRate(100.0, 0.0);
        expect(result, 0.0);
      });
    });

    group('formatProfitLossRate', () {
      test('formats positive rate with plus sign', () {
        final result = ProfitLossCalculator.formatProfitLossRate(25.5);
        expect(result, '+25.50%');
      });

      test('formats negative rate', () {
        final result = ProfitLossCalculator.formatProfitLossRate(-10.25);
        expect(result, '-10.25%');
      });

      test('formats zero rate', () {
        final result = ProfitLossCalculator.formatProfitLossRate(0.0);
        expect(result, '0%');
      });
    });

    group('getProfitLossColor', () {
      test('returns green for profit', () {
        final result = ProfitLossCalculator.getProfitLossColor(100.0);
        expect(result, const Color(0xFF4CAF50));
      });

      test('returns red for loss', () {
        final result = ProfitLossCalculator.getProfitLossColor(-50.0);
        expect(result, const Color(0xFFE53935));
      });

      test('returns grey for zero', () {
        final result = ProfitLossCalculator.getProfitLossColor(0.0);
        expect(result, const Color(0xFF9E9E9E));
      });
    });

    group('getProfitLossLabel', () {
      test('returns 이익 for positive', () {
        final result = ProfitLossCalculator.getProfitLossLabel(100.0);
        expect(result, '이익');
      });

      test('returns 손실 for negative', () {
        final result = ProfitLossCalculator.getProfitLossLabel(-50.0);
        expect(result, '손실');
      });

      test('returns 손익없음 for zero', () {
        final result = ProfitLossCalculator.getProfitLossLabel(0.0);
        expect(result, '손익없음');
      });
    });
  });
}
