import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/account_utils.dart';

void main() {
  group('AccountUtils', () {
    group('rootAccountName', () {
      test('is ROOT', () {
        expect(AccountUtils.rootAccountName, 'ROOT');
      });
    });

    group('isRootAccount', () {
      test('returns true for ROOT', () {
        expect(AccountUtils.isRootAccount('ROOT'), isTrue);
      });

      test('returns true for root (case insensitive)', () {
        expect(AccountUtils.isRootAccount('root'), isTrue);
        expect(AccountUtils.isRootAccount('Root'), isTrue);
        expect(AccountUtils.isRootAccount('rOOt'), isTrue);
      });

      test('returns false for other accounts', () {
        expect(AccountUtils.isRootAccount('user1'), isFalse);
        expect(AccountUtils.isRootAccount('admin'), isFalse);
        expect(AccountUtils.isRootAccount(''), isFalse);
      });
    });

    group('canAccessAccount', () {
      test('ROOT can access any account', () {
        expect(AccountUtils.canAccessAccount('ROOT', 'user1'), isTrue);
        expect(AccountUtils.canAccessAccount('ROOT', 'user2'), isTrue);
        expect(AccountUtils.canAccessAccount('ROOT', 'ROOT'), isTrue);
      });

      test('regular user can only access own account', () {
        expect(AccountUtils.canAccessAccount('user1', 'user1'), isTrue);
        expect(AccountUtils.canAccessAccount('user1', 'user2'), isFalse);
        expect(AccountUtils.canAccessAccount('user1', 'ROOT'), isFalse);
      });
    });

    group('isRootOnlyFeature', () {
      test('returns true for ROOT', () {
        expect(AccountUtils.isRootOnlyFeature('ROOT'), isTrue);
      });

      test('returns false for other accounts', () {
        expect(AccountUtils.isRootOnlyFeature('user1'), isFalse);
        expect(AccountUtils.isRootOnlyFeature('admin'), isFalse);
      });
    });
  });
}
