import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/utils/app_locale_controller.dart';
import 'package:smart_ledger/utils/pref_keys.dart';

void main() {
  group('AppLocaleController', () {
    final controller = AppLocaleController.instance;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      controller.locale.value = null;
    });

    test('currentCode returns system when locale is null', () {
      expect(controller.currentCode(), AppLocaleController.systemCode);
    });

    test('loadFromPrefs sets locale to null when system/empty', () async {
      final prefs = await SharedPreferences.getInstance();

      await controller.loadFromPrefs(prefs);
      expect(controller.locale.value, isNull);

      await prefs.setString(PrefKeys.language, AppLocaleController.systemCode);
      await controller.loadFromPrefs(prefs);
      expect(controller.locale.value, isNull);
    });

    test('loadFromPrefs maps known language codes', () async {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(PrefKeys.language, 'en');
      await controller.loadFromPrefs(prefs);
      expect(controller.locale.value, const Locale('en', 'US'));

      await prefs.setString(PrefKeys.language, 'ko');
      await controller.loadFromPrefs(prefs);
      expect(controller.locale.value, const Locale('ko', 'KR'));

      await prefs.setString(PrefKeys.language, 'ja');
      await controller.loadFromPrefs(prefs);
      expect(controller.locale.value, const Locale('ja', 'JP'));
    });

    test('setLanguageCode persists and updates notifier', () async {
      await controller.setLanguageCode('ja');
      expect(controller.locale.value, const Locale('ja', 'JP'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(PrefKeys.language), 'ja');
      expect(controller.currentCode(), 'ja');
    });
  });
}
