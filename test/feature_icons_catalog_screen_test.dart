import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/screens/feature_icons_catalog_screen.dart';
import 'package:smart_ledger/utils/main_feature_icon_catalog.dart';

void main() {
  testWidgets('FeatureIconsCatalogScreen renders pages or empty message', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: FeatureIconsCatalogScreen()),
    );

    // AppBar title should be present
    expect(find.text('기능 아이콘 카탈로그'), findsOneWidget);

    // Behavior depends on catalog content; assert accordingly
    if (MainFeatureIconCatalog.pageCount == 0) {
      expect(find.text('표시할 페이지가 없습니다'), findsOneWidget);
    } else {
      // There should be at least one GridView (page sections)
      expect(find.byType(GridView), findsWidgets);

      // And at least one Icon should be rendered inside tiles
      expect(find.byType(Icon), findsWidgets);
    }
  });
}
