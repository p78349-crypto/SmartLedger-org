library;

import 'package:smart_ledger/features/wms/domain/repositories/inventory_repository.dart';
import 'package:smart_ledger/features/wms/domain/usecases/base_usecase.dart';
import 'package:smart_ledger/shared/errors.dart';
import 'package:smart_ledger/shared/result.dart';
import 'package:smart_ledger/shared/unit.dart';

/// UseCase for deleting an inventory item.
///
/// Business rules:
/// - Item ID cannot be empty
/// - Item must exist before deletion
///
/// Returns:
/// - Success(Unit) if deletion was successful
/// - Failure(ValidationError) if item ID is empty
/// - Failure(NotFoundError) if item doesn't exist
/// - Failure(NetworkError) if repository operation fails
class DeleteItemUseCase extends UseCase<String, Unit> {
  final InventoryRepository _repository;

  DeleteItemUseCase(this._repository);

  @override
  Future<Result<Unit>> execute(String itemId) async {
    // Validation: item ID cannot be empty
    if (itemId.trim().isEmpty) {
      return const Failure(ValidationError('Item ID cannot be empty'));
    }

    // Check if item exists before deleting
    final existsResult = await _repository.getItemById(itemId);
    
    // If item doesn't exist, getItemById will return NotFoundError
    if (existsResult.isFailure) {
      return Failure(existsResult.errorOrNull!);
    }
    
    // Item exists, proceed with deletion
    return _repository.deleteItem(itemId);
  }
}
