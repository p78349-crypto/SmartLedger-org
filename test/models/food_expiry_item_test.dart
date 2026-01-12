import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/food_expiry_item.dart';

void main() {
  group('FoodExpiryItem', () {
    test('creates with required fields', () {
      final item = FoodExpiryItem(
        id: 'food-1',
        name: '우유',
        purchaseDate: DateTime(2026),
        expiryDate: DateTime(2026, 1, 10),
        createdAt: DateTime(2026),
      );

      expect(item.id, 'food-1');
      expect(item.name, '우유');
      expect(item.quantity, 1.0); // 기본값
      expect(item.unit, '개'); // 기본값
      expect(item.category, '기타'); // 기본값
      expect(item.location, '냉장'); // 기본값
    });

    test('creates with all fields', () {
      final item = FoodExpiryItem(
        id: 'food-2',
        name: '돼지고기',
        purchaseDate: DateTime(2026, 1, 5),
        expiryDate: DateTime(2026, 1, 12),
        createdAt: DateTime(2026, 1, 5),
        memo: '삼겹살',
        quantity: 500,
        unit: 'g',
        category: '육류',
        location: '냉동',
        price: 15000,
        supplier: '이마트',
        healthTags: const ['단백질'],
      );

      expect(item.memo, '삼겹살');
      expect(item.quantity, 500);
      expect(item.unit, 'g');
      expect(item.category, '육류');
      expect(item.location, '냉동');
      expect(item.price, 15000);
      expect(item.supplier, '이마트');
      expect(item.healthTags, ['단백질']);
    });

    group('daysLeft', () {
      test('returns positive days for future expiry', () {
        final item = FoodExpiryItem(
          id: 'food-1',
          name: '우유',
          purchaseDate: DateTime(2026),
          expiryDate: DateTime(2026, 1, 10),
          createdAt: DateTime(2026),
        );

        final now = DateTime(2026, 1, 5);
        expect(item.daysLeft(now), 5);
      });

      test('returns zero for today expiry', () {
        final item = FoodExpiryItem(
          id: 'food-1',
          name: '우유',
          purchaseDate: DateTime(2026),
          expiryDate: DateTime(2026, 1, 5),
          createdAt: DateTime(2026),
        );

        final now = DateTime(2026, 1, 5);
        expect(item.daysLeft(now), 0);
      });

      test('returns negative for expired item', () {
        final item = FoodExpiryItem(
          id: 'food-1',
          name: '우유',
          purchaseDate: DateTime(2026),
          expiryDate: DateTime(2026, 1, 5),
          createdAt: DateTime(2026),
        );

        final now = DateTime(2026, 1, 8);
        expect(item.daysLeft(now), -3);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final item = FoodExpiryItem(
          id: 'food-1',
          name: '계란',
          purchaseDate: DateTime(2026),
          expiryDate: DateTime(2026, 1, 20),
          createdAt: DateTime(2026),
          quantity: 30,
          category: '유제품',
          price: 8000,
          supplier: '농협',
          healthTags: const ['단백질', '콜레스테롤'],
        );

        final json = item.toJson();

        expect(json['id'], 'food-1');
        expect(json['name'], '계란');
        expect(json['quantity'], 30);
        expect(json['unit'], '개');
        expect(json['category'], '유제품');
        expect(json['price'], 8000);
        expect(json['healthTags'], ['단백질', '콜레스테롤']);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'id': 'food-1',
          'name': '치즈',
          'purchaseDate': '2026-01-01T00:00:00.000',
          'expiryDate': '2026-02-01T00:00:00.000',
          'createdAt': '2026-01-01T00:00:00.000',
          'memo': '모짜렐라',
          'quantity': 200.0,
          'unit': 'g',
          'category': '유제품',
          'location': '냉장',
          'price': 5000.0,
          'supplier': '코스트코',
          'healthTags': ['칼슘'],
        };

        final item = FoodExpiryItem.fromJson(json);

        expect(item.id, 'food-1');
        expect(item.name, '치즈');
        expect(item.memo, '모짜렐라');
        expect(item.quantity, 200.0);
        expect(item.category, '유제품');
        expect(item.healthTags, ['칼슘']);
      });
    });

    group('copyWith', () {
      test('updates specified fields', () {
        final original = FoodExpiryItem(
          id: 'food-1',
          name: '우유',
          purchaseDate: DateTime(2026),
          expiryDate: DateTime(2026, 1, 10),
          createdAt: DateTime(2026),
        );

        final updated = original.copyWith(
          name: '저지방 우유',
          quantity: 2,
        );

        expect(updated.id, 'food-1');
        expect(updated.name, '저지방 우유');
        expect(updated.quantity, 2);
      });
    });
  });
}
