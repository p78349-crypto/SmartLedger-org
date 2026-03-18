library;

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/features/wms/domain/usecases/load_inventory_usecase.dart';
import 'package:smart_ledger/shared/errors.dart';
import 'package:smart_ledger/shared/result.dart';
import '../../mocks/fake_inventory_repository.dart';

void main() {
  group('LoadInventoryUseCase', () {
    late FakeInventoryRepository repository;
    late LoadInventoryUseCase useCase;

    setUp(() {
      repository = FakeInventoryRepository();
      useCase = LoadInventoryUseCase(repository);
    });

    tearDown(() {
      repository.clear();
    });

    group('Success Tests', () {
      test(
        'Given empty repository, When execute, Then returns empty list',
        () async {
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
        },
      );

      test(
        'Given repository with items, When execute, Then returns all items',
        () async {
          // Given
          final testItems = [
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
          ];
          repository.seed(testItems);

          // When
          final result = await useCase.execute();

          // Then
          expect(result.isSuccess, isTrue);
          result.when(
            success: (items) {
              expect(items.length, 2);
              expect(items[0].name, 'Rice');
              expect(items[1].name, 'Flour');
            },
            failure: (_) => fail('Should not fail'),
          );
        },
      );

      test(
        'Given multiple items, When execute, Then preserves item properties',
        () async {
          // Given
          final item = ConsumableInventoryItem(
            id: '3',
            name: 'Sugar',
            currentStock: 30.0,
            threshold: 8.0,
            unit: 'kg',
            category: 'Food',
            location: 'Pantry A',
            supplier: 'Local Market',
            createdAt: DateTime.now(),
            lastUpdated: DateTime.now(),
          );
          repository.seed([item]);

          // When
          final result = await useCase.execute();

          // Then
          expect(result.isSuccess, isTrue);
          result.when(
            success: (items) {
              final loadedItem = items.first;
              expect(loadedItem.id, '3');
              expect(loadedItem.name, 'Sugar');
              expect(loadedItem.currentStock, 30.0);
              expect(loadedItem.threshold, 8.0);
              expect(loadedItem.location, 'Pantry A');
              expect(loadedItem.supplier, 'Local Market');
            },
            failure: (_) => fail('Should not fail'),
          );
        },
      );
    });

    group('Repository Failure Tests', () {
      test(
        'Given repository fails, When execute, Then returns NetworkError',
        () async {
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
              expect(
                (error as NetworkError).message,
                contains('Failed to fetch'),
              );
            },
          );
        },
      );
    });
  });
}
