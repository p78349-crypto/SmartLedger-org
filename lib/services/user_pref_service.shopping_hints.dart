part of 'user_pref_service.dart';

// --- Shopping category hints & quick expense per-store ---
String _shoppingCategoryHintsKey(String a) =>
    PrefKeys.accountKey(a, 'shopping_category_hints_v1');
String _shoppingQuickExpenseLastMainCategoryKey(String a) =>
    PrefKeys.accountKey(a, 'shopping_quick_last_main_category_expense_v1');
String _shoppingQuickExpenseLastSubCategoryKey(String a) =>
    PrefKeys.accountKey(a, 'shopping_quick_last_sub_category_expense_v1');

String _normalizeStoreKey(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final collapsed = trimmed.replaceAll(RegExp(r'\s+'), ' ');
  final safe = collapsed.replaceAll(RegExp(r'[^a-zA-Z0-9가-힣 _\-]'), '');
  final compact = safe.replaceAll(' ', '');
  if (compact.isEmpty) return '';
  return compact.length > 24 ? compact.substring(0, 24) : compact;
}

String _shoppingQuickExpenseStoreLastPaymentKey(String a, String s) {
  final k = _normalizeStoreKey(s);
  return PrefKeys.accountKey(a, 'shopping_quick_${k}_pay_v1');
}

String _shoppingQuickExpenseStoreLastMainCategoryKey(String a, String s) {
  final k = _normalizeStoreKey(s);
  return PrefKeys.accountKey(a, 'shopping_quick_${k}_main_v1');
}

String _shoppingQuickExpenseStoreLastSubCategoryKey(String a, String s) {
  final k = _normalizeStoreKey(s);
  return PrefKeys.accountKey(a, 'shopping_quick_${k}_sub_v1');
}

String _normalizeShoppingHintKey(String raw) =>
    raw.trim().toLowerCase().replaceAll(' ', '');

Future<Map<String, CategoryHint>> _getShoppingCategoryHints({
  required String accountName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_shoppingCategoryHintsKey(accountName));
  if (raw == null || raw.trim().isEmpty) return <String, CategoryHint>{};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, CategoryHint>{};
    final out = <String, CategoryHint>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String || entry.value is! Map) continue;
      out[entry.key as String] =
          CategoryHint.fromJson(Map<String, dynamic>.from(entry.value as Map));
    }
    return out;
  } catch (_) {
    return <String, CategoryHint>{};
  }
}

