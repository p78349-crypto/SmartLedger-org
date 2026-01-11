import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/services/privacy_service.dart';

void main() {
  group('PrivacyService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('maskSensitive returns true by default', () {
      // 기본값은 true (민감 정보 마스킹)
      expect(PrivacyService.maskSensitive(), isTrue);
    });

    test('setMask changes mask state', () async {
      await PrivacyService.setMask(false);
      expect(PrivacyService.maskSensitive(), isFalse);

      await PrivacyService.setMask(true);
      expect(PrivacyService.maskSensitive(), isTrue);
    });

    test('load restores persisted value', () async {
      // 먼저 false로 설정
      await PrivacyService.setMask(false);
      expect(PrivacyService.maskSensitive(), isFalse);

      // load 후에도 값 유지
      await PrivacyService.load();
      expect(PrivacyService.maskSensitive(), isFalse);
    });
  });
}
