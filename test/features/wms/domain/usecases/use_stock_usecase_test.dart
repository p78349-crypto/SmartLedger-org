/// Tests for UseStockUseCase
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/features/wms/domain/usecases/use_stock_usecase.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/shared/errors.dart';
import 'package:smart_ledger/shared/result.dart';
import '../../mocks/fake_inventory_repository.dart';

void main() {
  group('UseStockUseCase', () {
    late FakeInventoryRepository repository;
    late UseStockUseCase useCase;

    setUp(() {
      repository = FakeInventoryRepository();
      useCase = UseStockUseCase(repository);
    });

    tearDown(() {
      repository.clear();
    });

    group('Validation Tests', () {
      test(
        'Given empty item ID, When execute, Then returns ValidationError',
        () async {
          // Given
          const input = UseStockInput(itemId: '', amount: 1.0);

          // When
          final result = await useCase.execute(input);

          // Then
          expect(result.isFailure, isTrue);
          result.when(
            success: (_) => fail('Should not succeed'),
            failure: (error) {
              expect(error, isA<ValidationError>());
              expect(error.message, contains('Item ID cannot be empty'));
            },
          );
        },
      );

      test(
        'Given zero amount, When execute, Then returns ValidationError',
        () async {
          // Given
          const input = UseStockInput(itemId: 'soap-1', amount: 0.0);

          // When
          final result = await useCase.execute(input);

          // Then
          expect(result.isFailure, isTrue);
          result.when(
            success: (_) => fail('Should not succeed'),
            failure: (error) {
              expect(error, isA<ValidationError>());
              expect(error.message, contains('Amount must be greater than 0'));
            },
          );
        },
      );

      test(
        'Given negative amount, When execute, Then returns ValidationError',
        () async {
          // Given
          const input = UseStockInput(itemId: 'soap-1', amount: -5.0);

          // When
          final result = await useCase.execute(input);

          // Then
          expect(result.isFailure, isTrue);
          result.when(
            success: (_) => fail('Should not succeed'),
            failure: (error) {
              expect(error, isA<ValidationError>());
              expect(error.message, contains('Amount must be greater than 0'));
            },
          );
        },
      );
    });

    group('Success Tests', () {
      test(
        'Given valid input, When execute, Then uses stock successfully',
        () async {
          // Given
          final item = ConsumableInventoryItem(
            id: 'soap-1',
            name: '비누',
            currentStock: 10.0,
            threshold: 2.0,
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          );
          repository.seed([item]);

          const input = UseStockInput(
            itemId: 'soap-1',
            amount: 3.0,
            purpose: 'Daily use',
          );

          // When
          final result = await useCase.execute(input);

          // Then
          expect(result.isSuccess, isTrue);
          result.when(
            success: (unit) {
              // Verify stock was actually reduced
              final updatedItem = repository.items.firstWhere(
                (i) => i.id == 'soap-1',
              );
              expect(updatedItem.currentStock, 7.0); // 10 - 3 = 7
            },
            failure: (error) => fail('Should not fail: ${error.message}'),
          );
        },
      );

      test(
        'Given using partial stock, When execute, Then remaining stock is correct',
        () async {
          // Given
          final item = ConsumableInventoryItem(
            id: 'shampoo-1',
            name: '샴푸',
            currentStock: 5.0,
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          );
          repository.seed([item]);

          const input = UseStockInput(itemId: 'shampoo-1', amount: 2.5);

          // When
          final result = await useCase.execute(input);

          // Then
          expect(result.isSuccess, isTrue);
          result.when(
            success: (_) {
              final updatedItem = repository.items.firstWhere(
                (i) => i.id == 'shampoo-1',
              );
              expect(updatedItem.currentStock, 2.5); // 5.0 - 2.5 = 2.5
            },
            failure: (error) => fail('Should not fail: ${error.message}'),
          );
        },
      );

      test(
        'Given using all stock, When execute, Then stock becomes zero',
        () async {
          // Given
          final item = ConsumableInventoryItem(
            id: 'detergent-1',
            name: '세제',
            currentStock: 3.0,
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          );
          repository.seed([item]);

          const input = UseStockInput(
            itemId: 'detergent-1',
            amount: 3.0,
            purpose: 'Complete usage',
          );

          // When
          final result = await useCase.execute(input);

          // Then
          expect(result.isSuccess, isTrue);
          result.when(
            success: (_) {
              final updatedItem = repository.items.firstWhere(
                (i) => i.id == 'detergent-1',
              );
              expect(updatedItem.currentStock, 0.0);
            },
            failure: (error) => fail('Should not fail: ${error.message}'),
          );
        },
      );
    });

    group('Insufficient Stock Tests', () {
      test(
        'Given amount exceeds stock, When execute, Then returns ValidationError',
        () async {
          // Given
          final item = ConsumableInventoryItem(
            id: 'soap-1',
            name: '비누',
            currentStock: 2.0,
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          );
          repository.seed([item]);

          const input = UseStockInput(itemId: 'soap-1', amount: 5.0);

          // When
          final result = await useCase.execute(input);

          // Then
          expect(result.isFailure, isTrue);
          result.when(
            success: (_) => fail('Should not succeed'),
            failure: (error) {
              expect(error, isA<ValidationError>());
              expect(error.message, contains('Insufficient stock'));
              expect(error.message, contains('available 2.0'));
              expect(error.message, contains('requested 5.0'));
            },
          );
        },
      );

      test(
        'Given zero stock, When use any amount, Then returns ValidationError',
        () async {
          // Given
          final item = ConsumableInventoryItem(
            id: 'empty-1',
            name: '빈 재고',
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          );
          repository.seed([item]);

          const input = UseStockInput(itemId: 'empty-1', amount: 1.0);

          // When
          final result = await useCase.execute(input);

          // Then
          expect(result.isFailure, isTrue);
          result.when(
            success: (_) => fail('Should not succeed'),
            failure: (error) {
              expect(error, isA<ValidationError>());
              expect(error.message, contains('Insufficient stock'));
            },
          );
        },
      );
    });

    group('Not Found Tests', () {
      test(
        'Given non-existent item ID, When execute, Then returns NotFoundError',
        () async {
          // Given
          repository.seed([]); // Empty repository

          const input = UseStockInput(itemId: 'non-existent', amount: 1.0);

          // When
          final result = await useCase.execute(input);

          // Then
          expect(result.isFailure, isTrue);
          result.when(
            success: (_) => fail('Should not succeed'),
            failure: (error) {
              expect(error, isA<NotFoundError>());
              expect(error.message, contains('not found'));
            },
          );
        },
      );

      test(
        'Given repository with other items, When use non-existent, Then returns NotFoundError',
        () async {
          // Given
          final item = ConsumableInventoryItem(
            id: 'soap-1',
            name: '비누',
            currentStock: 10.0,
            threshold: 2.0,
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          );
          repository.seed([item]);

          const input = UseStockInput(itemId: 'shampoo-999', amount: 1.0);

          // When
          final result = await useCase.execute(input);

          // Then
          expect(result.isFailure, isTrue);
          result.when(
            success: (_) => fail('Should not succeed'),
            failure: (error) {
              expect(error, isA<NotFoundError>());
            },
          );
        },
      );
    });

    group('Repository Failure Tests', () {
      test(
        'Given repository fails on useStock, When execute, Then returns NetworkError',
        () async {
          // Given
          final item = ConsumableInventoryItem(
            id: 'soap-1',
            name: '비누',
            currentStock: 10.0,
            threshold: 2.0,
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          );
          repository.seed([item]);
          repository.shouldFailOnUse = true;

          const input = UseStockInput(itemId: 'soap-1', amount: 2.0);

          // When
          final result = await useCase.execute(input);

          // Then
          expect(result.isFailure, isTrue);
          result.when(
            success: (_) => fail('Should not succeed'),
            failure: (error) {
              expect(error, isA<NetworkError>());
            },
          );
        },
      );
    });
  });
}
