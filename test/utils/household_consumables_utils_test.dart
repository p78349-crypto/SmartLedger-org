import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/utils/household_consumables_utils.dart';

void main() {
  group('HouseholdConsumablesUtils', () {
    test('defaultItems has expected structure', () {
      const items = HouseholdConsumablesUtils.defaultItems;
      expect(items, isNotEmpty);

      final first = items.first;
      expect(first.name, isNotEmpty);
      expect(first.mainCategory, isNotEmpty);
      expect(first.subCategory, isNotEmpty);
      expect(first.icon, isA<IconData>());
      expect(first.defaultBundleSize, greaterThan(0));
    });

    test('defaultItems contain a known entry (toilet paper)', () {
      const items = HouseholdConsumablesUtils.defaultItems;
      final tp = items.where((e) => e.detailCategory == '두루마리 휴지').toList();
      expect(tp.length, 1);
      expect(tp.single.icon, Icons.layers);
      expect(tp.single.defaultBundleSize, 30.0);
    });
  });
}
