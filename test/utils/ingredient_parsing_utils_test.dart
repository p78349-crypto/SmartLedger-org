import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/ingredient_parsing_utils.dart';

void main() {
  group('IngredientParsingUtils', () {
    group('knownIngredients', () {
      test('contains common ingredients', () {
        expect(IngredientParsingUtils.knownIngredients.contains('닭고기'), true);
        expect(IngredientParsingUtils.knownIngredients.contains('양파'), true);
        expect(IngredientParsingUtils.knownIngredients.contains('계란'), true);
        expect(IngredientParsingUtils.knownIngredients.contains('쌀'), true);
      });

      test('is not empty', () {
        expect(IngredientParsingUtils.knownIngredients, isNotEmpty);
      });
    });

    group('parseNameAndAmount', () {
      test('parses ingredient with numeric amount', () {
        final result = IngredientParsingUtils.parseNameAndAmount('가지 1개');
        expect(result.$1, '가지');
        expect(result.$2, '1개');
      });

      test('parses ingredient with decimal amount', () {
        final result = IngredientParsingUtils.parseNameAndAmount('우유 1.5L');
        expect(result.$1, '우유');
        expect(result.$2, '1.5L');
      });

      test('parses ingredient with range amount', () {
        final result = IngredientParsingUtils.parseNameAndAmount('양파 2~3개');
        expect(result.$1, '양파');
        expect(result.$2, '2~3개');
      });

      test('parses ingredient with fraction amount', () {
        final result = IngredientParsingUtils.parseNameAndAmount('레몬 1/2개');
        expect(result.$1, '레몬');
        expect(result.$2, '1/2개');
      });

      test('parses ingredient with weight', () {
        final result = IngredientParsingUtils.parseNameAndAmount('소고기 100g');
        expect(result.$1, '소고기');
        expect(result.$2, '100g');
      });

      test('handles ingredient with parentheses', () {
        final result = IngredientParsingUtils.parseNameAndAmount(
          '닭고기(적은 것) 1마리',
        );
        expect(result.$1, '닭고기(적은 것)');
        expect(result.$2, '1마리');
      });

      test('handles text unit - 한 개', () {
        final result = IngredientParsingUtils.parseNameAndAmount('양파 한 개');
        expect(result.$1, '양파');
        expect(result.$2, '한 개');
      });

      test('handles text unit - 적당량', () {
        final result = IngredientParsingUtils.parseNameAndAmount('소금 적당량');
        expect(result.$1, '소금');
        expect(result.$2, '적당량');
      });

      test('handles amount in parentheses', () {
        final result = IngredientParsingUtils.parseNameAndAmount('양파(1개)');
        expect(result.$1, '양파');
        expect(result.$2, '1개');
      });

      test('returns empty for empty string', () {
        final result = IngredientParsingUtils.parseNameAndAmount('');
        expect(result.$1, '');
        expect(result.$2, '');
      });

      test('returns original with 정보 없음 when cannot parse', () {
        final result = IngredientParsingUtils.parseNameAndAmount('양파');
        expect(result.$1, '양파');
        expect(result.$2, '(정보 없음)');
      });

      test('handles only amount string', () {
        final result = IngredientParsingUtils.parseNameAndAmount('1개');
        expect(result.$1, '1개');
        expect(result.$2, '(정보 없음)');
      });
    });

    group('extractUniqueNames', () {
      test('extracts unique ingredient names', () {
        final result = IngredientParsingUtils.extractUniqueNames([
          '양파 1개',
          '당근 2개',
          '양파 2개',
        ]);
        expect(result, contains('양파'));
        expect(result, contains('당근'));
        expect(result.length, 2);
      });

      test('returns empty list for empty input', () {
        final result = IngredientParsingUtils.extractUniqueNames([]);
        expect(result, isEmpty);
      });

      test('handles unparseable items', () {
        final result = IngredientParsingUtils.extractUniqueNames([
          '양파',
          '당근 1개',
        ]);
        expect(result, contains('양파'));
        expect(result, contains('당근'));
      });
    });
  });
}
