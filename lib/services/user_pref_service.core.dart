part of 'user_pref_service.dart';

// --- Default count-like units constant ---
const List<String> _kDefaultCountLikeUnitsV1 = [
  '개',
  '알',
  '롤',
  '팩',
  '봉',
  '봉지',
  '캔',
  '병',
  '장',
  '매',
  '줄',
  '통',
  '박스',
  '포',
  '조각',
  '세트',
  '줄기',
];

List<String> _normalizeUnitList(Iterable<String> raw) {
  final seen = <String>{};
  final out = <String>[];
  for (final v in raw) {
    final u = v.trim();
    if (u.isEmpty) continue;
    final key = u.toLowerCase();
    if (!seen.add(key)) continue;
    out.add(u);
  }
  return out;
}

Future<List<String>> _getCountLikeUnitsV1() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(PrefKeys.countLikeUnitsV1);
  if (raw == null || raw.trim().isEmpty) {
    return _normalizeUnitList(_kDefaultCountLikeUnitsV1);
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return _normalizeUnitList(_kDefaultCountLikeUnitsV1);
    return _normalizeUnitList(decoded.whereType<String>());
  } catch (_) {
    return _normalizeUnitList(_kDefaultCountLikeUnitsV1);
  }
}

Future<void> _setCountLikeUnitsV1(List<String> units) async {
  final prefs = await SharedPreferences.getInstance();
  final normalized = _normalizeUnitList(units);
  await prefs.setString(PrefKeys.countLikeUnitsV1, jsonEncode(normalized));
}

Future<int> _getStockUseAutoAddDepletionDaysFoodV1() async {
  final prefs = await SharedPreferences.getInstance();
  final v = prefs.getInt(PrefKeys.stockUseAutoAddDepletionDaysFoodV1);
  if (v != null) return v.clamp(1, 30);
  final legacy = prefs.getInt(PrefKeys.stockUseAutoAddDepletionDaysV1);
  return (legacy ?? 3).clamp(1, 30);
}

Future<int> _getStockUseAutoAddDepletionDaysHouseholdV1() async {
  final prefs = await SharedPreferences.getInstance();
  final v = prefs.getInt(PrefKeys.stockUseAutoAddDepletionDaysHouseholdV1);
  if (v != null) return v.clamp(1, 30);
  final legacy = prefs.getInt(PrefKeys.stockUseAutoAddDepletionDaysV1);
  return (legacy ?? 5).clamp(1, 30);
}

Future<void> _setStockUseAutoAddDepletionDaysFoodV1(int days) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(
    PrefKeys.stockUseAutoAddDepletionDaysFoodV1,
    days.clamp(1, 30),
  );
}

Future<void> _setStockUseAutoAddDepletionDaysHouseholdV1(int days) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(
    PrefKeys.stockUseAutoAddDepletionDaysHouseholdV1,
    days.clamp(1, 30),
  );
}

Future<String> _getLanguageCode() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(PrefKeys.language);
  if (stored == null || stored == 'system') {
    return PlatformDispatcher.instance.locale.languageCode;
  }
  return stored;
}

String _withProfile(String suffix, String? profileKey) {
  final p = profileKey?.trim();
  if (p == null || p.isEmpty) return suffix;
  return '${suffix}_$p';
}

Future<bool> _getPage1FullScreenAdEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(PrefKeys.page1FullScreenAdEnabled) ?? false;
}

Future<void> _setPage1FullScreenAdEnabled({required bool enabled}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(PrefKeys.page1FullScreenAdEnabled, enabled);
}

Future<bool> _getIsOfficialUser() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(PrefKeys.isOfficialUser) ?? false;
}

Future<void> _setIsOfficialUser({required bool isOfficial}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(PrefKeys.isOfficialUser, isOfficial);
}

Future<bool> _getZeroQuickButtonsEnabled() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(PrefKeys.zeroQuickButtonsEnabled) ?? false;
}

Future<void> _setZeroQuickButtonsEnabled({required bool enabled}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(PrefKeys.zeroQuickButtonsEnabled, enabled);
}

Future<void> _setLastAccountName(String name) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(UserPrefService.lastAccountKey, name);
}

Future<String?> _getLastAccountName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(UserPrefService.lastAccountKey);
}

Future<void> _clearLastAccountName() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(UserPrefService.lastAccountKey);
}
