import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/shopping_cart_item.dart';

void main() {
  group('ShoppingCartItem', () {
    final now = DateTime(2026, 1, 11);

    test('creates with required fields', () {
      final item = ShoppingCartItem(
        id: 'item-1',
        name: '우유',
        createdAt: now,
        updatedAt: now,
      );

      expect(item.id, 'item-1');
      expect(item.name, '우유');
      expect(item.quantity, 1); // 기본값
      expect(item.unitPrice, 0); // 기본값
      expect(item.isPlanned, isTrue); // 기본값
      expect(item.isChecked, isFalse); // 기본값
    });

    test('creates with all fields', () {
      final item = ShoppingCartItem(
        id: 'item-2',
        name: '계란',
        quantity: 2,
        unitPrice: 8000,
        unitLabel: '판',
        bundleCount: 2,
        unitsPerBundle: 30,
        memo: '유정란',
        storeLocation: '냉장 코너',
        isChecked: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(item.quantity, 2);
      expect(item.unitPrice, 8000);
      expect(item.unitLabel, '판');
      expect(item.bundleCount, 2);
      expect(item.unitsPerBundle, 30);
      expect(item.memo, '유정란');
      expect(item.storeLocation, '냉장 코너');
      expect(item.isChecked, isTrue);
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final original = ShoppingCartItem(
          id: 'item-1',
          name: '우유',
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(
          quantity: 3,
          isChecked: true,
        );

        expect(updated.id, 'item-1');
        expect(updated.name, '우유');
        expect(updated.quantity, 3);
        expect(updated.isChecked, isTrue);
      });

      test('preserves unspecified fields', () {
        final original = ShoppingCartItem(
          id: 'item-1',
          name: '사과',
          quantity: 5,
          unitPrice: 1000,
          memo: '아삭한 것',
          createdAt: now,
          updatedAt: now,
        );

        final updated = original.copyWith(isChecked: true);

        expect(updated.name, '사과');
        expect(updated.quantity, 5);
        expect(updated.unitPrice, 1000);
        expect(updated.memo, '아삭한 것');
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final item = ShoppingCartItem(
          id: 'item-1',
          name: '빵',
          quantity: 2,
          unitPrice: 3500,
          memo: '식빵',
          createdAt: now,
          updatedAt: now,
        );

        final json = item.toJson();

        expect(json['id'], 'item-1');
        expect(json['name'], '빵');
        expect(json['quantity'], 2);
        expect(json['unitPrice'], 3500);
        expect(json['memo'], '식빵');
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'id': 'item-1',
          'name': '바나나',
          'quantity': 1,
          'unitPrice': 5000.0,
          'unitLabel': '송이',
          'bundleCount': 1,
          'unitsPerBundle': 1,
          'memo': '델몬트',
          'storeLocation': '과일 코너',
          'isPlanned': true,
          'isChecked': false,
          'createdAt': '2026-01-11T00:00:00.000',
          'updatedAt': '2026-01-11T00:00:00.000',
        };

        final item = ShoppingCartItem.fromJson(json);

        expect(item.id, 'item-1');
        expect(item.name, '바나나');
        expect(item.unitPrice, 5000);
        expect(item.unitLabel, '송이');
        expect(item.memo, '델몬트');
        expect(item.storeLocation, '과일 코너');
      });
    });

    test('bundleCount defaults to quantity when not specified', () {
      final item = ShoppingCartItem(
        id: 'item-1',
        name: '물',
        quantity: 6,
        createdAt: now,
        updatedAt: now,
      );

      expect(item.bundleCount, 6);
    });

    test('unitsPerBundle defaults to 1 when not specified', () {
      final item = ShoppingCartItem(
        id: 'item-1',
        name: '과자',
        quantity: 3,
        createdAt: now,
        updatedAt: now,
      );

      expect(item.unitsPerBundle, 1);
    });
  });
}
