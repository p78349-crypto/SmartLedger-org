import 'package:flutter/widgets.dart';

class AccountNameLanguageTag {
  static String _internationalCode(Locale locale) {
    final code = locale.languageCode.toLowerCase();

    // App-supported locales: show the codes users typically expect.
    switch (code) {
      case 'en':
        return 'EN';
      case 'ja':
        return 'JP';
      case 'ko':
        return 'KR';
      default:
        return code.toUpperCase();
    }
  }

  static String suffixForLocale(Locale locale) {
    // Use a leading space so it reads naturally and avoids collisions
    // with the base name (e.g., "My Account EN").
    return ' ${_internationalCode(locale)}';
  }

  static String applyForcedSuffix(String baseName, Locale locale) {
    final trimmed = baseName.trim();
    if (trimmed.isEmpty) return '';

    final suffix = suffixForLocale(locale);
    if (trimmed.toLowerCase().endsWith(suffix.toLowerCase())) {
      return trimmed;
    }
    return '$trimmed$suffix';
  }
}
