import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/asset.dart';
import 'package:smart_ledger/utils/asset_icon_utils.dart';

void main() {
  group('AssetIconUtils', () {
    group('getIcon', () {
      test('returns icon for stock category', () {
        final icon = AssetIconUtils.getIcon(AssetCategory.stock);
        expect(icon.id, 'asset_stock');
        expect(icon.label, 'Stock');
        expect(icon.icon, isA<IconData>());
      });

      test('returns icon for all categories', () {
        for (final category in AssetCategory.values) {
          final icon = AssetIconUtils.getIcon(category);
          expect(icon, isNotNull);
          expect(icon.id, isNotEmpty);
          expect(icon.label, isNotEmpty);
        }
      });
    });

    group('getIconData', () {
      test('returns IconData for each category', () {
        for (final category in AssetCategory.values) {
          final iconData = AssetIconUtils.getIconData(category);
          expect(iconData, isA<IconData>());
        }
      });
    });

    group('getLabel', () {
      test('returns label for stock', () {
        expect(AssetIconUtils.getLabel(AssetCategory.stock), 'Stock');
      });

      test('returns label for bond', () {
        expect(AssetIconUtils.getLabel(AssetCategory.bond), 'Bond');
      });

      test('returns label for realEstate', () {
        expect(AssetIconUtils.getLabel(AssetCategory.realEstate), 'Real estate');
      });

      test('returns label for deposit', () {
        expect(AssetIconUtils.getLabel(AssetCategory.deposit), 'Deposit');
      });

      test('returns label for crypto', () {
        expect(AssetIconUtils.getLabel(AssetCategory.crypto), 'Crypto');
      });

      test('returns label for cash', () {
        expect(AssetIconUtils.getLabel(AssetCategory.cash), 'Cash');
      });

      test('returns label for other', () {
        expect(AssetIconUtils.getLabel(AssetCategory.other), 'Other');
      });
    });

    group('getAllIcons', () {
      test('returns all category icons', () {
        final icons = AssetIconUtils.getAllIcons();
        expect(icons.length, AssetCategory.values.length);
      });

      test('all icons have unique ids', () {
        final icons = AssetIconUtils.getAllIcons();
        final ids = icons.map((i) => i.id).toSet();
        expect(ids.length, icons.length);
      });
    });
  });

  group('AssetCategoryIcon', () {
    test('creates with all required fields', () {
      const icon = AssetCategoryIcon(
        id: 'test_id',
        label: 'Test Label',
        icon: Icons.star,
      );

      expect(icon.id, 'test_id');
      expect(icon.label, 'Test Label');
      expect(icon.icon, Icons.star);
    });
  });
}
