import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/policy_service.dart';

void main() {
  group('PolicyService', () {
    late PolicyService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = PolicyService();
    });

    group('holds', () {
      test('listHolds returns empty list initially', () async {
        final holds = await service.listHolds();
        expect(holds, isEmpty);
      });

      test('addHold adds a hold entry', () async {
        await service.addHold(reason: 'Test hold reason');
        final holds = await service.listHolds();
        expect(holds, hasLength(1));
        expect(holds[0]['reason'], 'Test hold reason');
      });

      test('addHold with meta stores metadata', () async {
        await service.addHold(
          reason: 'Hold with meta',
          meta: {'key': 'value', 'count': 42},
        );
        final holds = await service.listHolds();
        expect(holds[0]['meta']['key'], 'value');
        expect(holds[0]['meta']['count'], 42);
      });

      test('multiple holds are stored in reverse order', () async {
        await service.addHold(reason: 'First');
        await service.addHold(reason: 'Second');
        await service.addHold(reason: 'Third');
        final holds = await service.listHolds();
        expect(holds, hasLength(3));
        expect(holds[0]['reason'], 'Third'); // 최신이 먼저
        expect(holds[1]['reason'], 'Second');
        expect(holds[2]['reason'], 'First');
      });
    });

    group('blocking rules', () {
      test('listBlockingRules returns empty list initially', () async {
        final rules = await service.listBlockingRules();
        expect(rules, isEmpty);
      });

      test('addBlockingRule adds a rule', () async {
        await service.addBlockingRule(
          key: 'test_rule',
          avg: 50000.0,
          count: 10,
        );
        final rules = await service.listBlockingRules();
        expect(rules, hasLength(1));
        expect(rules[0]['key'], 'test_rule');
        expect(rules[0]['avg'], 50000.0);
        expect(rules[0]['count'], 10);
      });

      test('addBlockingRule with meta stores metadata', () async {
        await service.addBlockingRule(
          key: 'rule_with_meta',
          avg: 100.0,
          count: 5,
          meta: {'category': 'food'},
        );
        final rules = await service.listBlockingRules();
        expect(rules[0]['meta']['category'], 'food');
      });
    });
  });
}
