part of 'user_pref_service.dart';

// --- Shopping cart / history / templates / budget / stores / payments ---
String _shoppingCartItemsKey(String a) =>
    PrefKeys.accountKey(a, 'shopping_cart_items');
String _shoppingCartHistoryKey(String a) =>
    PrefKeys.accountKey(a, 'shopping_cart_history_v1');
String _shoppingCartPlannedBudgetKey(String a) =>
    PrefKeys.accountKey(a, 'shopping_cart_planned_budget_v1');
String _shoppingGroceryTemplateKey(String a) =>
    PrefKeys.accountKey(a, 'shopping_grocery_template_v1');

Future<List<ShoppingCartItem>> _getShoppingCartItems({
  required String accountName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_shoppingCartItemsKey(accountName));
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: 15));
    final items = decoded
        .whereType<Map<String, dynamic>>()
        .map(ShoppingCartItem.fromJson)
        .where((i) => i.id.trim().isNotEmpty && i.name.trim().isNotEmpty)
        .where((i) => i.updatedAt.isAfter(cutoffDate))
        .toList();
    if (items.length < decoded.length) {
      await _setShoppingCartItems(accountName: accountName, items: items);
    }
    return items;
  } catch (_) {
    return const [];
  }
}

Future<void> _setShoppingCartItems({
  required String accountName,
  required List<ShoppingCartItem> items,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final data = items.map((i) => i.toJson()).toList(growable: false);
  await prefs.setString(_shoppingCartItemsKey(accountName), jsonEncode(data));
}

Future<void> _clearShoppingCartItems({required String accountName}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_shoppingCartItemsKey(accountName));
}

Future<double?> _getShoppingCartPlannedBudget({
  required String accountName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getDouble(_shoppingCartPlannedBudgetKey(accountName));
  return (value == null || value <= 0) ? null : value;
}

Future<void> _setShoppingCartPlannedBudget({
  required String accountName,
  required double? budget,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final next = (budget == null || budget <= 0) ? null : budget;
  if (next == null) {
    await prefs.remove(_shoppingCartPlannedBudgetKey(accountName));
    return;
  }
  await prefs.setDouble(_shoppingCartPlannedBudgetKey(accountName), next);
}

Future<List<ShoppingCartHistoryEntry>> _getShoppingCartHistory({
  required String accountName,
  int limit = 200,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_shoppingCartHistoryKey(accountName));
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final entries = decoded
        .whereType<Map<String, dynamic>>()
        .map(ShoppingCartHistoryEntry.fromJson)
        .where((e) =>
            e.id.trim().isNotEmpty &&
            e.itemId.trim().isNotEmpty &&
            e.name.trim().isNotEmpty)
        .toList();
    entries.sort((a, b) => b.at.compareTo(a.at));
    return entries.take(limit).toList(growable: false);
  } catch (_) {
    return const [];
  }
}

Future<void> _addShoppingCartHistoryEntry({
  required String accountName,
  required ShoppingCartHistoryEntry entry,
  int maxItems = 500,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final current = await _getShoppingCartHistory(
    accountName: accountName, limit: maxItems,
  );
  final next = [entry, ...current];
  final data = next.take(maxItems).map((e) => e.toJson()).toList();
  await prefs.setString(
    _shoppingCartHistoryKey(accountName), jsonEncode(data),
  );
}

Future<void> _clearShoppingCartHistory({required String accountName}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_shoppingCartHistoryKey(accountName));
}

Future<void> _setShoppingCartHistory({
  required String accountName,
  required List<ShoppingCartHistoryEntry> entries,
  int maxItems = 500,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final trimmed = entries.take(maxItems).toList(growable: false);
  final data = trimmed.map((e) => e.toJson()).toList(growable: false);
  await prefs.setString(
    _shoppingCartHistoryKey(accountName), jsonEncode(data),
  );
}

Future<List<ShoppingTemplateItem>> _getShoppingGroceryTemplateItems({
  required String accountName,
  int limit = 200,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_shoppingGroceryTemplateKey(accountName));
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final items = decoded
        .whereType<Map<String, dynamic>>()
        .map(ShoppingTemplateItem.fromJson)
        .where((i) => i.name.trim().isNotEmpty)
        .toList();
    return items.take(limit).toList(growable: false);
  } catch (_) {
    return const [];
  }
}

Future<void> _setShoppingGroceryTemplateItems({
  required String accountName,
  required List<ShoppingTemplateItem> items,
  int maxItems = 500,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final trimmed = items
      .where((i) => i.name.trim().isNotEmpty)
      .take(maxItems)
      .toList(growable: false);
  final data = trimmed.map((i) => i.toJson()).toList(growable: false);
  await prefs.setString(
    _shoppingGroceryTemplateKey(accountName), jsonEncode(data),
  );
}

Future<void> _clearShoppingGroceryTemplateItems({
  required String accountName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_shoppingGroceryTemplateKey(accountName));
}

Future<List<String>> _getRecentStores(String accountName) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(
        PrefKeys.accountKey(accountName, 'recent_stores')) ??
      [];
}

Future<void> _saveRecentStore(String accountName, String store) async {
  final trimmed = store.trim();
  if (trimmed.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  final key = PrefKeys.accountKey(accountName, 'recent_stores');
  final current = prefs.getStringList(key) ?? [];
  current.remove(trimmed);
  current.insert(0, trimmed);
  if (current.length > 10) current.removeRange(10, current.length);
  await prefs.setStringList(key, current);
}

Future<List<String>> _getRecentPayments(String accountName) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(
        PrefKeys.accountKey(accountName, 'recent_payments')) ??
      [];
}

Future<void> _saveRecentPayment(String accountName, String payment) async {
  final trimmed = payment.trim();
  if (trimmed.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  final key = PrefKeys.accountKey(accountName, 'recent_payments');
  final current = prefs.getStringList(key) ?? [];
  current.remove(trimmed);
  current.insert(0, trimmed);
  if (current.length > 10) current.removeRange(10, current.length);
  await prefs.setStringList(key, current);
}
