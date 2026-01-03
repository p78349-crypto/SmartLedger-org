/// Defines income-specific categories used for
/// transaction and planning screens.
class IncomeCategoryDefinitions {
  IncomeCategoryDefinitions._();

  static const String defaultCategory = '미분류';

  static const Map<String, List<String>> categoryOptions = {
    defaultCategory: <String>[],
    '주수입': ['급여', '배우자 급여', '출장비'],
    '사업소득': ['사업 순수입', '프리랜서 수입'],
    '부수입': ['상여금', '명절 보너스', '성과급', '용돈', '선물'],
    '금융소득': ['예적금 이자', '배당금', '주식 수익', '코인 수익', '투자 수익'],
    '기타소득': ['중고거래 수익', '앱테크', '부조금(경조사)', '환급금', '아르바이트비', '부동산 월세'],
  };

  static List<String> get mainCategories =>
      categoryOptions.keys.toList(growable: false);

  static String? get defaultMainCategory {
    for (final entry in categoryOptions.entries) {
      if (entry.key != defaultCategory && entry.value.isNotEmpty) {
        return entry.key;
      }
    }
    return null;
  }

  static String? firstSubcategoryOf(String mainCategory) {
    final subs = categoryOptions[mainCategory];
    if (subs == null || subs.isEmpty) {
      return null;
    }
    return subs.first;
  }
}
