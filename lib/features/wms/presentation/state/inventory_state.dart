library;

import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/shared/errors.dart';

/// Represents the state of the inventory feature in the UI.
///
/// Uses sealed classes for exhaustive pattern matching.
sealed class InventoryState {
  const InventoryState();
}

/// Initial state before any data is loaded
class InventoryInitial extends InventoryState {
  const InventoryInitial();
}

/// Loading state when fetching data
class InventoryLoading extends InventoryState {
  const InventoryLoading();
}

/// Success state with loaded inventory items
class InventoryLoaded extends InventoryState {
  final List<ConsumableInventoryItem> items;
  final List<ConsumableInventoryItem> lowStockItems;

  const InventoryLoaded({required this.items, required this.lowStockItems});

  /// Get items sorted by name
  List<ConsumableInventoryItem> get itemsSortedByName {
    final sorted = List<ConsumableInventoryItem>.from(items);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  /// Get items sorted by stock level (lowest first)
  List<ConsumableInventoryItem> get itemsSortedByStock {
    final sorted = List<ConsumableInventoryItem>.from(items);
    sorted.sort((a, b) => a.currentStock.compareTo(b.currentStock));
    return sorted;
  }

  /// Check if an item has low stock
  bool isLowStock(ConsumableInventoryItem item) {
    return lowStockItems.any((lowItem) => lowItem.id == item.id);
  }
}

/// Error state when an operation fails
class InventoryError extends InventoryState {
  final AppError error;

  const InventoryError(this.error);

  String get message => error.message;
}

/// State when performing an operation (add, update, delete)
class InventoryOperating extends InventoryState {
  final List<ConsumableInventoryItem> items;
  final String operation; // 'adding', 'updating', 'deleting', 'using'

  const InventoryOperating({required this.items, required this.operation});
}

/// Success state after an operation completes
class InventoryOperationSuccess extends InventoryState {
  final List<ConsumableInventoryItem> items;
  final String message;

  const InventoryOperationSuccess({required this.items, required this.message});
}