Future<CategoryHint?> _getShoppingQuickExpenseLastCategory({
  required String accountName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final main = prefs.getString(
    _shoppingQuickExpenseLastMainCategoryKey(accountName),
  );
  if (main == null || main.trim().isEmpty) return null;
  final sub = prefs.getString(
    _shoppingQuickExpenseLastSubCategoryKey(accountName),
  );
  return CategoryHint(mainCategory: main.trim(), subCategory: sub?.trim());
}

Future<void> _setShoppingQuickExpenseLastCategory({
  required String accountName,
  required CategoryHint hint,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final main = hint.mainCategory.trim();
  if (main.isEmpty) {
    await prefs.remove(_shoppingQuickExpenseLastMainCategoryKey(accountName));
    await prefs.remove(_shoppingQuickExpenseLastSubCategoryKey(accountName));
    return;
  }
  await prefs.setString(
    _shoppingQuickExpenseLastMainCategoryKey(accountName), main,
  );
  final sub = hint.subCategory?.trim() ?? '';
  if (sub.isEmpty) {
    await prefs.remove(_shoppingQuickExpenseLastSubCategoryKey(accountName));
  } else {
    await prefs.setString(
      _shoppingQuickExpenseLastSubCategoryKey(accountName), sub,
    );
  }
}

Future<String?> _getShoppingQuickExpenseStoreLastPayment({
  required String accountName,
  required String storeKey,
}) async {
  final k = _normalizeStoreKey(storeKey);
  if (k.isEmpty) return null;
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(
    _shoppingQuickExpenseStoreLastPaymentKey(accountName, k),
  );
  final value = raw?.trim() ?? '';
  return value.isEmpty ? null : value;
}

Future<void> _setShoppingQuickExpenseStoreLastPayment({
  required String accountName,
  required String storeKey,
  required String payment,
}) async {
  final k = _normalizeStoreKey(storeKey);
  if (k.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  final value = payment.trim();
  if (value.isEmpty) {
    await prefs.remove(
      _shoppingQuickExpenseStoreLastPaymentKey(accountName, k),
    );
    return;
  }
  await prefs.setString(
    _shoppingQuickExpenseStoreLastPaymentKey(accountName, k), value,
  );
}

Future<CategoryHint?> _getShoppingQuickExpenseStoreLastCategory({
  required String accountName,
  required String storeKey,
}) async {
  final k = _normalizeStoreKey(storeKey);
  if (k.isEmpty) return null;
  final prefs = await SharedPreferences.getInstance();
  final main = prefs.getString(
    _shoppingQuickExpenseStoreLastMainCategoryKey(accountName, k),
  );
  if (main == null || main.trim().isEmpty) return null;
  final sub = prefs.getString(
    _shoppingQuickExpenseStoreLastSubCategoryKey(accountName, k),
  );
  return CategoryHint(mainCategory: main.trim(), subCategory: sub?.trim());
}

Future<void> _setShoppingQuickExpenseStoreLastCategory({
  required String accountName,
  required String storeKey,
  required CategoryHint hint,
}) async {
  final k = _normalizeStoreKey(storeKey);
  if (k.isEmpty) return;
  final prefs = await SharedPreferences.getInstance();
  final main = hint.mainCategory.trim();
  if (main.isEmpty) {
    await prefs.remove(
      _shoppingQuickExpenseStoreLastMainCategoryKey(accountName, k),
    );
    await prefs.remove(
      _shoppingQuickExpenseStoreLastSubCategoryKey(accountName, k),
    );
    return;
  }
  await prefs.setString(
    _shoppingQuickExpenseStoreLastMainCategoryKey(accountName, k), main,
  );
  final sub = hint.subCategory?.trim() ?? '';
  if (sub.isEmpty) {
    await prefs.remove(
      _shoppingQuickExpenseStoreLastSubCategoryKey(accountName, k),
    );
  } else {
    await prefs.setString(
      _shoppingQuickExpenseStoreLastSubCategoryKey(accountName, k), sub,
    );
  }
}

Future<void> _setShoppingCategoryHint({
  required String accountName,
  required String keyword,
  required CategoryHint hint,
  int maxItems = 500,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final current = await _getShoppingCategoryHints(accountName: accountName);
  final next = Map<String, CategoryHint>.from(current);
  final normalizedKey = _normalizeShoppingHintKey(keyword);
  if (normalizedKey.isEmpty) return;
  next[normalizedKey] = hint;
  while (next.length > maxItems) {
    next.remove(next.keys.first);
  }
  final data = <String, dynamic>{
    for (final e in next.entries) e.key: e.value.toJson(),
  };
  await prefs.setString(
    _shoppingCategoryHintsKey(accountName), jsonEncode(data),
  );
}

Future<void> _setShoppingCategoryHints({
  required String accountName,
  required Map<String, CategoryHint> hints,
  int maxItems = 500,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final normalized = <String, CategoryHint>{};
  for (final entry in hints.entries) {
    if (normalized.length >= maxItems) break;
    final key = _normalizeShoppingHintKey(entry.key);
    if (key.isEmpty) continue;
    normalized[key] = entry.value;
  }
  if (normalized.isEmpty) {
    await prefs.remove(_shoppingCategoryHintsKey(accountName));
    return;
  }
  final data = <String, dynamic>{
    for (final e in normalized.entries) e.key: e.value.toJson(),
  };
  await prefs.setString(
    _shoppingCategoryHintsKey(accountName), jsonEncode(data),
  );
}

Future<void> _clearShoppingCategoryHints({
  required String accountName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_shoppingCategoryHintsKey(accountName));
}

Future<int> _bootstrapShoppingCategoryHintsFromTransactions({
  required String accountName,
  int maxItems = 300,
  int maxScanTransactions = 2000,
  bool includeRefunds = false,
}) async {
  final existing = await _getShoppingCategoryHints(accountName: accountName);
  if (existing.isNotEmpty) return 0;
  final service = TransactionService();
  await service.loadTransactions();
  final all = service.getTransactions(accountName);
  if (all.isEmpty) return 0;
  final candidates = all
      .where((t) =>
          t.type == TransactionType.expense &&
          t.description.trim().isNotEmpty &&
          t.mainCategory != Transaction.defaultMainCategory &&
          (includeRefunds ? true : !t.isRefund))
      .toList(growable: false);
  if (candidates.isEmpty) return 0;
  candidates.sort((a, b) => b.date.compareTo(a.date));
  final next = <String, CategoryHint>{};
  final scanLimit =
      maxScanTransactions <= 0 ? candidates.length : maxScanTransactions;
  for (final t in candidates.take(scanLimit)) {
    if (next.length >= maxItems) break;
    final key = _normalizeShoppingHintKey(t.description);
    if (key.isEmpty) continue;
    if (next.containsKey(key)) continue;
    next[key] = CategoryHint(
      mainCategory: t.mainCategory,
      subCategory: t.subCategory,
    );
  }
  if (next.isEmpty) return 0;
  await _setShoppingCategoryHints(
    accountName: accountName, hints: next, maxItems: maxItems,
  );
  return next.length;
}
