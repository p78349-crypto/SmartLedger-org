import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/fixed_cost.dart';

void main() {
  group('FixedCost', () {
    test('creates with required fields', () {
      final cost = FixedCost(
        id: 'cost-1',
        name: '월세',
        amount: 500000,
      );

      expect(cost.id, 'cost-1');
      expect(cost.name, '월세');
      expect(cost.amount, 500000);
      expect(cost.paymentMethod, '현금'); // 기본값
    });

    test('creates with all fields', () {
      final cost = FixedCost(
        id: 'cost-2',
        name: '전기세',
        amount: 50000,
        vendor: '한국전력',
        paymentMethod: '자동이체',
        memo: '매월 25일',
        dueDay: 25,
      );

      expect(cost.vendor, '한국전력');
      expect(cost.paymentMethod, '자동이체');
      expect(cost.memo, '매월 25일');
      expect(cost.dueDay, 25);
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'id': 'cost-1',
          'name': '인터넷',
          'amount': 30000,
          'vendor': 'KT',
          'paymentMethod': '카드',
          'memo': '약정 할인',
          'dueDay': 15,
        };

        final cost = FixedCost.fromJson(json);

        expect(cost.id, 'cost-1');
        expect(cost.name, '인터넷');
        expect(cost.amount, 30000);
        expect(cost.vendor, 'KT');
        expect(cost.paymentMethod, '카드');
        expect(cost.memo, '약정 할인');
        expect(cost.dueDay, 15);
      });

      test('handles missing optional fields', () {
        final json = {
          'name': '보험료',
          'amount': 100000,
        };

        final cost = FixedCost.fromJson(json);

        expect(cost.name, '보험료');
        expect(cost.amount, 100000);
        expect(cost.vendor, isNull);
        expect(cost.memo, isNull);
        expect(cost.dueDay, isNull);
      });

      test('generates legacy ID when id is missing', () {
        final json = {
          'name': '월세',
          'amount': 500000,
        };

        final cost = FixedCost.fromJson(json);

        expect(cost.id, startsWith('legacy_'));
      });

      test('uses default paymentMethod when missing', () {
        final json = {
          'id': 'cost-1',
          'name': '관리비',
          'amount': 150000,
        };

        final cost = FixedCost.fromJson(json);
        expect(cost.paymentMethod, '현금');
      });
    });

    group('toJson', () {
      test('serializes to JSON correctly', () {
        final cost = FixedCost(
          id: 'cost-1',
          name: '월세',
          amount: 500000,
          vendor: '집주인',
          paymentMethod: '이체',
          memo: '매월 1일',
          dueDay: 1,
        );

        final json = cost.toJson();

        expect(json['id'], 'cost-1');
        expect(json['name'], '월세');
        expect(json['amount'], 500000);
        expect(json['vendor'], '집주인');
        expect(json['paymentMethod'], '이체');
        expect(json['memo'], '매월 1일');
        expect(json['dueDay'], 1);
      });
    });
  });
}
