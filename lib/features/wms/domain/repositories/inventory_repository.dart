/// Abstract repository interface for inventory operations
library;

import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/shared/result.dart';
import 'package:smart_ledger/shared/unit.dart';
import '../models/inventory_mutation_receipt.dart';

/// Repository interface for inventory management
///
/// This defines all data operations for inventory items.
/// Implementations should handle data persistence (Firebase, SQLite, etc.).
///
/// All methods return Result\<T\> for type-safe error handling.
abstract class InventoryRepository {
  /// Fetch all inventory items
  ///
  /// Returns a list of all items, or empty list if none exist.
  /// Failure cases: network errors, storage errors.
  Future<Result<List<ConsumableInventoryItem>>> fetchItems();

  /// Add new inventory item
  ///
  /// Returns the created item with generated ID if successful.
  /// Failure cases: validation error, duplicate ID, storage error.
  Future<Result<ConsumableInventoryItem>> addItem(ConsumableInventoryItem item);

  /// Update existing inventory item
  ///
  /// Returns the updated item if successful.
  /// Failure cases: item not found, validation error, storage error.
  Future<Result<ConsumableInventoryItem>> updateItem(
    ConsumableInventoryItem item,
  );

  /// Use stock (decrease quantity)
  ///
  /// Decreases the stock by the given amount and returns a receipt.
  /// Failure cases: item not found, insufficient stock, negative amount.
  Future<Result<InventoryMutationReceipt>> useStock(String id, double amount);

  /// Delete inventory item
  ///
  /// Permanently removes the item from storage.
  /// Failure cases: item not found, storage error.
  Future<Result<Unit>> deleteItem(String id);

  /// Get item by ID
  ///
  /// Returns a single item if found.
  /// Failure cases: item not found, storage error.
  Future<Result<ConsumableInventoryItem>> getItemById(String id);

  /// Search items by name
  ///
  /// Returns items whose names contain the query string (case-insensitive).
  /// Returns empty list if no matches found.
  Future<Result<List<ConsumableInventoryItem>>> searchByName(String query);

  /// Get low stock items
  ///
  /// Returns items where currentStock <= minThreshold.
  /// Returns empty list if no low stock items exist.
  Future<Result<List<ConsumableInventoryItem>>> getLowStockItems();

  /// Get items by location
  ///
  /// Returns items stored at the specified location.
  /// Returns empty list if no items found at that location.
  Future<Result<List<ConsumableInventoryItem>>> getItemsByLocation(
    String location,
  );

  /// Bulk add items
  ///
  /// Adds multiple items in a single transaction.
  /// Returns list of added items if successful.
  /// Failure cases: validation error on any item, storage error.
  Future<Result<List<ConsumableInventoryItem>>> bulkAddItems(
    List<ConsumableInventoryItem> items,
  );

  /// Bulk delete items
  ///
  /// Deletes multiple items in a single transaction.
  /// Failure cases: any item not found, storage error.
  Future<Result<Unit>> bulkDeleteItems(List<String> ids);
}
