import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/form_field_helpers.dart';

void main() {
  group('FormFieldHelpers', () {
    group('getOptionalFieldValue', () {
      test('returns value when not empty', () {
        expect(getOptionalFieldValue('테스트'), '테스트');
      });

      test('returns trimmed value', () {
        expect(getOptionalFieldValue('  테스트  '), '테스트');
      });

      test('returns default for empty string', () {
        expect(getOptionalFieldValue(''), '(미입력)');
      });

      test('returns default for whitespace only', () {
        expect(getOptionalFieldValue('   '), '(미입력)');
      });

      test('returns custom default value', () {
        expect(getOptionalFieldValue('', '없음'), '없음');
      });
    });

    group('isAmountValid', () {
      test('returns true for positive amount', () {
        expect(isAmountValid(100.0), true);
        expect(isAmountValid(0.01), true);
      });

      test('returns false for null', () {
        expect(isAmountValid(null), false);
      });

      test('returns false for zero', () {
        expect(isAmountValid(0.0), false);
      });

      test('returns false for negative', () {
        expect(isAmountValid(-10.0), false);
      });
    });

    group('getOptionalNumericValue', () {
      test('returns value when not null', () {
        expect(getOptionalNumericValue<int>(5, 0), 5);
        expect(getOptionalNumericValue<double>(3.14, 0.0), 3.14);
      });

      test('returns default when null', () {
        expect(getOptionalNumericValue<int>(null, 1), 1);
        expect(getOptionalNumericValue<double>(null, 2.5), 2.5);
      });
    });

    group('combineOptionalTexts', () {
      test('combines non-empty values', () {
        expect(combineOptionalTexts(['시중은행', '적금']), '시중은행 적금');
      });

      test('skips empty values', () {
        expect(combineOptionalTexts(['시중은행', '', '적금']), '시중은행 적금');
      });

      test('returns default when all empty', () {
        expect(combineOptionalTexts(['', '   ']), '(미입력)');
      });

      test('returns custom default', () {
        expect(combineOptionalTexts([], '없음'), '없음');
      });

      test('trims individual values', () {
        expect(combineOptionalTexts(['  A  ', '  B  ']), 'A B');
      });
    });

    group('conditionalValue', () {
      test('returns trimmed value when not empty', () {
        expect(
          conditionalValue(true, '  테스트  ', onTrue: '기본', onFalse: '없음'),
          '테스트',
        );
      });

      test('returns onTrue when condition is true and value empty', () {
        expect(
          conditionalValue(true, '', onTrue: '자동이체', onFalse: '없음'),
          '자동이체',
        );
      });

      test('returns onFalse when condition is false and value empty', () {
        expect(
          conditionalValue(false, '', onTrue: '자동이체', onFalse: '없음'),
          '없음',
        );
      });
    });

    group('FieldValidationResult', () {
      test('valid factory creates valid result', () {
        final result = FieldValidationResult.valid();
        expect(result.isValid, true);
        expect(result.errorMessage, isNull);
      });

      test('invalid factory creates invalid result with message', () {
        final result = FieldValidationResult.invalid('에러 메시지');
        expect(result.isValid, false);
        expect(result.errorMessage, '에러 메시지');
      });
    });

    group('validateAmountField', () {
      test('returns valid for positive number string', () {
        final result = validateAmountField('100');
        expect(result.isValid, true);
      });

      test('returns valid for number with comma', () {
        final result = validateAmountField('1,000');
        expect(result.isValid, true);
      });

      test('returns invalid for empty', () {
        final result = validateAmountField('');
        expect(result.isValid, false);
      });

      test('returns invalid for null', () {
        final result = validateAmountField(null);
        expect(result.isValid, false);
      });

      test('returns invalid for zero', () {
        final result = validateAmountField('0');
        expect(result.isValid, false);
      });

      test('uses custom error message', () {
        final result = validateAmountField('', '필수 입력');
        expect(result.errorMessage, '필수 입력');
      });
    });

    group('validateOptionalField', () {
      test('always returns valid', () {
        expect(validateOptionalField(null).isValid, true);
        expect(validateOptionalField('').isValid, true);
        expect(validateOptionalField('값').isValid, true);
      });
    });

    group('validateMinLength', () {
      test('returns valid when length meets minimum', () {
        final result = validateMinLength('abc', 3);
        expect(result.isValid, true);
      });

      test('returns invalid when too short', () {
        final result = validateMinLength('ab', 3);
        expect(result.isValid, false);
      });

      test('returns invalid for null', () {
        final result = validateMinLength(null, 1);
        expect(result.isValid, false);
      });

      test('uses custom error message', () {
        final result = validateMinLength('a', 5, '5자 이상');
        expect(result.errorMessage, '5자 이상');
      });
    });

    group('validateNumericRange', () {
      test('returns valid when in range', () {
        final result = validateNumericRange<int>(5, 1, 10);
        expect(result.isValid, true);
      });

      test('returns valid at boundaries', () {
        expect(validateNumericRange<int>(1, 1, 10).isValid, true);
        expect(validateNumericRange<int>(10, 1, 10).isValid, true);
      });

      test('returns invalid when below range', () {
        final result = validateNumericRange<int>(0, 1, 10);
        expect(result.isValid, false);
      });

      test('returns invalid when above range', () {
        final result = validateNumericRange<int>(11, 1, 10);
        expect(result.isValid, false);
      });

      test('returns invalid for null', () {
        final result = validateNumericRange<int>(null, 1, 10);
        expect(result.isValid, false);
      });
    });
  });
}
