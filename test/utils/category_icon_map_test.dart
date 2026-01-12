import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/category_icon_map.dart';
import 'package:smart_ledger/utils/icon_catalog.dart';

void main() {
  group('CategoryIcon', () {
    group('getIcon', () {
      test('returns restaurant icon for 식비', () {
        final icon = CategoryIcon.getIcon('식비');
        expect(icon, IconCatalog.restaurant);
      });

      test('returns shoppingCart icon for 장보기', () {
        final icon = CategoryIcon.getIcon('장보기');
        expect(icon, IconCatalog.shoppingCart);
      });

      test('returns moveDown icon for 교통', () {
        final icon = CategoryIcon.getIcon('교통');
        expect(icon, IconCatalog.moveDown);
      });

      test('returns shoppingCart icon for 쇼핑', () {
        final icon = CategoryIcon.getIcon('쇼핑');
        expect(icon, IconCatalog.shoppingCart);
      });

      test('returns savings icon for 저축', () {
        final icon = CategoryIcon.getIcon('저축');
        expect(icon, IconCatalog.savings);
      });

      test('returns attachMoney icon for 수입', () {
        final icon = CategoryIcon.getIcon('수입');
        expect(icon, IconCatalog.attachMoney);
      });

      test('returns localOffer icon for 생활', () {
        final icon = CategoryIcon.getIcon('생활');
        expect(icon, IconCatalog.localOffer);
      });

      test('returns payment icon for 결제수단', () {
        final icon = CategoryIcon.getIcon('결제수단');
        expect(icon, IconCatalog.payment);
      });

      test('returns categoryOutlined icon for 기타', () {
        final icon = CategoryIcon.getIcon('기타');
        expect(icon, IconCatalog.categoryOutlined);
      });

      test('returns categoryOutlined for null category', () {
        final icon = CategoryIcon.getIcon(null);
        expect(icon, IconCatalog.categoryOutlined);
      });

      test('returns categoryOutlined for unknown category', () {
        final icon = CategoryIcon.getIcon('알수없는카테고리');
        expect(icon, IconCatalog.categoryOutlined);
      });

      test('returns categoryOutlined for empty string', () {
        final icon = CategoryIcon.getIcon('');
        expect(icon, IconCatalog.categoryOutlined);
      });
    });
  });
}
