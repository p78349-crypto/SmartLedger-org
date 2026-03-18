library;

import 'package:smart_ledger/features/wms/domain/repositories/inventory_repository.dart';
import 'package:smart_ledger/features/wms/domain/usecases/base_usecase.dart';
import 'package:smart_ledger/shared/errors.dart';
import 'package:smart_ledger/shared/result.dart';
import 'package:smart_ledger/shared/unit.dart';

/// Input parameters for using stock from inventory.
class UseStockInput {
  /// The ID of the inventory item to use.
  final String itemId;

  /// The amount to use (must be positive).
  final double amount;

  /// Optional purpose or reason for using the stock.
  final String? purpose;

  const UseStockInput({
    required this.itemId,
    required this.amount,
    this.purpose,
  });
}

/// UseCase for consuming/using stock from an inventory item.
///
/// Business rules:
/// - Item ID cannot be empty
/// - Amount must be positive (greater than 0)
/// - Amount cannot exceed available stock
///
/// Returns:
/// - Success(Unit) if stock was used successfully
/// - Failure(ValidationError) if input validation fails
/// - Failure(NotFoundError) if item doesn't exist
/// - Failure(ValidationError) if insufficient stock
/// - Failure(NetworkError) if repository operation fails
class UseStockUseCase extends UseCase<UseStockInput, Unit> {
  final InventoryRepository _repository;

  UseStockUseCase(this._repository);

  @override
  Future<Result<Unit>> execute(UseStockInput input) async {
    // Validation: item ID cannot be empty
    if (input.itemId.trim().isEmpty) {
      return const Failure(ValidationError('Item ID cannot be empty'));
    }

    // Validation: amount must be positive
    if (input.amount <= 0) {
      return const Failure(ValidationError('Amount must be greater than 0'));
    }

    // Check if item exists and has sufficient stock
    final itemResult = await _repository.getItemById(input.itemId);

    // Handle item not found or get the item
    final item = itemResult.when(
      success: (item) => item,
      failure: (error) => null,
    );

    if (item == null) {
      return itemResult.map((_) => Unit.instance);
    }

    // Validation: sufficient stock
    if (item.currentStock < input.amount) {
      return Failure(
        ValidationError(
          'Insufficient stock: available ${item.currentStock}, requested ${input.amount}',
        ),
      );
    }

    // All validations passed, use the stock
    // Convert Result<InventoryMutationReceipt> to Result<Unit>
    final useResult = await _repository.useStock(input.itemId, input.amount);

    return useResult.map((_) => Unit.instance);
  }
}
