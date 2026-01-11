import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/localization_utils.dart';

void main() {
  Widget _buildWithLocale(Locale locale, Widget child) {
    return MaterialApp(
      locale: locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ko'),
        Locale('ja'),
        Locale('fr'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    );
  }

  group('LocalizationUtils', () {
    testWidgets('getCurrentLanguage returns languageCode', (tester) async {
      late String code;

      await tester.pumpWidget(
        _buildWithLocale(
          const Locale('ja'),
          Builder(
            builder: (context) {
              code = LocalizationUtils.getCurrentLanguage(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(code, 'ja');
    });

    testWidgets('tr returns translated value for key', (tester) async {
      late String ok;

      await tester.pumpWidget(
        _buildWithLocale(
          const Locale('en'),
          Builder(
            builder: (context) {
              ok = LocalizationUtils.tr(context, 'ok');
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(ok, 'OK');
    });

    testWidgets('tr substitutes placeholders', (tester) async {
      late String welcome;

      await tester.pumpWidget(
        _buildWithLocale(
          const Locale('ko'),
          Builder(
            builder: (context) {
              welcome = LocalizationUtils.tr(
                context,
                'welcome',
                args: {'name': '홍길동'},
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(welcome, '환영합니다, 홍길동님!');
    });

    testWidgets('tr falls back to ko translations for unsupported locale', (
      tester,
    ) async {
      late String ok;

      await tester.pumpWidget(
        _buildWithLocale(
          const Locale('fr'),
          Builder(
            builder: (context) {
              ok = LocalizationUtils.tr(context, 'ok');
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(ok, '확인');
    });

    testWidgets('formatCurrency formats per locale defaults', (tester) async {
      late String en;
      late String ja;
      late String ko;

      await tester.pumpWidget(
        _buildWithLocale(
          const Locale('en'),
          Builder(
            builder: (context) {
              en = LocalizationUtils.formatCurrency(context, 12.345);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        _buildWithLocale(
          const Locale('ja'),
          Builder(
            builder: (context) {
              ja = LocalizationUtils.formatCurrency(context, 12.0);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        _buildWithLocale(
          const Locale('ko'),
          Builder(
            builder: (context) {
              ko = LocalizationUtils.formatCurrency(context, 1234.0);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(en, r'$12.35');
      expect(ja, '¥12');
      expect(ko, '1234원');
    });

    testWidgets('formatCurrency respects custom symbol', (tester) async {
      late String value;

      await tester.pumpWidget(
        _buildWithLocale(
          const Locale('en'),
          Builder(
            builder: (context) {
              value = LocalizationUtils.formatCurrency(
                context,
                10.0,
                symbol: 'USD ',
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(value, 'USD 10.00');
    });

    testWidgets('plural returns tr(key) for ko/ja', (tester) async {
      late String ko;
      late String ja;

      await tester.pumpWidget(
        _buildWithLocale(
          const Locale('ko'),
          Builder(
            builder: (context) {
              ko = LocalizationUtils.plural(context, 'ok', 2);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        _buildWithLocale(
          const Locale('ja'),
          Builder(
            builder: (context) {
              ja = LocalizationUtils.plural(context, 'ok', 2);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(ko, '확인');
      expect(ja, 'OK');
    });
  });

  group('LocalizationExtension', () {
    testWidgets('context extension getters work', (tester) async {
      late String ok;
      late String code;
      late bool isEnglish;

      await tester.pumpWidget(
        _buildWithLocale(
          const Locale('en'),
          Builder(
            builder: (context) {
              ok = context.tr('ok');
              code = context.languageCode;
              isEnglish = context.isEnglish;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(ok, 'OK');
      expect(code, 'en');
      expect(isEnglish, true);
    });

    testWidgets('context.formatCurrency delegates to LocalizationUtils', (
      tester,
    ) async {
      late String value;

      await tester.pumpWidget(
        _buildWithLocale(
          const Locale('ko'),
          Builder(
            builder: (context) {
              value = context.formatCurrency(2000.0);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(value, '2000원');
    });
  });
}
