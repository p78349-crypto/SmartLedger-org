import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/product_name_utils.dart';

void main() {
  group('ProductNameUtils', () {
    group('normalizeKey', () {
      test('returns empty for empty string', () {
        expect(ProductNameUtils.normalizeKey(''), '');
      });

      test('converts to lowercase', () {
        expect(ProductNameUtils.normalizeKey('HELLO'), 'hello');
      });

      test('removes parenthetical notes', () {
        expect(ProductNameUtils.normalizeKey('우유(1L)'), '우유');
      });

      test('removes bracket notes', () {
        expect(ProductNameUtils.normalizeKey('우유[대용량]'), '우유');
      });

      test('removes punctuation', () {
        expect(ProductNameUtils.normalizeKey('A-B_C'), 'abc');
      });

      test('keeps Korean characters', () {
        expect(ProductNameUtils.normalizeKey('김치찌개'), '김치찌개');
      });

      test('keeps English characters', () {
        expect(ProductNameUtils.normalizeKey('Coffee'), 'coffee');
      });

      test('keeps digits', () {
        expect(ProductNameUtils.normalizeKey('A1B2'), 'a1b2');
      });

      test('normalizes spacing', () {
        expect(ProductNameUtils.normalizeKey('hello  world'), 'helloworld');
      });

      test('handles mixed content', () {
        expect(
          ProductNameUtils.normalizeKey('서울 우유 (1L) - 대용량'),
          '서울우유대용량',
        );
      });

      test('trims whitespace', () {
        expect(ProductNameUtils.normalizeKey('  test  '), 'test');
      });
    });
  });
}
