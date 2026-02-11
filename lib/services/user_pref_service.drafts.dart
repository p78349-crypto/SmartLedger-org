part of 'user_pref_service.dart';

// --- Shopping points drafts ---
String _shoppingPointsDraftsKey(String accountName) {
  return PrefKeys.accountKey(accountName, 'shopping_points_drafts_v1');
}

Future<List<ShoppingPointsDraftEntry>> _getShoppingPointsDrafts({
  required String accountName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_shoppingPointsDraftsKey(accountName));
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((m) => ShoppingPointsDraftEntry.fromJson(
              Map<String, dynamic>.from(m)))
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
}

Future<void> _setShoppingPointsDrafts({
  required String accountName,
  required List<ShoppingPointsDraftEntry> drafts,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = jsonEncode(drafts.map((d) => d.toJson()).toList());
  await prefs.setString(_shoppingPointsDraftsKey(accountName), encoded);
}

Future<void> _addShoppingPointsDraft({
  required String accountName,
  required ShoppingPointsDraftEntry draft,
  int maxEntries = 60,
}) async {
  final current = await _getShoppingPointsDrafts(accountName: accountName);
  final next = <ShoppingPointsDraftEntry>[
    draft,
    for (final d in current)
      if (d.id != draft.id) d,
  ];
  final trimmed =
      next.length <= maxEntries ? next : next.take(maxEntries).toList();
  await _setShoppingPointsDrafts(accountName: accountName, drafts: trimmed);
}

Future<void> _updateShoppingPointsDraft({
  required String accountName,
  required ShoppingPointsDraftEntry draft,
}) async {
  final current = await _getShoppingPointsDrafts(accountName: accountName);
  final next =
      current.map((d) => d.id == draft.id ? draft : d).toList(growable: false);
  await _setShoppingPointsDrafts(accountName: accountName, drafts: next);
}

Future<void> _removeShoppingPointsDraft({
  required String accountName,
  required String id,
}) async {
  final current = await _getShoppingPointsDrafts(accountName: accountName);
  final next = current.where((d) => d.id != id).toList(growable: false);
  await _setShoppingPointsDrafts(accountName: accountName, drafts: next);
}

// --- WMS Inventory Drafts ---
String _wmsInventoryDraftsKey(String accountName) {
  return PrefKeys.accountKey(accountName, 'wms_inventory_drafts_v1');
}

Future<List<WmsInventoryDraftEntry>> _getWmsInventoryDrafts({
  required String accountName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_wmsInventoryDraftsKey(accountName));
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((m) => WmsInventoryDraftEntry.fromJson(
              Map<String, dynamic>.from(m)))
        .toList(growable: false);
  } catch (_) {
    return const [];
  }
}

Future<void> _setWmsInventoryDrafts({
  required String accountName,
  required List<WmsInventoryDraftEntry> drafts,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = jsonEncode(drafts.map((d) => d.toJson()).toList());
  await prefs.setString(_wmsInventoryDraftsKey(accountName), encoded);
}

Future<void> _addWmsInventoryDraft({
  required String accountName,
  required WmsInventoryDraftEntry draft,
  int maxEntries = 30,
}) async {
  final current = await _getWmsInventoryDrafts(accountName: accountName);
  final next = <WmsInventoryDraftEntry>[
    draft,
    for (final d in current)
      if (d.id != draft.id) d,
  ];
  final trimmed =
      next.length <= maxEntries ? next : next.take(maxEntries).toList();
  await _setWmsInventoryDrafts(accountName: accountName, drafts: trimmed);
}

Future<void> _updateWmsInventoryDraft({
  required String accountName,
  required WmsInventoryDraftEntry draft,
}) async {
  final current = await _getWmsInventoryDrafts(accountName: accountName);
  final next =
      current.map((d) => d.id == draft.id ? draft : d).toList(growable: false);
  await _setWmsInventoryDrafts(accountName: accountName, drafts: next);
}

Future<void> _removeWmsInventoryDraft({
  required String accountName,
  required String id,
}) async {
  final current = await _getWmsInventoryDrafts(accountName: accountName);
  final next = current.where((d) => d.id != id).toList(growable: false);
  await _setWmsInventoryDrafts(accountName: accountName, drafts: next);
}

Future<void> _clearAllWmsInventoryDrafts({
  required String accountName,
}) async {
  await _setWmsInventoryDrafts(accountName: accountName, drafts: const []);
}
