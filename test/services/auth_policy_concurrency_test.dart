import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/asset_password_service.dart';
import 'package:smart_ledger/services/asset_pin_service.dart';
import 'package:smart_ledger/services/root_pin_service.dart';
import 'package:smart_ledger/services/user_password_service.dart';
import 'package:smart_ledger/services/user_pin_service.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

void main() {
  group('Auth policy concurrency', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('UserPinService counts concurrent failed attempts', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = UserPinService();

      await service.setPin(prefs, pin: '1234', iterations: 1);

      await Future.wait([
        service.verifyPinWithPolicy(prefs, pin: '0000'),
        service.verifyPinWithPolicy(prefs, pin: '0000'),
      ]);

      final attempts = prefs.getInt(PrefKeys.userPinFailedAttempts);
      expect(attempts, 2);
    });

    test('UserPasswordService counts concurrent failed attempts', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = UserPasswordService();

      await service.setPassword(prefs, password: 'secret', iterations: 1);

      await Future.wait([
        service.verifyPasswordWithPolicy(prefs, password: 'wrong'),
        service.verifyPasswordWithPolicy(prefs, password: 'wrong'),
      ]);

      final attempts = prefs.getInt(PrefKeys.userPasswordFailedAttempts);
      expect(attempts, 2);
    });

    test('UserPinService serializes across instances', () async {
      final prefs = await SharedPreferences.getInstance();
      final serviceA = UserPinService();
      final serviceB = UserPinService();

      await serviceA.setPin(prefs, pin: '1234', iterations: 1);

      await Future.wait([
        serviceA.verifyPinWithPolicy(prefs, pin: '0000'),
        serviceB.verifyPinWithPolicy(prefs, pin: '0000'),
      ]);

      final attempts = prefs.getInt(PrefKeys.userPinFailedAttempts);
      expect(attempts, 2);
    });

    test('UserPasswordService serializes across instances', () async {
      final prefs = await SharedPreferences.getInstance();
      final serviceA = UserPasswordService();
      final serviceB = UserPasswordService();

      await serviceA.setPassword(prefs, password: 'secret', iterations: 1);

      await Future.wait([
        serviceA.verifyPasswordWithPolicy(prefs, password: 'wrong'),
        serviceB.verifyPasswordWithPolicy(prefs, password: 'wrong'),
      ]);

      final attempts = prefs.getInt(PrefKeys.userPasswordFailedAttempts);
      expect(attempts, 2);
    });

    test('RootPinService serializes pin policy across instances', () async {
      final prefs = await SharedPreferences.getInstance();
      final serviceA = RootPinService();
      final serviceB = RootPinService();

      await serviceA.setPin(prefs, pin: '1234', iterations: 1);

      await Future.wait([
        serviceA.verifyPinWithPolicy(prefs, pin: '0000'),
        serviceB.verifyPinWithPolicy(prefs, pin: '0000'),
      ]);

      final attempts = prefs.getInt(PrefKeys.rootPinFailedAttempts);
      expect(attempts, 2);
    });

    test(
      'RootPinService serializes password policy across instances',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final serviceA = RootPinService();
        final serviceB = RootPinService();

        await serviceA.setPassword(prefs, password: 'root', iterations: 1);

        await Future.wait([
          serviceA.verifyPasswordWithPolicy(prefs, password: 'wrong'),
          serviceB.verifyPasswordWithPolicy(prefs, password: 'wrong'),
        ]);

        final attempts = prefs.getInt(PrefKeys.rootPasswordFailedAttempts);
        expect(attempts, 2);
      },
    );

    test('AssetPinService serializes pin policy across instances', () async {
      final prefs = await SharedPreferences.getInstance();
      final serviceA = AssetPinService();
      final serviceB = AssetPinService();

      await serviceA.setPin(prefs, pin: '1234', iterations: 1);

      await Future.wait([
        serviceA.verifyPinWithPolicy(prefs, pin: '0000'),
        serviceB.verifyPinWithPolicy(prefs, pin: '0000'),
      ]);

      final attempts = prefs.getInt(PrefKeys.assetPinFailedAttempts);
      expect(attempts, 2);
    });

    test(
      'AssetPasswordService serializes password policy across instances',
      () async {
        final prefs = await SharedPreferences.getInstance();
        final serviceA = AssetPasswordService();
        final serviceB = AssetPasswordService();

        await serviceA.setPassword(prefs, password: 'asset', iterations: 1);

        await Future.wait([
          serviceA.verifyPasswordWithPolicy(prefs, password: 'wrong'),
          serviceB.verifyPasswordWithPolicy(prefs, password: 'wrong'),
        ]);

        final attempts = prefs.getInt(PrefKeys.assetPasswordFailedAttempts);
        expect(attempts, 2);
      },
    );
  });
}
