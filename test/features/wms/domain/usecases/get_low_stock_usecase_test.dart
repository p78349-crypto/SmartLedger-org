library;

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/features/wms/domain/usecases/get_low_stock_usecase.dart';
import 'package:smart_ledger/shared/errors.dart';
import 'package:smart_ledger/shared/result.dart';
import '../../mocks/fake_inventory_repository.dart';

void main() {
  group('GetLowStockUseCase', () {
    late FakeInventoryRepository repository;
    late GetLowStockUseCase useCase;

    setUp(() {
      repository = FakeInventoryRepository();
      useCase = GetLowStockUseCase(repository);
    });

    tearDown(() {
      repository.clear();
    });

    group('Success Tests', () {
      test('Given empty repository, When execute, Then returns empty list', () async {
        // Given: Repository is empty (default state)

        // When
        final result = await useCase.execute();

        // Then
        expect(result.isSuccess, isTrue);
        result.when(
          success: (items) {
            expect(items, isEmpty);
          },
          failure: (_) => fail('Should not fail'),
        );
      });

      test('Given items with stock below threshold, When execute, Then returns those items', () async {
        // Given
        final items = [
          ConsumableInventoryItem(
            id: '1',
            name: 'Rice',
            currentStock: 5.0, // Below threshold
            threshold: 10.0,
            unit: 'kg',
            category: 'Food',
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
          ConsumableInventoryItem(
            id: '2',
            name: 'Flour',
            currentStock: 50.0, // Above threshold
            threshold: 10.0,
            unit: 'kg',
            category: 'Food',
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
          ConsumableInventoryItem(
            id: '3',
            name: 'Sugar',
            currentStock: 8.0, // Exactly at threshold
            threshold: 8.0,
            unit: 'kg',
            category: 'Food',
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
        ];
        repository.seed(items);

        // When
        final result = await useCase.execute();

        // Then
        expect(result.isSuccess, isTrue);
        result.when(
          success: (lowStockItems) {
            expect(lowStockItems.length, 2); // Rice and Sugar
            expect(lowStockItems.any((item) => item.id == '1'), isTrue);
            expect(lowStockItems.any((item) => item.id == '2'), isFalse);
            expect(lowStockItems.any((item) => item.id == '3'), isTrue);
          },
          failure: (_) => fail('Should not fail'),
        );
      });

      test('Given all items above threshold, When execute, Then returns empty list', () async {
        // Given
        final items = [
          ConsumableInventoryItem(
            id: '1',
            name: 'Rice',
            currentStock: 50.0,
            threshold: 10.0,
            unit: 'kg',
            category: 'Food',
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
          ConsumableInventoryItem(
            id: '2',
            name: 'Flour',
            currentStock: 100.0,
            threshold: 20.0,
            unit: 'kg',
            category: 'Food',
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
        ];
        repository.seed(items);

        // When
        final result = await useCase.execute();

        // Then
        expect(result.isSuccess, isTrue);
        result.when(
          success: (lowStockItems) {
            expect(lowStockItems, isEmpty);
          },
          failure: (_) => fail('Should not fail'),
        );
      });

      test('Given all items below threshold, When execute, Then returns all items', () async {
        // Given
        final items = [
          ConsumableInventoryItem(
            id: '1',
            name: 'Rice',
            currentStock: 5.0,
            threshold: 10.0,
            unit: 'kg',
            category: 'Food',
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
          ConsumableInventoryItem(
            id: '2',
            name: 'Flour',
            currentStock: 3.0,
            threshold: 20.0,
            unit: 'kg',
            category: 'Food',
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
          ConsumableInventoryItem(
            id: '3',
            name: 'Sugar',
            threshold: 5.0,
            unit: 'kg',
            category: 'Food',
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
        ];
        repository.seed(items);

        // When
        final result = await useCase.execute();

        // Then
        expect(result.isSuccess, isTrue);
        result.when(
          success: (lowStockItems) {
            expect(lowStockItems.length, 3);
          },
          failure: (_) => fail('Should not fail'),
        );
      });

      test('Given item with zero stock, When execute, Then includes that item', () async {
        // Given
        final item = ConsumableInventoryItem(
          id: '1',
          name: 'Salt',
          threshold: 5.0,
          unit: 'kg',
          category: 'Food',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
        repository.seed([item]);

        // When
        final result = await useCase.execute();

        // Then
        expect(result.isSuccess, isTrue);
        result.when(
          success: (lowStockItems) {
            expect(lowStockItems.length, 1);
            expect(lowStockItems.first.currentStock, 0.0);
          },
          failure: (_) => fail('Should not fail'),
        );
      });
    });

    group('Repository Failure Tests', () {
      test('Given repository fails, When execute, Then returns NetworkError', () async {
        // Given
        repository.shouldFailOnFetch = true;

        // When
        final result = await useCase.execute();

        // Then
        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Should not succeed'),
          failure: (error) {
            expect(error, isA<NetworkError>());
          },
        );
      });
    });
  });
}
