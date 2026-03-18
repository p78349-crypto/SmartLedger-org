/// Base classes for use cases
library;

import 'package:smart_ledger/shared/result.dart';

/// Base class for use cases that require input parameters
///
/// Example:
/// ```dart
/// class AddStockUseCase extends UseCase<ConsumableInventoryItem, ConsumableInventoryItem> {
///   final InventoryRepository repository;
///
///   AddStockUseCase(this.repository);
///
///   @override
///   Future<Result<ConsumableInventoryItem>> execute(ConsumableInventoryItem input) async {
///     // Validation
///     if (input.name.trim().isEmpty) {
///       return Failure(ValidationError('Name cannot be empty'));
///     }
///
///     // Business logic
///     return await repository.addItem(input);
///   }
/// }
/// ```
abstract class UseCase<Input, Output> {
  /// Execute the use case with given input
  Future<Result<Output>> execute(Input input);
}

/// Base class for use cases that don't require input parameters
///
/// Example:
/// ```dart
/// class LoadInventoryUseCase extends NoArgUseCase<List<ConsumableInventoryItem>> {
///   final InventoryRepository repository;
///
///   LoadInventoryUseCase(this.repository);
///
///   @override
///   Future<Result<List<ConsumableInventoryItem>>> execute() async {
///     return await repository.fetchItems();
///   }
/// }
/// ```
abstract class NoArgUseCase<Output> {
  /// Execute the use case without input parameters
  Future<Result<Output>> execute();
}

/// Base class for synchronous use cases with input
abstract class SyncUseCase<Input, Output> {
  /// Execute the use case synchronously with given input
  Result<Output> execute(Input input);
}

/// Base class for synchronous use cases without input
abstract class NoArgSyncUseCase<Output> {
  /// Execute the use case synchronously without input
  Result<Output> execute();
}
