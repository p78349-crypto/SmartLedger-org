library;

import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/features/wms/domain/repositories/inventory_repository.dart';
import 'package:smart_ledger/features/wms/domain/usecases/base_usecase.dart';
import 'package:smart_ledger/shared/result.dart';

/// UseCase for fetching inventory items with low stock.
///
/// Returns items where currentStock <= threshold.
/// This is useful for alerts and shopping list generation.
///
/// Business rules:
/// - No input validation required (no parameters)
/// - Returns empty list if no low stock items
///
/// Returns:
/// - Success(List\<ConsumableInventoryItem\>) with low stock items
/// - Failure(NetworkError) if repository operation fails
class GetLowStockUseCase extends NoArgUseCase<List<ConsumableInventoryItem>> {
  final InventoryRepository _repository;

  GetLowStockUseCase(this._repository);

  @override
  Future<Result<List<ConsumableInventoryItem>>> execute() async {
    return _repository.getLowStockItems();
  }
}
