import 'package:flutter/foundation.dart';
import '../models/consumable_inventory_item.dart';
import '../models/food_expiry_item.dart';
import 'consumable_inventory_service.dart';

/// FoodExpiry 호환 서비스 (통합 재고 기반)
///
/// - legacy SharedPreferences 저장 제거
/// - ConsumableInventoryService의 expiryDate 데이터를 투영
class FoodExpiryService {
  FoodExpiryService._internal();
  static final FoodExpiryService instance = FoodExpiryService._internal();

  final ValueNotifier<List<FoodExpiryItem>> items =
      ValueNotifier<List<FoodExpiryItem>>(<FoodExpiryItem>[]);

  Future<void> load() async {
    await ConsumableInventoryService.instance.load();
    final inventory = ConsumableInventoryService.instance.items.value;
    final mapped = inventory
        .where((e) => e.expiryDate != null)
        .map(_fromInventory)
        .toList();
    mapped.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    items.value = mapped;
  }

  FoodExpiryItem _fromInventory(ConsumableInventoryItem item) {
    return FoodExpiryItem(
      id: item.id,
      name: item.name,
      purchaseDate: item.purchaseDate ?? item.createdAt,
      expiryDate: item.expiryDate ?? item.createdAt,
      createdAt: item.createdAt,
      quantity: item.currentStock,
      unit: item.unit,
      category: item.category,
      location: item.location,
      price: item.price ?? 0.0,
      supplier: item.supplier ?? '',
    );
  }

  Future<void> addItem({
    required String name,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    String memo = '',
    double quantity = 1.0,
    String unit = '',
    String category = '기타',
    String location = '냉장',
    double price = 0.0,
    String supplier = '',
  }) async {
    await ConsumableInventoryService.instance.addItem(
      name: name.trim(),
      currentStock: quantity,
      unit: unit,
      category: category,
      location: location,
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      price: price > 0 ? price : null,
      supplier: supplier.isEmpty ? null : supplier,
    );
    await load();
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required DateTime purchaseDate,
    required DateTime expiryDate,
    required String memo,
    required double quantity,
    required String unit,
    String category = '기타',
    String location = '냉장',
    double price = 0.0,
    String supplier = '',
  }) async {
    final current = ConsumableInventoryService.instance.items.value;
    final idx = current.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    final existing = current[idx];
    final updated = existing.copyWith(
      name: name.trim(),
      currentStock: quantity,
      unit: unit,
      category: category,
      location: location,
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      price: price > 0 ? price : null,
      supplier: supplier.isEmpty ? null : supplier,
    );
    await ConsumableInventoryService.instance.updateItem(updated);
    await load();
  }

  Future<void> deleteById(String id) async {
    await ConsumableInventoryService.instance.deleteItem(id);
    await load();
  }
}
