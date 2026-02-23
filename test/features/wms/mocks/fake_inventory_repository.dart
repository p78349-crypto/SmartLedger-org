/// Fake implementation of InventoryRepository for testing
library;

import 'package:smart_ledger/features/wms/domain/models/inventory_mutation_receipt.dart';
import 'package:smart_ledger/features/wms/domain/repositories/inventory_repository.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/shared/errors.dart';
import 'package:smart_ledger/shared/result.dart';
import 'package:smart_ledger/shared/unit.dart';

/// Fake repository implementation for testing
/// 
/// This provides an in-memory implementation of InventoryRepository
/// with controllable failure scenarios for testing error handling.
class FakeInventoryRepository implements InventoryRepository {
  final List<ConsumableInventoryItem> _items = [];
  
  // Test control flags
  bool shouldFailOnAdd = false;
  bool shouldFailOnUpdate = false;
  bool shouldFailOnFetch = false;
  bool shouldFailOnUse = false;
  bool shouldFailOnDelete = false;
  
  /// Read-only access to items
  List<ConsumableInventoryItem> get items => List.unmodifiable(_items);
  
  /// Initialize with test data
  void seed(List<ConsumableInventoryItem> initialItems) {
    _items.clear();
    _items.addAll(initialItems);
  }
  
  /// Clear all data and reset flags
  void clear() {
    _items.clear();
    shouldFailOnAdd = false;
    shouldFailOnUpdate = false;
    shouldFailOnFetch = false;
    shouldFailOnUse = false;
    shouldFailOnDelete = false;
  }
  
  @override
  Future<Result<List<ConsumableInventoryItem>>> fetchItems() async {
    await Future.delayed(const Duration(milliseconds: 10));
    
    if (shouldFailOnFetch) {
      return const Failure(NetworkError('Failed to fetch items', statusCode: 503));
    }
    
    return Success(List.from(_items));
  }
  
  @override
  Future<Result<ConsumableInventoryItem>> addItem(
    ConsumableInventoryItem item,
  ) async {
    await Future.delayed(const Duration(milliseconds: 10));
    
    if (shouldFailOnAdd) {
      return const Failure(NetworkError('Failed to add item', statusCode: 500));
    }
    
    if (_items.any((i) => i.id == item.id)) {
      return Failure(ValidationError('Item with id ${item.id} already exists'));
    }
    
    _items.add(item);
    return Success(item);
  }
  
  @override
  Future<Result<ConsumableInventoryItem>> updateItem(
    ConsumableInventoryItem item,
  ) async {
    await Future.delayed(const Duration(milliseconds: 10));
    
    if (shouldFailOnUpdate) {
      return const Failure(NetworkError('Failed to update item', statusCode: 500));
    }
    
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      return Failure(NotFoundError('Item not found: ${item.id}'));
    }
    
    _items[index] = item;
    return Success(item);
  }
  
  @override
  Future<Result<InventoryMutationReceipt>> useStock(
    String id,
    double amount,
  ) async {
    await Future.delayed(const Duration(milliseconds: 10));
    
    if (shouldFailOnUse) {
      return const Failure(NetworkError('Failed to use stock', statusCode: 500));
    }
    
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) {
      return Failure(NotFoundError('Item not found: $id'));
    }
    
    final item = _items[index];
    if (item.currentStock < amount) {
      return const Failure(
        ValidationError('Insufficient stock'),
      );
    }
    
    final updatedItem = item.copyWith(
      currentStock: item.currentStock - amount,
      lastUpdated: DateTime.now(),
    );
    _items[index] = updatedItem;
    
    return Success(
      InventoryMutationReceipt(
        itemId: id,
        delta: -amount,
        occurredAt: DateTime.now(),
      ),
    );
  }
  
  @override
  Future<Result<Unit>> deleteItem(String id) async {
    await Future.delayed(const Duration(milliseconds: 10));
    
    if (shouldFailOnDelete) {
      return const Failure(NetworkError('Failed to delete item', statusCode: 500));
    }
    
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) {
      return Failure(NotFoundError('Item not found: $id'));
    }
    
    _items.removeAt(index);
    return successVoid();
  }
  
  @override
  Future<Result<ConsumableInventoryItem>> getItemById(String id) async {
    await Future.delayed(const Duration(milliseconds: 10));
    
    try {
      final item = _items.firstWhere(
        (i) => i.id == id,
        orElse: () => throw StateError('Not found'),
      );
      return Success(item);
    } catch (_) {
      return Failure(NotFoundError('Item not found: $id'));
    }
  }
  
  @override
  Future<Result<List<ConsumableInventoryItem>>> searchByName(
    String query,
  ) async {
    await Future.delayed(const Duration(milliseconds: 10));
    
    final results = _items
        .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    
    return Success(results);
  }
  
  @override
  Future<Result<List<ConsumableInventoryItem>>> getLowStockItems() async {
    await Future.delayed(const Duration(milliseconds: 10));
    
    if (shouldFailOnFetch) {
      return const Failure(NetworkError('Failed to fetch items', statusCode: 503));
    }
    
    final lowStock = _items
        .where((item) => item.currentStock <= item.threshold)
        .toList();
    
    return Success(lowStock);
  }
  
  @override
  Future<Result<List<ConsumableInventoryItem>>> getItemsByLocation(
    String location,
  ) async {
    await Future.delayed(const Duration(milliseconds: 10));
    
    final results = _items
        .where((item) => item.location == location)
        .toList();
    
    return Success(results);
  }
  
  @override
  Future<Result<List<ConsumableInventoryItem>>> bulkAddItems(
    List<ConsumableInventoryItem> items,
  ) async {
    await Future.delayed(const Duration(milliseconds: 10));
    
    if (shouldFailOnAdd) {
      return const Failure(NetworkError('Failed to add items', statusCode: 500));
    }
    
    // Check for duplicates
    for (final item in items) {
      if (_items.any((i) => i.id == item.id)) {
        return Failure(
          ValidationError('Item with id ${item.id} already exists'),
        );
      }
    }
    
    _items.addAll(items);
    return Success(items);
  }
  
  @override
  Future<Result<Unit>> bulkDeleteItems(List<String> ids) async {
    await Future.delayed(const Duration(milliseconds: 10));
    
    if (shouldFailOnDelete) {
      return const Failure(NetworkError('Failed to delete items', statusCode: 500));
    }
    
    // Check all items exist
    for (final id in ids) {
      if (!_items.any((i) => i.id == id)) {
        return Failure(NotFoundError('Item not found: $id'));
      }
    }
    
    _items.removeWhere((item) => ids.contains(item.id));
    return successVoid();
  }
}
