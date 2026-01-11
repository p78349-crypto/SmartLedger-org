import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/store_memo_utils.dart';

void main() {
  group('StoreMemoUtils', () {
    group('extractStoreKey', () {
      test('returns null for null', () {
        expect(StoreMemoUtils.extractStoreKey(null), isNull);
      });

      test('returns null for empty string', () {
        expect(StoreMemoUtils.extractStoreKey(''), isNull);
      });

      test('extracts first line', () {
        expect(StoreMemoUtils.extractStoreKey('마트\n부가정보'), '마트');
      });

      test('stops at slash separator', () {
        expect(StoreMemoUtils.extractStoreKey('마트 / 식품'), '마트');
      });

      test('stops at pipe separator', () {
        expect(StoreMemoUtils.extractStoreKey('마트 | 할인'), '마트');
      });

      test('stops at comma separator', () {
        expect(StoreMemoUtils.extractStoreKey('마트, 할인행사'), '마트');
      });

      test('strips brackets', () {
        expect(StoreMemoUtils.extractStoreKey('[대형마트]'), '대형마트');
      });

      test('strips parentheses', () {
        expect(StoreMemoUtils.extractStoreKey('(마트)'), '마트');
      });

      test('strips quotes', () {
        expect(StoreMemoUtils.extractStoreKey('"마트"'), '마트');
      });

      test('strips nested wrapping', () {
        expect(StoreMemoUtils.extractStoreKey('[[마트]]'), '마트');
      });

      test('collapses whitespace', () {
        expect(StoreMemoUtils.extractStoreKey('대형  마트'), '대형 마트');
      });

      test('trims whitespace', () {
        expect(StoreMemoUtils.extractStoreKey('  마트  '), '마트');
      });
    });

    group('normalizeMemoForMatch', () {
      test('returns empty for empty string', () {
        expect(StoreMemoUtils.normalizeMemoForMatch(''), '');
      });

      test('converts to lowercase', () {
        expect(StoreMemoUtils.normalizeMemoForMatch('HELLO'), 'hello');
      });

      test('uses first line only', () {
        expect(StoreMemoUtils.normalizeMemoForMatch('first\nsecond'), 'first');
      });

      test('collapses whitespace', () {
        expect(StoreMemoUtils.normalizeMemoForMatch('a   b'), 'a b');
      });

      test('trims whitespace', () {
        expect(StoreMemoUtils.normalizeMemoForMatch('  test  '), 'test');
      });
    });
  });
}
