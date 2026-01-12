import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/main_feature_icon_catalog.dart';

void main() {
  group('MainFeatureIconCatalog', () {
    testWidgets('MainFeatureIcon.labelFor respects locale and bilingualInKorean', (tester) async {
      const icon = MainFeatureIcon(
        id: 'x',
        label: '한국어',
        labelEn: 'English',
        icon: Icons.abc,
      );

      String? koLabel;
      String? koOnly;
      String? enLabel;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          supportedLocales: const [Locale('ko'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              koLabel = icon.labelFor(context);
              koOnly = icon.labelFor(context, bilingualInKorean: false);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          supportedLocales: const [Locale('ko'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) {
              enLabel = icon.labelFor(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(koLabel, '한국어 (English)');
      expect(koOnly, '한국어');
      expect(enLabel, 'English');
    });

    test('pageCount is 0 when blocked, restores when unblocked', () {
      final before = MainFeatureIconCatalog.pageCount;
      MainFeatureIconCatalog.setPagesBlocked(true);
      expect(MainFeatureIconCatalog.pageCount, 0);
      MainFeatureIconCatalog.setPagesBlocked(false);
      expect(MainFeatureIconCatalog.pageCount, before);
    });

    test('iconsForModuleKey returns items for known module', () {
      final items = MainFeatureIconCatalog.iconsForModuleKey('purchase');
      expect(items, isNotEmpty);
      expect(items.any((e) => e.routeName != null), isTrue);

      final unknown = MainFeatureIconCatalog.iconsForModuleKey('unknown_module');
      expect(unknown.length, greaterThanOrEqualTo(items.length));
    });
  });
}
