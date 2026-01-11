import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smart_ledger/utils/localized_date_formatter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR', null);
    await initializeDateFormatting('en_US', null);
  });
  group('LocalizedDateFormatter', () {
    testWidgets('yM formats date with locale', (tester) async {
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('ko', 'KR'),
          delegates: const <LocalizationsDelegate<dynamic>>[
            DefaultWidgetsLocalizations.delegate,
          ],
          child: Builder(
            builder: (context) {
              final formatted = LocalizedDateFormatter.yM(
                context,
                DateTime(2026, 1, 11),
              );
              expect(formatted, isNotEmpty);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('yMd formats date with locale', (tester) async {
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('ko', 'KR'),
          delegates: const <LocalizationsDelegate<dynamic>>[
            DefaultWidgetsLocalizations.delegate,
          ],
          child: Builder(
            builder: (context) {
              final formatted = LocalizedDateFormatter.yMd(
                context,
                DateTime(2026, 1, 11),
              );
              expect(formatted, isNotEmpty);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('md formats date with locale', (tester) async {
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('ko', 'KR'),
          delegates: const <LocalizationsDelegate<dynamic>>[
            DefaultWidgetsLocalizations.delegate,
          ],
          child: Builder(
            builder: (context) {
              final formatted = LocalizedDateFormatter.md(
                context,
                DateTime(2026, 1, 11),
              );
              expect(formatted, isNotEmpty);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('y formats year with locale', (tester) async {
      await tester.pumpWidget(
        Localizations(
          locale: const Locale('ko', 'KR'),
          delegates: const <LocalizationsDelegate<dynamic>>[
            DefaultWidgetsLocalizations.delegate,
          ],
          child: Builder(
            builder: (context) {
              final formatted = LocalizedDateFormatter.y(context, 2026);
              expect(formatted, contains('2026'));
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
