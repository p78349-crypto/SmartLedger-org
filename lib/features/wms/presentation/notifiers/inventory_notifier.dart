library;

import 'package:flutter/foundation.dart';
import 'package:smart_ledger/models/consumable_inventory_item.dart';
import 'package:smart_ledger/features/wms/domain/repositories/inventory_repository.dart';
import 'package:smart_ledger/features/wms/domain/usecases/load_inventory_usecase.dart';
import 'package:smart_ledger/features/wms/domain/usecases/add_stock_usecase.dart';
import 'package:smart_ledger/features/wms/domain/usecases/update_stock_usecase.dart';
import 'package:smart_ledger/features/wms/domain/usecases/delete_item_usecase.dart';
import 'package:smart_ledger/features/wms/domain/usecases/use_stock_usecase.dart';
import 'package:smart_ledger/features/wms/domain/usecases/get_low_stock_usecase.dart';
import 'package:smart_ledger/shared/result.dart';
import '../state/inventory_state.dart';

/// Manages inventory state using ChangeNotifier pattern.
/// 
/// Coordinates between UI and UseCases, handling all business logic
/// through the domain layer.
class InventoryNotifier extends ChangeNotifier {
  final InventoryRepository _repository;
  
  // UseCases
  late final LoadInventoryUseCase _loadInventoryUseCase;
  late final AddStockUseCase _addStockUseCase;
  late final UpdateStockUseCase _updateStockUseCase;
  late final DeleteItemUseCase _deleteItemUseCase;
  late final UseStockUseCase _useStockUseCase;
  late final GetLowStockUseCase _getLowStockUseCase;
  
  InventoryState _state = const InventoryInitial();
  
  InventoryNotifier(this._repository) {
    _loadInventoryUseCase = LoadInventoryUseCase(_repository);
    _addStockUseCase = AddStockUseCase(_repository);
    _updateStockUseCase = UpdateStockUseCase(_repository);
    _deleteItemUseCase = DeleteItemUseCase(_repository);
    _useStockUseCase = UseStockUseCase(_repository);
    _getLowStockUseCase = GetLowStockUseCase(_repository);
  }
  
  InventoryState get state => _state;
  
  void _setState(InventoryState newState) {
    _state = newState;
    notifyListeners();
  }
  
  /// Load all inventory items
  Future<void> loadInventory() async {
    _setState(const InventoryLoading());
    
    final result = await _loadInventoryUseCase.execute();
    final lowStockResult = await _getLowStockUseCase.execute();
    
    result.when(
      success: (items) {
        lowStockResult.when(
          success: (lowStockItems) {
            _setState(InventoryLoaded(
              items: items,
              lowStockItems: lowStockItems,
            ));
          },
          failure: (error) {
            // If low stock fetch fails, just use empty list
            _setState(InventoryLoaded(
              items: items,
              lowStockItems: [],
            ));
          },
        );
      },
      failure: (error) {
        _setState(InventoryError(error));
      },
    );
  }
  
  /// Add a new inventory item
  Future<void> addItem(ConsumableInventoryItem item) async {
    final currentItems = _getCurrentItems();
    _setState(InventoryOperating(
      items: currentItems,
      operation: 'adding',
    ));
    
    final result = await _addStockUseCase.execute(item);
    
    result.when(
      success: (_) async {
        await loadInventory(); // Reload to get latest data
        _setState(InventoryOperationSuccess(
          items: _getCurrentItems(),
          message: 'Item added successfully',
        ));
      },
      failure: (error) {
        _setState(InventoryError(error));
      },
    );
  }
  
  /// Update an existing inventory item
  Future<void> updateItem(ConsumableInventoryItem item) async {
    final currentItems = _getCurrentItems();
    _setState(InventoryOperating(
      items: currentItems,
      operation: 'updating',
    ));
    
    final result = await _updateStockUseCase.execute(item);
    
    result.when(
      success: (_) async {
        await loadInventory();
        _setState(InventoryOperationSuccess(
          items: _getCurrentItems(),
          message: 'Item updated successfully',
        ));
      },
      failure: (error) {
        _setState(InventoryError(error));
      },
    );
  }
  
  /// Delete an inventory item
  Future<void> deleteItem(String itemId) async {
    final currentItems = _getCurrentItems();
    _setState(InventoryOperating(
      items: currentItems,
      operation: 'deleting',
    ));
    
    final result = await _deleteItemUseCase.execute(itemId);
    
    result.when(
      success: (_) async {
        await loadInventory();
        _setState(InventoryOperationSuccess(
          items: _getCurrentItems(),
          message: 'Item deleted successfully',
        ));
      },
      failure: (error) {
        _setState(InventoryError(error));
      },
    );
  }
  
  /// Use stock (decrease quantity)
  Future<void> useStock(String itemId, double amount, {String? purpose}) async {
    final currentItems = _getCurrentItems();
    _setState(InventoryOperating(
      items: currentItems,
      operation: 'using',
    ));
    
    final result = await _useStockUseCase.execute(
      UseStockInput(itemId: itemId, amount: amount, purpose: purpose),
    );
    
    result.when(
      success: (_) async {
        await loadInventory();
        _setState(InventoryOperationSuccess(
          items: _getCurrentItems(),
          message: 'Stock used successfully',
        ));
      },
      failure: (error) {
        _setState(InventoryError(error));
      },
    );
  }
  
  /// Refresh inventory data
  Future<void> refresh() => loadInventory();
  
  /// Get current items from state (helper method)
  List<ConsumableInventoryItem> _getCurrentItems() {
    return switch (_state) {
      InventoryLoaded(:final items) => items,
      InventoryOperating(:final items) => items,
      InventoryOperationSuccess(:final items) => items,
      _ => [],
    };
  }
}
