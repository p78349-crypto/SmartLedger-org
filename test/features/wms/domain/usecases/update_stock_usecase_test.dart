library;

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/features/wms/domain/usecases/update_stock_usecase.dart';
import 'package:smart_ledger/shared/errors.dart';
import 'package:smart_ledger/shared/result.dart';
import '../../mocks/fake_inventory_repository.dart';

void main() {
  group('UpdateStockUseCase', () {
    late FakeInventoryRepository repository;
    late UpdateStockUseCase useCase;

    setUp(() {
      repository = FakeInventoryRepository();
      useCase = UpdateStockUseCase(repository);
    });

    tearDown(() {
      repository.clear();
    });

    group('Validation Tests', () {
      test('Given empty name, When execute, Then returns ValidationError', () async {
        // Given
        final item = ConsumableInventoryItem(
          id: '1',
          name: '   ', // Empty after trim
          currentStock: 10.0,
          threshold: 5.0,
          unit: 'kg',
          category: 'Food',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // When
        final result = await useCase.execute(item);

        // Then
        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Should not succeed'),
          failure: (error) {
            expect(error, isA<ValidationError>());
            expect((error as ValidationError).message, contains('name cannot be empty'));
          },
        );
      });

      test('Given negative stock, When execute, Then returns ValidationError', () async {
        // Given
        final item = ConsumableInventoryItem(
          id: '2',
          name: 'Rice',
          currentStock: -5.0, // Negative stock
          threshold: 5.0,
          unit: 'kg',
          category: 'Food',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // When
        final result = await useCase.execute(item);

        // Then
        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Should not succeed'),
          failure: (error) {
            expect(error, isA<ValidationError>());
            expect((error as ValidationError).message, contains('stock cannot be negative'));
          },
        );
      });

      test('Given negative threshold, When execute, Then returns ValidationError', () async {
        // Given
        final item = ConsumableInventoryItem(
          id: '3',
          name: 'Sugar',
          currentStock: 10.0,
          threshold: -2.0, // Negative threshold
          unit: 'kg',
          category: 'Food',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // When
        final result = await useCase.execute(item);

        // Then
        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Should not succeed'),
          failure: (error) {
            expect(error, isA<ValidationError>());
            expect((error as ValidationError).message, contains('threshold cannot be negative'));
          },
        );
      });
    });

    group('Success Tests', () {
      test('Given valid item, When execute, Then updates item successfully', () async {
        // Given
        final originalItem = ConsumableInventoryItem(
          id: '4',
          name: 'Flour',
          currentStock: 25.0,
          threshold: 10.0,
          unit: 'kg',
          category: 'Food',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
        repository.seed([originalItem]);

        final updatedItem = originalItem.copyWith(
          currentStock: 50.0,
          threshold: 15.0,
        );

        // When
        final result = await useCase.execute(updatedItem);

        // Then
        expect(result.isSuccess, isTrue);
        result.when(
          success: (item) {
            expect(item.id, '4');
            expect(item.name, 'Flour');
            expect(item.currentStock, 50.0);
            expect(item.threshold, 15.0);
          },
          failure: (_) => fail('Should not fail'),
        );
      });

      test('Given item with name change, When execute, Then updates name', () async {
        // Given
        final originalItem = ConsumableInventoryItem(
          id: '5',
          name: 'Salt',
          currentStock: 5.0,
          threshold: 2.0,
          unit: 'kg',
          category: 'Food',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
        repository.seed([originalItem]);

        final updatedItem = originalItem.copyWith(name: 'Sea Salt');

        // When
        final result = await useCase.execute(updatedItem);

        // Then
        expect(result.isSuccess, isTrue);
        result.when(
          success: (item) {
            expect(item.name, 'Sea Salt');
          },
          failure: (_) => fail('Should not fail'),
        );
      });
    });

    group('Not Found Tests', () {
      test('Given non-existent item, When execute, Then returns NotFoundError', () async {
        // Given
        final item = ConsumableInventoryItem(
          id: 'non-existent',
          name: 'Coffee',
          currentStock: 15.0,
          threshold: 5.0,
          unit: 'kg',
          category: 'Food',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        // When
        final result = await useCase.execute(item);

        // Then
        expect(result.isFailure, isTrue);
        result.when(
          success: (_) => fail('Should not succeed'),
          failure: (error) {
            expect(error, isA<NotFoundError>());
          },
        );
      });
    });

    group('Repository Failure Tests', () {
      test('Given repository fails, When execute, Then returns NetworkError', () async {
        // Given
        final item = ConsumableInventoryItem(
          id: '6',
          name: 'Tea',
          currentStock: 20.0,
          threshold: 8.0,
          unit: 'kg',
          category: 'Food',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
        );
        repository.seed([item]);
        repository.shouldFailOnUpdate = true;

        // When
        final result = await useCase.execute(item);

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
