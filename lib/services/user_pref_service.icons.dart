part of 'user_pref_service.dart';

// --- Per-page icon settings (index-based & pageId-based) ---
String _pageIconOrderKey(String a, int i, {String? profileKey}) =>
    PrefKeys.accountKey(a, _withProfile('page_${i}_icon_order', profileKey));
String _pageIconSlotsKey(String a, int i, {String? profileKey}) =>
    PrefKeys.accountKey(a, _withProfile('page_${i}_icon_slots', profileKey));
String _pageIdKey(String a, String pid, String s) =>
    PrefKeys.accountKey(a, 'pageId_${pid}_$s');
String _pageIconOrderKeyById(String a, String pid) =>
    _pageIdKey(a, pid, 'icon_order');
String _pageIconSlotsKeyById(String a, String pid) =>
    _pageIdKey(a, pid, 'icon_slots');
String _pageSlotGroupsKeyById(String a, String pid) =>
    _pageIdKey(a, pid, 'slot_groups');
String _pageSlotGroupsKey(String a, int i) =>
    PrefKeys.accountKey(a, 'page_${i}_slot_groups');
String _showEditButtonKey(String a) =>
    PrefKeys.accountKey(a, 'show_edit_button');
String _hideEmptySlotsKey(String a) =>
    PrefKeys.accountKey(a, 'hide_empty_slots');
String _iconLabelOverridesKey(String a, {String? profileKey}) =>
    PrefKeys.accountKey(a, _withProfile('icon_label_overrides_v1', profileKey));

// --- PageId-based icon settings ---
Future<void> _setPageIconSettingsById({
  required String accountName,
  required String pageId,
  int? legacyPageIndex,
  required List<String> order,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_pageIconOrderKeyById(accountName, pageId), order);
  if (legacyPageIndex != null) {
    await _setPageIconSettings(
      accountName: accountName,
      pageIndex: legacyPageIndex,
      order: order,
    );
  }
}

Future<({List<String> order})> _getPageIconSettingsById({
  required String accountName,
  required String pageId,
  int? legacyPageIndex,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final order = prefs.getStringList(_pageIconOrderKeyById(accountName, pageId));
  if (order != null) return (order: order);
  if (legacyPageIndex != null) {
    return _getPageIconSettings(
      accountName: accountName,
      pageIndex: legacyPageIndex,
    );
  }
  return (order: <String>[]);
}

Future<void> _setPageIconSlotsById({
  required String accountName,
  required String pageId,
  int? legacyPageIndex,
  required List<String> slots,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_pageIconSlotsKeyById(accountName, pageId), slots);
  if (legacyPageIndex != null) {
    await _setPageIconSlots(
      accountName: accountName,
      pageIndex: legacyPageIndex,
      slots: slots,
    );
  }
}

Future<List<String>> _getPageIconSlotsById({
  required String accountName,
  required String pageId,
  int? legacyPageIndex,
  int slotCount = Page1BottomQuickIcons.slotCount,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList(_pageIconSlotsKeyById(accountName, pageId));
  if (saved != null) {
    if (saved.length >= slotCount) return saved.sublist(0, slotCount);
    return [...saved, ...List<String>.filled(slotCount - saved.length, '')];
  }
  if (legacyPageIndex != null) {
    return _getPageIconSlots(
      accountName: accountName,
      pageIndex: legacyPageIndex,
      slotCount: slotCount,
    );
  }
  return List<String>.filled(slotCount, '');
}

Future<void> _setPageSlotGroupsById({
  required String accountName,
  required String pageId,
  int? legacyPageIndex,
  required List<List<String>> groups,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final strings = groups.map((g) => g.join(',')).toList();
  await prefs.setStringList(
    _pageSlotGroupsKeyById(accountName, pageId),
    strings,
  );
  if (legacyPageIndex != null) {
    await _setPageSlotGroups(
      accountName: accountName,
      pageIndex: legacyPageIndex,
      groups: groups,
    );
  }
}

Future<List<List<String>>> _getPageSlotGroupsById({
  required String accountName,
  required String pageId,
  int? legacyPageIndex,
  int slotCount = Page1BottomQuickIcons.slotCount,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList(
    _pageSlotGroupsKeyById(accountName, pageId),
  );
  if (saved != null) {
    final list = saved
        .take(slotCount)
        .map((s) => s.isEmpty ? <String>[] : s.split(','))
        .toList();
    if (list.length >= slotCount) return list.sublist(0, slotCount);
    return [
      ...list,
      ...List.generate(slotCount - list.length, (_) => <String>[]),
    ];
  }
  if (legacyPageIndex != null) {
    return _getPageSlotGroups(
      accountName: accountName,
      pageIndex: legacyPageIndex,
      slotCount: slotCount,
    );
  }
  return List.generate(slotCount, (_) => <String>[]);
}

// --- Show/hide, label overrides ---
Future<void> _setShowEditButton({
  required String accountName,
  required bool show,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_showEditButtonKey(accountName), show);
}

Future<bool> _getShowEditButton({required String accountName}) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_showEditButtonKey(accountName)) ?? true;
}

Future<void> _setHideEmptySlots({
  required String accountName,
  required bool hide,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_hideEmptySlotsKey(accountName), hide);
}

Future<bool> _getHideEmptySlots({required String accountName}) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_hideEmptySlotsKey(accountName)) ?? true;
}

