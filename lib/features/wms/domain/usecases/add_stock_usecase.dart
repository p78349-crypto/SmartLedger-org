/// Use case for adding new inventory items
library;

import 'package:smart_ledger/features/wms/domain/repositories/inventory_repository.dart';
import 'package:smart_ledger/features/wms/domain/usecases/base_usecase.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/shared/errors.dart';
import 'package:smart_ledger/shared/result.dart';

/// Add a new inventory item with validation
/// 
/// This use case validates the input item before adding it to the repository.
/// Validation rules:
/// - Item name cannot be empty
/// - Current stock cannot be negative
/// - Min threshold must be non-negative
/// 
/// Example:
/// ```dart
/// final useCase = AddStockUseCase(repository);
/// final item = ConsumableInventoryItem(
///   id: 'soap-1',
///   name: '비누',
///   currentStock: 10.0,
///   createdAt: DateTime.now(),
/// );
/// 
/// final result = await useCase.execute(item);
/// result.when(
///   success: (added) => print('Added: ${added.name}'),
///   failure: (error) => print('Error: ${error.message}'),
/// );
/// ```
class AddStockUseCase
    extends UseCase<ConsumableInventoryItem, ConsumableInventoryItem> {
  final InventoryRepository _repository;
  
  AddStockUseCase(this._repository);

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
      return const Failure(
        ValidationError('Current stock cannot be negative'),
      );
    }
    
    // Validation: threshold must be non-negative
    if (item.threshold < 0) {
      return const Failure(
        ValidationError('threshold cannot be negative'),
      );
    }
    
    // Call repository to persist the item
    return await _repository.addItem(item);
  }
}
