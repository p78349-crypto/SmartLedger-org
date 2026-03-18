library;

import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/features/wms/domain/repositories/inventory_repository.dart';
import 'package:smart_ledger/features/wms/domain/usecases/base_usecase.dart';
import 'package:smart_ledger/shared/errors.dart';
import 'package:smart_ledger/shared/result.dart';

/// UseCase for updating an existing inventory item.
///
/// Business rules:
/// - Item must exist (verified by ID)
/// - Name cannot be empty
/// - Stock cannot be negative
/// - Threshold cannot be negative
///
/// Returns:
/// - Success(ConsumableInventoryItem) if update was successful
/// - Failure(ValidationError) if input validation fails
/// - Failure(NotFoundError) if item doesn't exist
/// - Failure(NetworkError) if repository operation fails
class UpdateStockUseCase
    extends UseCase<ConsumableInventoryItem, ConsumableInventoryItem> {
  final InventoryRepository _repository;

  UpdateStockUseCase(this._repository);

  @override
  Future<Result<ConsumableInventoryItem>> execute(
    ConsumableInventoryItem item,
  ) async {
    // Validation: name cannot be empty
    if (item.name.trim().isEmpty) {
      return const Failure(ValidationError('Item name cannot be empty'));
    }

    // Validation: stock cannot be negative
    if (item.currentStock < 0) {
      return const Failure(ValidationError('Current stock cannot be negative'));
    }

    // Validation: threshold cannot be negative
    if (item.threshold < 0) {
      return const Failure(ValidationError('threshold cannot be negative'));
    }

    // Check if item exists
    final existsResult = await _repository.getItemById(item.id);

    // If item doesn't exist, getItemById will return NotFoundError
    if (existsResult.isFailure) {
      return Failure(existsResult.errorOrNull!);
    }

    // All validations passed, update the item
    return _repository.updateItem(item);
  }
}
