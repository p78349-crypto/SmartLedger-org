import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/savings_plan.dart';

void main() {
  group('SavingsPlan', () {
    test('creates with required fields', () {
      final plan = SavingsPlan(
        id: 'plan-1',
        name: '비상금 적금',
        monthlyAmount: 500000,
        startDate: DateTime(2026, 1, 1),
        termMonths: 12,
        interestRate: 0.035,
        paidMonths: [1, 2, 3],
        createdAt: DateTime(2026, 1, 1),
      );

      expect(plan.id, 'plan-1');
      expect(plan.name, '비상금 적금');
      expect(plan.monthlyAmount, 500000);
      expect(plan.termMonths, 12);
      expect(plan.interestRate, 0.035);
      expect(plan.paidMonths, [1, 2, 3]);
      expect(plan.autoDeposit, isTrue); // 기본값
      expect(plan.bankName, ''); // 기본값
    });

    test('creates with all fields', () {
      final plan = SavingsPlan(
        id: 'plan-2',
        bankName: '국민은행',
        name: '주택청약',
        monthlyAmount: 100000,
        startDate: DateTime(2026, 1, 1),
        termMonths: 24,
        interestRate: 0.025,
        paidMonths: [],
        createdAt: DateTime(2026, 1, 1),
        autoDeposit: false,
      );

      expect(plan.bankName, '국민은행');
      expect(plan.autoDeposit, isFalse);
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final original = SavingsPlan(
          id: 'plan-1',
          name: '적금',
          monthlyAmount: 500000,
          startDate: DateTime(2026, 1, 1),
          termMonths: 12,
          interestRate: 0.035,
          paidMonths: [1],
          createdAt: DateTime(2026, 1, 1),
        );

        final updated = original.copyWith(
          monthlyAmount: 600000,
          paidMonths: [1, 2],
        );

        expect(updated.id, 'plan-1');
        expect(updated.monthlyAmount, 600000);
        expect(updated.paidMonths, [1, 2]);
      });

      test('preserves unspecified fields', () {
        final original = SavingsPlan(
          id: 'plan-1',
          bankName: '신한은행',
          name: '적금',
          monthlyAmount: 500000,
          startDate: DateTime(2026, 1, 1),
          termMonths: 12,
          interestRate: 0.035,
          paidMonths: [1],
          createdAt: DateTime(2026, 1, 1),
        );

        final updated = original.copyWith(name: '정기적금');

        expect(updated.bankName, '신한은행');
        expect(updated.monthlyAmount, 500000);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'id': 'plan-1',
          'bankName': '우리은행',
          'name': '목돈 마련',
          'monthlyAmount': 300000,
          'startDate': '2026-01-01T00:00:00.000',
          'termMonths': 24,
          'interestRate': 0.04,
          'paidMonths': [1, 2, 3],
          'createdAt': '2026-01-01T00:00:00.000',
          'autoDeposit': true,
        };

        final plan = SavingsPlan.fromJson(json);

        expect(plan.id, 'plan-1');
        expect(plan.bankName, '우리은행');
        expect(plan.name, '목돈 마련');
        expect(plan.monthlyAmount, 300000);
        expect(plan.termMonths, 24);
        expect(plan.interestRate, 0.04);
        expect(plan.paidMonths, [1, 2, 3]);
      });

      test('handles missing optional fields', () {
        final json = {
          'id': 'plan-1',
          'startDate': '2026-01-01T00:00:00.000',
        };

        final plan = SavingsPlan.fromJson(json);

        expect(plan.bankName, '');
        expect(plan.name, '예금');
        expect(plan.monthlyAmount, 0);
        expect(plan.termMonths, 12);
        expect(plan.interestRate, 0);
        expect(plan.autoDeposit, isTrue);
      });
    });

    group('toJson', () {
      test('serializes to JSON correctly', () {
        final plan = SavingsPlan(
          id: 'plan-1',
          bankName: 'KB',
          name: '적금',
          monthlyAmount: 500000,
          startDate: DateTime(2026, 1, 1),
          termMonths: 12,
          interestRate: 0.035,
          paidMonths: [1, 2],
          createdAt: DateTime(2026, 1, 1),
          autoDeposit: true,
        );

        final json = plan.toJson();

        expect(json['id'], 'plan-1');
        expect(json['bankName'], 'KB');
        expect(json['name'], '적금');
        expect(json['monthlyAmount'], 500000);
        expect(json['termMonths'], 12);
        expect(json['interestRate'], 0.035);
        expect(json['paidMonths'], [1, 2]);
        expect(json['autoDeposit'], isTrue);
      });
    });
  });
}
