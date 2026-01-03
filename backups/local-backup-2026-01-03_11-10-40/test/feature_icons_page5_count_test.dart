import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/screens/feature_icons_catalog_screen.dart';
import 'package:smart_ledger/utils/main_feature_icon_catalog.dart';

void main() {
  testWidgets('Page 5 (asset) icons render with expected labels',
      (WidgetTester tester) async {
    // Ensure page 4 (asset) exists (pages[4] = UI page 5)
    expect(MainFeatureIconCatalog.pages.length > 4, isTrue);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ko'),
        supportedLocales: [Locale('ko'), Locale('en')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: FeatureIconsCatalogScreen(),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(FeatureIconsCatalogScreen));
    // pages[4] = 자산 (Asset) - UI page 5
    final expectedLabels = MainFeatureIconCatalog.pages[4]
        .items
        .map((e) => e.labelFor(context))
        .toList();

    // Scroll until the '자산 (Assets)' section (pages[4]) is visible.
    final sectionFinder = find.text('자산 (Assets)');
    await tester.scrollUntilVisible(
      sectionFinder,
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Scope assertions to the '자산' section to avoid collisions when
    // the same label exists on other pages.
    final assetSection = find
        .ancestor(of: sectionFinder, matching: find.byType(Column))
        .first;

    // Verify each expected label for page 5 is present in the widget tree.
    for (final label in expectedLabels) {
      expect(find.descendant(of: assetSection, matching: find.text(label)),
          findsOneWidget);
    }
  });
}

