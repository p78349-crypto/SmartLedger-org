import '../models/shopping_cart_history_entry.dart';
import '../models/shopping_cart_item.dart';

abstract class ShoppingCartRepository {
  Future<List<ShoppingCartItem>> getItems({required String accountName});
  Future<void> setItems({
    required String accountName,
    required List<ShoppingCartItem> items,
  });
  Future<void> clearItems({required String accountName});

  Future<List<ShoppingCartHistoryEntry>> getHistory({
    required String accountName,
    int limit = 200,
  });
  Future<void> setHistory({
    required String accountName,
    required List<ShoppingCartHistoryEntry> entries,
    int maxItems = 500,
  });
  Future<void> addHistoryEntry({
    required String accountName,
    required ShoppingCartHistoryEntry entry,
    int maxItems = 500,
  });
  Future<void> clearHistory({required String accountName});
}
