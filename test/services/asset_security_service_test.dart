import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/asset_security_service.dart';

void main() {
  group('AssetSecurityService', () {
    setUp(() {
      // SharedPreferences 목업 초기화
      SharedPreferences.setMockInitialValues({});
    });

    test('isLocked returns false by default', () async {
      final locked = await AssetSecurityService.isLocked('TestAccount');
      expect(locked, isFalse);
    });

    test('setLocked stores lock state correctly', () async {
      await AssetSecurityService.setLocked('TestAccount', true);
      final locked = await AssetSecurityService.isLocked('TestAccount');
      expect(locked, isTrue);
    });

    test('setLocked can unlock account', () async {
      await AssetSecurityService.setLocked('TestAccount', true);
      expect(await AssetSecurityService.isLocked('TestAccount'), isTrue);

      await AssetSecurityService.setLocked('TestAccount', false);
      expect(await AssetSecurityService.isLocked('TestAccount'), isFalse);
    });

    test('different accounts have separate lock states', () async {
      await AssetSecurityService.setLocked('Account1', true);
      await AssetSecurityService.setLocked('Account2', false);

      expect(await AssetSecurityService.isLocked('Account1'), isTrue);
      expect(await AssetSecurityService.isLocked('Account2'), isFalse);
    });

    test('authenticateAndUnlock unlocks the account', () async {
      await AssetSecurityService.setLocked('TestAccount', true);
      expect(await AssetSecurityService.isLocked('TestAccount'), isTrue);

      final result =
          await AssetSecurityService.authenticateAndUnlock('TestAccount');
      expect(result, isTrue);
      expect(await AssetSecurityService.isLocked('TestAccount'), isFalse);
    });
  });
}
