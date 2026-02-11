part of 'user_pref_service.dart';

// --- Main page config keys ---
String _mainPageConfigsKey(String a) =>
    PrefKeys.accountKey(a, 'main_page_configs_v1');
String _mainPageLastIdKey(String a) =>
    PrefKeys.accountKey(a, 'main_page_last_id');
String _mainPageIndexKey(String a) =>
    PrefKeys.accountKey(a, PrefKeys.mainPageIndexSuffix);
String _mainPageNamesKey(String a) =>
    PrefKeys.accountKey(a, 'main_page_names');
String _pageTypesKey(String a) => PrefKeys.accountKey(a, 'page_types');

List<MainPageConfig> _defaultMainPageConfigs() {
  return const <MainPageConfig>[
    MainPageConfig(
      pageId: 'page0', moduleKey: 'dashboard',
      pageType: 'icons', name: '대시보드',
    ),
    MainPageConfig(
      pageId: 'page1', moduleKey: 'purchase',
      pageType: 'icons', name: '요리/쇼핑/지출',
    ),
    MainPageConfig(
      pageId: 'page2', moduleKey: 'income',
      pageType: 'icons', name: '수입',
    ),
    MainPageConfig(
      pageId: 'page3', moduleKey: 'stats',
      pageType: 'icons', name: '통계',
    ),
    MainPageConfig(
      pageId: 'page4', moduleKey: 'asset',
      pageType: 'icons', name: '자산',
    ),
    MainPageConfig(
      pageId: 'page5', moduleKey: 'root',
      pageType: 'icons', name: 'ROOT',
    ),
    MainPageConfig(
      pageId: 'page6', moduleKey: 'settings',
      pageType: 'icons', name: '설정',
    ),
    MainPageConfig(
      pageId: 'page7', moduleKey: 'page7',
      pageType: 'icons', name: '페이지7',
    ),
    MainPageConfig(
      pageId: 'page8', moduleKey: 'page8',
      pageType: 'icons', name: '페이지8',
    ),
    MainPageConfig(
      pageId: 'page9', moduleKey: 'page9',
      pageType: 'icons', name: '페이지9',
    ),
    MainPageConfig(
      pageId: 'page10', moduleKey: 'page10',
      pageType: 'icons', name: '페이지10',
    ),
    MainPageConfig(
      pageId: 'page11', moduleKey: 'page11',
      pageType: 'icons', name: '페이지11',
    ),
    MainPageConfig(
      pageId: 'page12', moduleKey: 'page12',
      pageType: 'icons', name: '페이지12',
    ),
    MainPageConfig(
      pageId: 'page13', moduleKey: 'page13',
      pageType: 'icons', name: '페이지13',
    ),
    MainPageConfig(
      pageId: 'page14', moduleKey: 'page14',
      pageType: 'icons', name: '페이지14',
    ),
  ];
}

Future<void> _setMainPageConfigs({
  required String accountName,
  required List<MainPageConfig> configs,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    _mainPageConfigsKey(accountName),
    jsonEncode(configs.map((c) => c.toJson()).toList()),
  );
  await _setMainPageNames(
    accountName: accountName,
    names: configs.map((c) => c.name).toList(),
  );
  await _setPageTypes(
    accountName: accountName,
    types: configs.map((c) => c.pageType).toList(),
  );
}

Future<bool> _hasMainPageConfigs({required String accountName}) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey(_mainPageConfigsKey(accountName));
}

Future<List<MainPageConfig>> _getMainPageConfigs({
  required String accountName,
  int pageCount = 0,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_mainPageConfigsKey(accountName));
  if (raw != null && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final parsed = decoded
            .map(MainPageConfig.tryFromJson)
            .whereType<MainPageConfig>()
            .toList();
        if (parsed.isNotEmpty) {
          return _normalizeMainPageConfigs(parsed, pageCount);
        }
      }
    } catch (_) {
      // fall through to legacy
    }
  }

  final legacyNames = await _getMainPageNames(accountName: accountName);
  final legacyTypes = await _getPageTypes(accountName: accountName);
  final defaults = _defaultMainPageConfigs();

  final names = _normalizeStringList(
    legacyNames ?? defaults.map((c) => c.name).toList(),
    defaults.map((c) => c.name).toList(),
    pageCount,
  );
  final types = _normalizeStringList(
    legacyTypes,
    defaults.map((c) => c.pageType).toList(),
    pageCount,
  );

  final out = <MainPageConfig>[];
  for (int i = 0; i < pageCount && i < defaults.length; i++) {
    final d = defaults[i];
    out.add(d.copyWith(name: names[i], pageType: types[i]));
  }
  return out;
}

List<MainPageConfig> _normalizeMainPageConfigs(
  List<MainPageConfig> source,
  int pageCount,
) {
  final defaults = _defaultMainPageConfigs();
  final out = List<MainPageConfig>.from(source);
  if (out.length < pageCount) {
    out.addAll(defaults.sublist(out.length, pageCount));
  } else if (out.length > pageCount) {
    out.removeRange(pageCount, out.length);
  }
  for (int i = 0; i < out.length; i++) {
    final cfg = out[i];
    if (cfg.pageId == 'reserved_1' || cfg.pageId == 'reserved_2') {
      final normalizedName = cfg.pageId == 'reserved_1' ? '예약1' : '예약2';
      final shouldNormalizeModuleKey =
          cfg.moduleKey.isEmpty || cfg.moduleKey.startsWith('reserved');
      out[i] = cfg.copyWith(
        moduleKey: shouldNormalizeModuleKey ? 'reserved' : cfg.moduleKey,
        name: cfg.name.trim().isEmpty ? normalizedName : cfg.name,
      );
    }
  }
  return out;
}

List<String> _normalizeStringList(
  List<String> source,
  List<String> defaults,
  int count,
) {
  final out = List<String>.from(source);
  if (out.length < count) {
    out.addAll(defaults.sublist(out.length, count));
  } else if (out.length > count) {
    out.removeRange(count, out.length);
  }
  return out;
}

Future<void> _setMainPageIndex({
  required String accountName,
  required int index,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_mainPageIndexKey(accountName), index);
}

Future<int?> _getMainPageIndex({required String accountName}) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt(_mainPageIndexKey(accountName));
}

Future<void> _setMainPageLastId({
  required String accountName,
  required String pageId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_mainPageLastIdKey(accountName), pageId);
}

Future<String?> _getMainPageLastId({required String accountName}) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(_mainPageLastIdKey(accountName));
}

Future<void> _setMainPageNames({
  required String accountName,
  required List<String> names,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_mainPageNamesKey(accountName), names);
}

Future<List<String>?> _getMainPageNames({
  required String accountName,
}) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getStringList(_mainPageNamesKey(accountName));
}

Future<void> _setPageTypes({
  required String accountName,
  required List<String> types,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_pageTypesKey(accountName), types);
}

Future<List<String>> _getPageTypes({required String accountName}) async {
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getStringList(_pageTypesKey(accountName));
  return saved ?? List.filled(15, 'icons');
}
