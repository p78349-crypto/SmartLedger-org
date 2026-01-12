import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/account.dart';

void main() {
  group('Account', () {
    test('creates with required name', () {
      final account = Account(name: '메인 계좌');

      expect(account.name, '메인 계좌');
      expect(account.carryoverAmount, 0);
      expect(account.overdraftAmount, 0);
      expect(account.lastCarryoverDate, isNull);
    });

    test('sets createdAt to now when not provided', () {
      final before = DateTime.now();
      final account = Account(name: '테스트');
      final after = DateTime.now();

      expect(account.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(account.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('creates with all fields', () {
      final createdAt = DateTime(2026);
      final lastCarryover = DateTime(2026, 1, 10);
      
      final account = Account(
        name: '가계부',
        createdAt: createdAt,
        carryoverAmount: 50000,
        overdraftAmount: 10000,
        lastCarryoverDate: lastCarryover,
      );

      expect(account.carryoverAmount, 50000);
      expect(account.overdraftAmount, 10000);
      expect(account.lastCarryoverDate, lastCarryover);
    });

    group('toJson', () {
      test('serializes all fields', () {
        final createdAt = DateTime(2026, 1, 5);
        final lastCarryover = DateTime(2026, 1, 10);
        
        final account = Account(
          name: '계좌',
          createdAt: createdAt,
          carryoverAmount: 30000,
          overdraftAmount: 5000,
          lastCarryoverDate: lastCarryover,
        );

        final json = account.toJson();

        expect(json['name'], '계좌');
        expect(json['createdAt'], createdAt.toIso8601String());
        expect(json['carryoverAmount'], 30000);
        expect(json['overdraftAmount'], 5000);
        expect(json['lastCarryoverDate'], lastCarryover.toIso8601String());
      });

      test('handles null lastCarryoverDate', () {
        final account = Account(name: '새계좌');

        final json = account.toJson();

        expect(json['lastCarryoverDate'], isNull);
      });
    });

    group('fromJson', () {
      test('parses complete JSON', () {
        final json = {
          'name': '복원계좌',
          'createdAt': '2026-01-05T00:00:00.000',
          'carryoverAmount': 25000.0,
          'overdraftAmount': 0.0,
          'lastCarryoverDate': '2026-01-08T12:00:00.000',
        };

        final account = Account.fromJson(json);

        expect(account.name, '복원계좌');
        expect(account.carryoverAmount, 25000);
        expect(account.overdraftAmount, 0);
        expect(account.lastCarryoverDate, isNotNull);
        expect(account.lastCarryoverDate!.day, 8);
      });

      test('handles missing optional fields', () {
        final json = {
          'name': '최소계좌',
        };

        final account = Account.fromJson(json);

        expect(account.name, '최소계좌');
        expect(account.carryoverAmount, 0);
        expect(account.overdraftAmount, 0);
        expect(account.lastCarryoverDate, isNull);
      });

      test('handles int amounts as double', () {
        final json = {
          'name': '계좌',
          'carryoverAmount': 10000, // int
          'overdraftAmount': 5000, // int
        };

        final account = Account.fromJson(json);

        expect(account.carryoverAmount, 10000.0);
        expect(account.overdraftAmount, 5000.0);
      });
    });

    test('serialization roundtrip preserves data', () {
      final original = Account(
        name: '왕복테스트',
        createdAt: DateTime(2026),
        carryoverAmount: 123456,
        overdraftAmount: 7890,
        lastCarryoverDate: DateTime(2026, 1, 10),
      );

      final json = original.toJson();
      final restored = Account.fromJson(json);

      expect(restored.name, original.name);
      expect(restored.carryoverAmount, original.carryoverAmount);
      expect(restored.overdraftAmount, original.overdraftAmount);
      expect(restored.lastCarryoverDate?.day, original.lastCarryoverDate?.day);
    });
  });
}
