/// Use case for loading inventory items
library;

import 'package:smart_ledger/features/wms/domain/repositories/inventory_repository.dart';
import 'package:smart_ledger/features/wms/domain/usecases/base_usecase.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/shared/result.dart';

/// Load all inventory items from repository
///
/// This use case fetches all inventory items and returns them.
/// No validation or business logic is applied - it's a simple pass-through.
///
/// Example:
/// ```dart
/// final useCase = LoadInventoryUseCase(repository);
/// final result = await useCase.execute();
///
/// result.when(
///   success: (items) => print('Loaded ${items.length} items'),
///   failure: (error) => print('Error: ${error.message}'),
/// );
/// ```
class LoadInventoryUseCase extends NoArgUseCase<List<ConsumableInventoryItem>> {
  final InventoryRepository _repository;

  LoadInventoryUseCase(this._repository);

  @override
  Future<Result<List<ConsumableInventoryItem>>> execute() async {
    return await _repository.fetchItems();
  }
}
