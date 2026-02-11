part of 'user_pref_service.dart';

// --- Main page management: reset, export/import, account cleanup ---

bool _isMainPageUiPrefSuffix(String suffix) {
  if (suffix.startsWith('main_page_')) return true;
  if (suffix == PrefKeys.mainPageIndexSuffix) return true;
  if (suffix == 'page_types') return true;
  if (suffix == 'hide_empty_slots') return true;
  if (suffix == 'show_edit_button') return true;
  if (suffix == 'icon_label_overrides_v1') return true;
  if (suffix.startsWith('page_')) return true;
  if (suffix.startsWith('pageId_')) return true;
  return false;
}

Future<void> _clearAllAccountScopedPrefs({
  required String accountName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final prefix = '${accountName}_';
  final keys = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();
  for (final key in keys) {
    await prefs.remove(key);
  }
}

Future<List<Map<String, dynamic>>> _exportMainPageUiPrefsSnapshot({
  required String accountName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final prefix = '${accountName}_';
  final keys = prefs
      .getKeys()
      .where((k) => k.startsWith(prefix))
      .map((k) => k.substring(prefix.length))
      .where(_isMainPageUiPrefSuffix)
      .toList()
    ..sort();

  final out = <Map<String, dynamic>>[];
  for (final suffix in keys) {
    final key = PrefKeys.accountKey(accountName, suffix);
    if (!prefs.containsKey(key)) continue;

    final sl = prefs.getStringList(key);
    if (sl != null) {
      out.add({'suffix': suffix, 'type': 'stringList', 'value': sl});
      continue;
    }
    final sv = prefs.getString(key);
    if (sv != null) {
      out.add({'suffix': suffix, 'type': 'string', 'value': sv});
      continue;
    }
    final iv = prefs.getInt(key);
    if (iv != null) {
      out.add({'suffix': suffix, 'type': 'int', 'value': iv});
      continue;
    }
    final dv = prefs.getDouble(key);
    if (dv != null) {
      out.add({'suffix': suffix, 'type': 'double', 'value': dv});
      continue;
    }
    final bv = prefs.getBool(key);
    if (bv != null) {
      out.add({'suffix': suffix, 'type': 'bool', 'value': bv});
      continue;
    }
  }
  return out;
}

Future<void> _importMainPageUiPrefsSnapshot({
  required String accountName,
  required List<dynamic> snapshot,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final prefix = '${accountName}_';
  final existingKeys = prefs
      .getKeys()
      .where((k) => k.startsWith(prefix))
      .map((k) => k.substring(prefix.length))
      .where(_isMainPageUiPrefSuffix)
      .toList();

  for (final suffix in existingKeys) {
    await prefs.remove(PrefKeys.accountKey(accountName, suffix));
  }

  for (final item in snapshot) {
    if (item is! Map) continue;
    final suffix = item['suffix'];
    final type = item['type'];
    final value = item['value'];
    if (suffix is! String || type is! String) continue;
    if (!_isMainPageUiPrefSuffix(suffix)) continue;

    final key = PrefKeys.accountKey(accountName, suffix);
    switch (type) {
      case 'stringList':
        if (value is List) {
          await prefs.setStringList(
            key,
            value.map((e) => e.toString()).toList(growable: false),
          );
        }
      case 'string':
        if (value is String) await prefs.setString(key, value);
      case 'int':
        if (value is num) await prefs.setInt(key, value.toInt());
      case 'double':
        if (value is num) await prefs.setDouble(key, value.toDouble());
      case 'bool':
        if (value is bool) await prefs.setBool(key, value);
    }
  }
}

Future<void> _resetAccountMainPages({
  required String accountName,
  int pageCount = 0,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final currentConfigs = await _getMainPageConfigs(
    accountName: accountName,
    pageCount: pageCount,
  );
  final defaultConfigs = _defaultMainPageConfigs();
  final pageIds = <String>{
    ...currentConfigs.map((c) => c.pageId),
    ...defaultConfigs.map((c) => c.pageId),
  };

  await prefs.remove(_mainPageConfigsKey(accountName));
  await prefs.remove(_mainPageLastIdKey(accountName));
  await prefs.remove(_mainPageIndexKey(accountName));
  await prefs.remove(_mainPageNamesKey(accountName));
  await prefs.remove(_pageTypesKey(accountName));
  await prefs.remove(_hideEmptySlotsKey(accountName));

  for (int i = 0; i < pageCount; i++) {
    await prefs.remove(_pageIconOrderKey(accountName, i));
    await prefs.remove(_pageIconSlotsKey(accountName, i));
  }

  for (final pageId in pageIds) {
    await prefs.remove(_pageIconOrderKeyById(accountName, pageId));
    await prefs.remove(_pageIconSlotsKeyById(accountName, pageId));
    await prefs.remove(_pageSlotGroupsKeyById(accountName, pageId));
  }

  final accountPrefix = '${accountName}_';
  final allKeys = prefs.getKeys();
  for (final key in allKeys) {
    if (!key.startsWith(accountPrefix)) continue;
    final isIndexBased = key.contains('_page_') &&
        (key.contains('_icon_slots') || key.contains('_icon_order'));
    final isPageIdBased = key.contains('_pageId_') &&
        (key.contains('_icon_slots') ||
            key.contains('_icon_order') ||
            key.contains('_slot_groups'));
    if (isIndexBased || isPageIdBased) await prefs.remove(key);
  }
}
