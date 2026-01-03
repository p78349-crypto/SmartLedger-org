import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/validators.dart';

void main() {
  group('Validators', () {
    group('required validation', () {
      test('should fail with null', () {
        final result = Validators.required(null);
        expect(result, isNotNull);
      });

      test('should fail with empty string', () {
        final result = Validators.required('');
        expect(result, isNotNull);
      });

      test('should fail with whitespace only', () {
        final result = Validators.required('   ');
        expect(result, isNotNull);
      });

      test('should pass with valid string', () {
        final result = Validators.required('John');
        expect(result, isNull);
      });

      test('should include field name in error message', () {
        final result = Validators.required('', fieldName: 'Name');
        expect(result, contains('Name'));
      });

      test('should use default field name if not provided', () {
        final result = Validators.required('', fieldName: null);
        expect(result, isNotNull);
        expect(result, contains('항목'));
      });
    });

    group('positiveNumber validation', () {
      test('should fail with non-numeric string', () {
        final result = Validators.positiveNumber('abc');
        expect(result, isNotNull);
      });

      test('should fail with negative number', () {
        final result = Validators.positiveNumber('-100');
        expect(result, isNotNull);
      });

      test('should fail with zero', () {
        final result = Validators.positiveNumber('0');
        expect(result, isNotNull);
      });

      test('should pass with positive integer', () {
        final result = Validators.positiveNumber('100');
        expect(result, isNull);
      });

      test('should pass with positive decimal', () {
        final result = Validators.positiveNumber('100.50');
        expect(result, isNull);
      });

      test('should pass with large positive number', () {
        final result = Validators.positiveNumber('1000000');
        expect(result, isNull);
      });

      test('should handle numbers with commas', () {
        final result = Validators.positiveNumber('1,000,000');
        expect(result, isNull); // Commas are handled
      });

      test('should fail with empty string', () {
        final result = Validators.positiveNumber('');
        expect(result, isNotNull);
      });
    });

    group('nonNegativeNumber validation', () {
      test('should fail with negative number', () {
        final result = Validators.nonNegativeNumber('-100');
        expect(result, isNotNull);
      });

      test('should pass with zero', () {
        final result = Validators.nonNegativeNumber('0');
        expect(result, isNull);
      });

      test('should pass with positive number', () {
        final result = Validators.nonNegativeNumber('100');
        expect(result, isNull);
      });

      test('should fail with non-numeric', () {
        final result = Validators.nonNegativeNumber('abc');
        expect(result, isNotNull);
      });

      test('should handle comma-separated numbers', () {
        final result = Validators.nonNegativeNumber('100,000');
        expect(result, isNull);
      });
    });

    group('integer validation', () {
      test('should pass with integer', () {
        final result = Validators.integer('100');
        expect(result, isNull);
      });

      test('should fail with decimal', () {
        final result = Validators.integer('100.5');
        expect(result, isNotNull);
      });

      test('should fail with non-numeric', () {
        final result = Validators.integer('abc');
        expect(result, isNotNull);
      });

      test('should pass with negative integer', () {
        final result = Validators.integer('-50');
        expect(result, isNull);
      });

      test('should handle comma-separated integers', () {
        final result = Validators.integer('1,000,000');
        expect(result, isNull);
      });
    });

    group('positiveInteger validation', () {
      test('should pass with positive integer', () {
        final result = Validators.positiveInteger('100');
        expect(result, isNull);
      });

      test('should fail with zero', () {
        final result = Validators.positiveInteger('0');
        expect(result, isNotNull);
      });

      test('should fail with negative', () {
        final result = Validators.positiveInteger('-50');
        expect(result, isNotNull);
      });

      test('should fail with decimal', () {
        final result = Validators.positiveInteger('99.5');
        expect(result, isNotNull);
      });

      test('should handle large numbers', () {
        final result = Validators.positiveInteger('9999999999');
        expect(result, isNull);
      });
    });

    group('accountName validation', () {
      test('should fail with short name', () {
        final result = Validators.accountName('A');
        expect(result, isNotNull);
      });

      test('should pass with 2 characters', () {
        final result = Validators.accountName('AB');
        expect(result, isNull);
      });

      test('should pass with normal name', () {
        final result = Validators.accountName('My Account');
        expect(result, isNull);
      });

      test('should fail with too long name', () {
        final result = Validators.accountName('A' * 21);
        expect(result, isNotNull);
      });

      test('should pass with 20 characters', () {
        final result = Validators.accountName('A' * 20);
        expect(result, isNull);
      });

      test('should fail with empty string', () {
        final result = Validators.accountName('');
        expect(result, isNotNull);
      });

      test('should fail with null', () {
        final result = Validators.accountName(null);
        expect(result, isNotNull);
      });
    });

    group('combined validations', () {
      test('should validate required and positive number', () {
        final requiredResult = Validators.required('');
        final positiveResult = Validators.positiveNumber('-50');

        expect(requiredResult, isNotNull);
        expect(positiveResult, isNotNull);
      });

      test('should pass both required and positive', () {
        final requiredResult = Validators.required('100');
        final positiveResult = Validators.positiveNumber('100');

        expect(requiredResult, isNull);
        expect(positiveResult, isNull);
      });

      test('should validate account name', () {
        final result = Validators.accountName('My Account');
        expect(result, isNull);
      });
    });

    group('edge cases', () {
      test('should handle very large numbers', () {
        final result = Validators.positiveNumber('9999999999999');
        expect(result, isNull);
      });

      test('should handle decimal places', () {
        final result = Validators.positiveNumber('99.99');
        expect(result, isNull);
      });

      test('should handle multiple spaces', () {
        final result = Validators.required('     hello     ');
        expect(result, isNull);
      });

      test('should reject null with custom field name', () {
        final result = Validators.required(null, fieldName: 'Email');
        expect(result, contains('Email'));
      });

      test('should handle zero properly', () {
        final nonNegResult = Validators.nonNegativeNumber('0');
        expect(nonNegResult, isNull);

        final posResult = Validators.positiveNumber('0');
        expect(posResult, isNotNull);
      });

      test('should handle negative numbers', () {
        final result = Validators.positiveNumber('-1');
        expect(result, isNotNull);
      });
    });
  });
}
