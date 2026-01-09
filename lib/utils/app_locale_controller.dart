import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pref_keys.dart';

class AppLocaleController {
  AppLocaleController._();

  static final AppLocaleController instance = AppLocaleController._();

  /// When null, follow system locale.
  final ValueNotifier<Locale?> locale = ValueNotifier<Locale?>(null);

  static const String systemCode = 'system';

  static Locale? _localeFromCode(String code) {
    switch (code) {
      case 'ko':
        return const Locale('ko', 'KR');
      case 'en':
        return const Locale('en', 'US');
      case 'ja':
        return const Locale('ja', 'JP');
      case systemCode:
      default:
        return null;
    }
  }

  static String _codeFromLocale(Locale? locale) {
    if (locale == null) return systemCode;
    return locale.languageCode;
  }

  Future<void> loadFromPrefs(SharedPreferences prefs) async {
    final code = prefs.getString(PrefKeys.language);
    if (code == null || code == systemCode) {
      locale.value = null;
      return;
    }
    locale.value = _localeFromCode(code);
  }

  Future<void> setLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PrefKeys.language, code);
    locale.value = _localeFromCode(code);
  }

  String currentCode() {
    return _codeFromLocale(locale.value);
  }
}
