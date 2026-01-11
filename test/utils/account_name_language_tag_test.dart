import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/account_name_language_tag.dart';

void main() {
  group('AccountNameLanguageTag', () {
    group('suffixForLocale', () {
      test('returns EN for English locale', () {
        const locale = Locale('en');
        expect(AccountNameLanguageTag.suffixForLocale(locale), ' EN');
      });

      test('returns JP for Japanese locale', () {
        const locale = Locale('ja');
        expect(AccountNameLanguageTag.suffixForLocale(locale), ' JP');
      });

      test('returns KR for Korean locale', () {
        const locale = Locale('ko');
        expect(AccountNameLanguageTag.suffixForLocale(locale), ' KR');
      });

      test('returns uppercase code for other locales', () {
        const locale = Locale('fr');
        expect(AccountNameLanguageTag.suffixForLocale(locale), ' FR');
      });

      test('handles locale with country code', () {
        const locale = Locale('en', 'US');
        expect(AccountNameLanguageTag.suffixForLocale(locale), ' EN');
      });
    });

    group('applyForcedSuffix', () {
      test('appends suffix to base name', () {
        const locale = Locale('en');
        final result =
            AccountNameLanguageTag.applyForcedSuffix('My Account', locale);
        expect(result, 'My Account EN');
      });

      test('returns empty string for empty base name', () {
        const locale = Locale('en');
        final result = AccountNameLanguageTag.applyForcedSuffix('', locale);
        expect(result, '');
      });

      test('returns empty string for whitespace-only base name', () {
        const locale = Locale('en');
        final result = AccountNameLanguageTag.applyForcedSuffix('   ', locale);
        expect(result, '');
      });

      test('trims whitespace from base name', () {
        const locale = Locale('ko');
        final result =
            AccountNameLanguageTag.applyForcedSuffix('  내 계좌  ', locale);
        expect(result, '내 계좌 KR');
      });

      test('does not duplicate suffix if already present', () {
        const locale = Locale('en');
        final result =
            AccountNameLanguageTag.applyForcedSuffix('My Account EN', locale);
        expect(result, 'My Account EN');
      });

      test('handles case-insensitive suffix check', () {
        const locale = Locale('en');
        final result =
            AccountNameLanguageTag.applyForcedSuffix('My Account en', locale);
        expect(result, 'My Account en');
      });

      test('appends JP suffix for Japanese locale', () {
        const locale = Locale('ja');
        final result =
            AccountNameLanguageTag.applyForcedSuffix('口座', locale);
        expect(result, '口座 JP');
      });
    });
  });
}
