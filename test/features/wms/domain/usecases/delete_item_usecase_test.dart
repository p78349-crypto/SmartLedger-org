library;

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/features/wms/domain/usecases/delete_item_usecase.dart';
import 'package:smart_ledger/shared/errors.dart';
import 'package:smart_ledger/shared/result.dart';
import '../../mocks/fake_inventory_repository.dart';

void main() {
  group('DeleteItemUseCase', () {
    late FakeInventoryRepository repository;
    late DeleteItemUseCase useCase;

    setUp(() {
      repository = FakeInventoryRepository();
      useCase = DeleteItemUseCase(repository);
    });

    tearDown(() {
      repository.clear();
    });

    group('Validation Tests', () {
      test(
        'Given empty item ID, When execute, Then returns ValidationError',
        () async {
          // Given
          const itemId = '   '; // Empty after trim

          // When
          final result = await useCase.execute(itemId);

          // Then
          expect(result.isFailure, isTrue);
          result.when(
            success: (_) => fail('Should not succeed'),
            failure: (error) {
              expect(error, isA<ValidationError>());
              expect(
                (error as ValidationError).message,
                contains('Item ID cannot be empty'),
              );
            },
          );
        },
      );
    });

    group('Success Tests', () {
      test(
        'Given existing item, When execute, Then deletes item successfully',
        () async {
          // Given
          final item = ConsumableInventoryItem(
            id: '1',
            name: 'Rice',
            currentStock: 50.0,
            threshold: 10.0,
            unit: 'kg',
            category: 'Food',
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          );
          repository.seed([item]);
          expect(repository.items.length, 1);

          // When
          final result = await useCase.execute('1');

          // Then
          expect(result.isSuccess, isTrue);
          expect(repository.items.length, 0);
        },
      );

      test(
        'Given multiple items, When delete one, Then only that item is removed',
        () async {
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
              currentStock: 25.0,
              threshold: 5.0,
              unit: 'kg',
              category: 'Food',
              createdAt: DateTime.now(),
              lastUpdated: DateTime.now(),
            ),
            ConsumableInventoryItem(
              id: '3',
              name: 'Sugar',
              currentStock: 30.0,
              threshold: 8.0,
              unit: 'kg',
              category: 'Food',
              createdAt: DateTime.now(),
              lastUpdated: DateTime.now(),
            ),
          ];
          repository.seed(items);
          expect(repository.items.length, 3);

          // When
          final result = await useCase.execute('2');

          // Then
          expect(result.isSuccess, isTrue);
          expect(repository.items.length, 2);
          expect(repository.items.any((item) => item.id == '1'), isTrue);
          expect(repository.items.any((item) => item.id == '2'), isFalse);
          expect(repository.items.any((item) => item.id == '3'), isTrue);
        },
      );
    });

    group('Not Found Tests', () {
      test(
        'Given non-existent item ID, When execute, Then returns NotFoundError',
        () async {
          // Given
          const nonExistentId = 'non-existent';

          // When
          final result = await useCase.execute(nonExistentId);

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

      test(
        'Given empty repository, When delete, Then returns NotFoundError',
        () async {
          // Given: Repository is empty (default state)

          // When
          final result = await useCase.execute('1');

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
        'Given repository fails, When execute, Then returns NetworkError',
        () async {
          // Given
          final item = ConsumableInventoryItem(
            id: '4',
            name: 'Coffee',
            currentStock: 15.0,
            threshold: 5.0,
            unit: 'kg',
            category: 'Food',
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          );
          repository.seed([item]);
          repository.shouldFailOnDelete = true;

          // When
          final result = await useCase.execute('4');

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
