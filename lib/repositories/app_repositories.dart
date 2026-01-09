import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/consumable_inventory_item.dart';
import '../models/shopping_cart_history_entry.dart';
import '../models/shopping_cart_item.dart';
import 'consumable_inventory_repository.dart';
import 'shopping_cart_repository.dart';
import '../services/user_pref_service.dart';

class AppRepositories {
  // Swap these at runtime later
  // (e.g., after Firebase login / family selection).
  static ConsumableInventoryRepository consumableInventory =
      SharedPrefsConsumableInventoryRepository();
  static ShoppingCartRepository shoppingCart = UserPrefShoppingCartRepository();
}

class SharedPrefsConsumableInventoryRepository
    implements ConsumableInventoryRepository {
  static const String _prefsKey = 'consumable_inventory_items_v1';

  @override
  Future<List<ConsumableInventoryItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.trim().isEmpty) return const [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final parsed = list
          .whereType<Map<String, dynamic>>()
          .map(ConsumableInventoryItem.fromJson)
          .toList();
      // FIFO: 생성일 기준 정렬 (오래된 것이 먼저)
      parsed.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return parsed;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> saveItems(List<ConsumableInventoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items.map((e) => e.toJson()).toList());
    await prefs.setString(_prefsKey, raw);
  }
}

class UserPrefShoppingCartRepository implements ShoppingCartRepository {
  @override
  Future<List<ShoppingCartItem>> getItems({required String accountName}) {
    return UserPrefService.getShoppingCartItems(accountName: accountName);
  }

  @override
  Future<void> setItems({
    required String accountName,
    required List<ShoppingCartItem> items,
  }) {
    return UserPrefService.setShoppingCartItems(
      accountName: accountName,
      items: items,
    );
  }

  @override
  Future<void> clearItems({required String accountName}) {
    return UserPrefService.clearShoppingCartItems(accountName: accountName);
  }

  @override
  Future<List<ShoppingCartHistoryEntry>> getHistory({
    required String accountName,
    int limit = 200,
  }) {
    return UserPrefService.getShoppingCartHistory(
      accountName: accountName,
      limit: limit,
    );
  }

  @override
  Future<void> setHistory({
    required String accountName,
    required List<ShoppingCartHistoryEntry> entries,
    int maxItems = 500,
  }) {
    return UserPrefService.setShoppingCartHistory(
      accountName: accountName,
      entries: entries,
      maxItems: maxItems,
    );
  }

  @override
  Future<void> addHistoryEntry({
    required String accountName,
    required ShoppingCartHistoryEntry entry,
    int maxItems = 500,
  }) {
    return UserPrefService.addShoppingCartHistoryEntry(
      accountName: accountName,
      entry: entry,
      maxItems: maxItems,
    );
  }

  @override
  Future<void> clearHistory({required String accountName}) {
    return UserPrefService.clearShoppingCartHistory(accountName: accountName);
  }
}