Future<Map<String, String>> _getIconLabelOverrides({
  required String accountName,
  String? profileKey,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(
    _iconLabelOverridesKey(accountName, profileKey: profileKey),
  );
  if (raw == null || raw.isEmpty) return <String, String>{};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, String>{};
    final result = <String, String>{};
    for (final entry in decoded.entries) {
      if (entry.key is String && entry.value is String) {
        result[entry.key as String] = entry.value as String;
      }
    }
    return result;
  } catch (_) {
    return <String, String>{};
  }
}

Future<void> _setIconLabelOverride({
  required String accountName,
  required String iconId,
  required String? label,
  String? profileKey,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final current = await _getIconLabelOverrides(
    accountName: accountName,
    profileKey: profileKey,
  );
  final next = Map<String, String>.from(current);
  final normalized = label?.trim();
  if (normalized == null || normalized.isEmpty) {
    next.remove(iconId);
  } else {
    next[iconId] = normalized;
  }
  await prefs.setString(
    _iconLabelOverridesKey(accountName, profileKey: profileKey),
    jsonEncode(next),
  );
}

// --- Legacy index-based icon settings ---
Future<void> _setPageIconSettings({
  required String accountName,
  required int pageIndex,
  required List<String> order,
  String? profileKey,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _pageIconOrderKey(accountName, pageIndex, profileKey: profileKey),
    order,
  );
}

Future<({List<String> order})> _getPageIconSettings({
  required String accountName,
  required int pageIndex,
  String? profileKey,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final order =
      prefs.getStringList(
        _pageIconOrderKey(accountName, pageIndex, profileKey: profileKey),
      ) ??
      [];
  return (order: order);
}

Future<void> _setPageIconSlots({
  required String accountName,
  required int pageIndex,
  required List<String> slots,
  String? profileKey,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _pageIconSlotsKey(accountName, pageIndex, profileKey: profileKey),
    slots,
  );
}

Future<List<String>> _getPageIconSlots({
  required String accountName,
  required int pageIndex,
  int slotCount = Page1BottomQuickIcons.slotCount,
  String? profileKey,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList(
    _pageIconSlotsKey(accountName, pageIndex, profileKey: profileKey),
  );
  if (saved == null) return List<String>.filled(slotCount, '');
  if (saved.length >= slotCount) return saved.sublist(0, slotCount);
  return [...saved, ...List<String>.filled(slotCount - saved.length, '')];
}

Future<void> _setPageSlotGroups({
  required String accountName,
  required int pageIndex,
  required List<List<String>> groups,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final strings = groups.map((g) => g.join(',')).toList();
  await prefs.setStringList(
    _pageSlotGroupsKey(accountName, pageIndex),
    strings,
  );
}

Future<List<List<String>>> _getPageSlotGroups({
  required String accountName,
  required int pageIndex,
  int slotCount = Page1BottomQuickIcons.slotCount,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList(_pageSlotGroupsKey(accountName, pageIndex));
  if (saved == null) return List.generate(slotCount, (_) => []);
  final list = saved
      .take(slotCount)
      .map((s) => s.isEmpty ? <String>[] : s.split(','))
      .toList();
  if (list.length >= slotCount) return list.sublist(0, slotCount);
  return [
    ...list,
    ...List.generate(slotCount - list.length, (_) => <String>[]),
  ];
}
