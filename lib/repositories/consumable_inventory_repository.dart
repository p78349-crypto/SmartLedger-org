import 'package:smart_ledger/models/consumable_inventory_item.dart';

abstract class ConsumableInventoryRepository {
  Future<List<ConsumableInventoryItem>> loadItems();
  Future<void> saveItems(List<ConsumableInventoryItem> items);
}
