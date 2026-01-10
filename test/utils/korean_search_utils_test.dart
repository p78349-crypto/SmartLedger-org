import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/korean_search_utils.dart';

void main() {
  group('KoreanSearchUtils', () {
    test('extractChosung extracts initial consonants from Hangul syllables', () {
      expect(KoreanSearchUtils.extractChosung('김치'), 'ㄱㅊ');
      expect(KoreanSearchUtils.extractChosung('안녕'), 'ㅇㄴ');
    });

    test('matches supports case-insensitive substring matching', () {
      expect(KoreanSearchUtils.matches('Hello World', 'world'), isTrue);
      expect(KoreanSearchUtils.matches('Hello World', 'WORLD'), isTrue);
      expect(KoreanSearchUtils.matches('Hello World', 'nope'), isFalse);
    });

    test('matches supports 초성-only queries', () {
      expect(KoreanSearchUtils.matches('김치', 'ㄱㅊ'), isTrue);
      expect(KoreanSearchUtils.matches('안녕하세요', 'ㅇㄴㅎㅅㅇ'), isTrue);
      expect(KoreanSearchUtils.matches('김치', 'ㄱㅈ'), isFalse);
    });

    test('초성 matching is whitespace-tolerant', () {
      expect(KoreanSearchUtils.matches('김치 찌개', 'ㄱㅊㅉㄱ'), isTrue);
      expect(KoreanSearchUtils.matches('김치\n찌개', 'ㄱㅊㅉㄱ'), isTrue);
      expect(KoreanSearchUtils.matches('김치\t찌개', 'ㄱㅊㅉㄱ'), isTrue);
    });

    test('empty query matches everything (search UX friendly)', () {
      expect(KoreanSearchUtils.matches('anything', ''), isTrue);
      expect(KoreanSearchUtils.matches('anything', '   '), isTrue);
    });

    test('isChosungQuery rejects non-초성 characters', () {
      expect(KoreanSearchUtils.isChosungQuery('ㄱㅊ'), isTrue);
      expect(KoreanSearchUtils.isChosungQuery('ㄱa'), isFalse);
      expect(KoreanSearchUtils.isChosungQuery('가'), isFalse);
    });
  });
}
