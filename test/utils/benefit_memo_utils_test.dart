import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/benefit_memo_utils.dart';

void main() {
  group('BenefitMemoUtils', () {
    group('parseBenefitByType', () {
      test('returns empty map for null input', () {
        final result = BenefitMemoUtils.parseBenefitByType(null);
        expect(result, isEmpty);
      });

      test('returns empty map for empty string', () {
        final result = BenefitMemoUtils.parseBenefitByType('');
        expect(result, isEmpty);
      });

      test('returns empty map when no benefit prefix', () {
        final result = BenefitMemoUtils.parseBenefitByType('일반 메모입니다');
        expect(result, isEmpty);
      });

      test('parses single benefit with = separator', () {
        final result = BenefitMemoUtils.parseBenefitByType('혜택:카드=1200');
        expect(result, {'카드': 1200});
      });

      test('parses single benefit with : separator', () {
        final result = BenefitMemoUtils.parseBenefitByType('혜택:배송:3000');
        expect(result, {'배송': 3000});
      });

      test('parses multiple benefits comma separated', () {
        final result = BenefitMemoUtils.parseBenefitByType('혜택:카드=1200, 배송=3000');
        expect(result['카드'], 1200);
        expect(result['배송'], 3000);
      });

      test('parses multiple benefits space separated', () {
        final result = BenefitMemoUtils.parseBenefitByType('혜택: 카드:1200 배송:3000');
        expect(result['카드'], 1200);
        expect(result['배송'], 3000);
      });

      test('handles amounts with commas in JSON decoding', () {
        // parseBenefitByType에서는 콤마가 구분자로 사용됨
        // 금액에 콤마가 필요하면 decodeBenefitJson 사용
        final result = BenefitMemoUtils.decodeBenefitJson('{"적립":"1,500"}');
        expect(result['적립'], 1500);
      });

      test('ignores zero and negative values', () {
        final result = BenefitMemoUtils.parseBenefitByType('혜택:카드=0, 배송=-100');
        expect(result, isEmpty);
      });

      test('handles benefit anywhere in memo', () {
        final result = BenefitMemoUtils.parseBenefitByType('좋은 가게. 혜택:카드=500. 다음에 또 오자');
        expect(result, {'카드': 500});
      });

      test('handles multiline memo', () {
        final result = BenefitMemoUtils.parseBenefitByType('''
좋은 제품
혜택:할인=2000
만족합니다
''');
        expect(result, {'할인': 2000});
      });
    });

    group('encodeBenefitJson', () {
      test('encodes empty map', () {
        final result = BenefitMemoUtils.encodeBenefitJson({});
        expect(result, '{}');
      });

      test('encodes single benefit', () {
        final result = BenefitMemoUtils.encodeBenefitJson({'카드': 1200});
        expect(result, '{"카드":1200.0}');
      });

      test('encodes multiple benefits', () {
        final result = BenefitMemoUtils.encodeBenefitJson({
          '카드': 1200,
          '배송': 3000,
        });
        expect(result, contains('"카드":1200.0'));
        expect(result, contains('"배송":3000.0'));
      });

      test('filters out zero values', () {
        final result = BenefitMemoUtils.encodeBenefitJson({
          '카드': 1000,
          '적립': 0,
        });
        expect(result, contains('카드'));
        expect(result, isNot(contains('적립')));
      });

      test('filters out empty keys', () {
        final result = BenefitMemoUtils.encodeBenefitJson({
          '카드': 1000,
          '': 500,
          '  ': 300,
        });
        expect(result, '{"카드":1000.0}');
      });
    });

    group('decodeBenefitJson', () {
      test('returns empty map for null input', () {
        final result = BenefitMemoUtils.decodeBenefitJson(null);
        expect(result, isEmpty);
      });

      test('returns empty map for empty string', () {
        final result = BenefitMemoUtils.decodeBenefitJson('');
        expect(result, isEmpty);
      });

      test('returns empty map for invalid JSON', () {
        final result = BenefitMemoUtils.decodeBenefitJson('not json');
        expect(result, isEmpty);
      });

      test('decodes valid JSON', () {
        final result = BenefitMemoUtils.decodeBenefitJson('{"카드":1200,"배송":3000}');
        expect(result['카드'], 1200);
        expect(result['배송'], 3000);
      });

      test('handles string values', () {
        final result = BenefitMemoUtils.decodeBenefitJson('{"포인트":"1,500"}');
        expect(result['포인트'], 1500);
      });

      test('filters out zero and negative', () {
        final result = BenefitMemoUtils.decodeBenefitJson('{"카드":1000,"할인":0,"환불":-500}');
        expect(result, {'카드': 1000});
      });
    });

    test('roundtrip encode then decode preserves data', () {
      final original = {'카드': 1200.0, '배송': 3000.0, '적립': 500.0};
      final json = BenefitMemoUtils.encodeBenefitJson(original);
      final restored = BenefitMemoUtils.decodeBenefitJson(json);

      expect(restored, original);
    });
  });
}
