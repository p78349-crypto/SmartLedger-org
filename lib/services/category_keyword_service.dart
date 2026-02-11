// ignore_for_file: lines_longer_than_80_chars

/// Offline keyword-based category classifier for expense transactions.
///
/// Provides fallback classification when user history hints are unavailable.
/// Uses a curated dictionary of Korean product keywords mapped to categories.
library;

part 'category_keyword_service_food_keywords.dart';
part 'category_keyword_service_general_keywords.dart';

class CategoryKeywordService {
  CategoryKeywordService._();
  static final CategoryKeywordService instance = CategoryKeywordService._();

  /// Primary keyword → category mapping (merged from part files).
  static const Map<String, (String, String?)> _keywordToCategory = {
    ..._foodKeywords,
    ..._generalKeywords,
  };

  /// Fuzzy matching threshold: 0.0 (exact) to 1.0 (very loose).
  static const double _fuzzyThreshold = 0.25;

  /// Normalize input for matching.
  String _normalize(String raw) {
    var s = raw.trim().toLowerCase();
    if (s.isEmpty) return '';

    // Remove promo patterns
    s = s.replaceAll(RegExp(r'\d+\s*[+×x]\s*\d+'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), '');
    s = s.replaceAll(RegExp(r'[^a-z0-9가-힣]'), '');

    // Remove trailing units
    s = s.replaceAll(
      RegExp(r'(\d+(?:\.\d+)?)(ml|l|kg|g|mg|개|입|팩|봉|병|캔|장|p|pcs|pc|box)$'),
      '',
    );

    // Remove promo suffixes
    s = s.replaceAll(RegExp(r'(행사|증정|무료|덤|할인|특가|세일)$'), '');

    return s;
  }

  /// Simple Levenshtein-based similarity (0.0 to 1.0).
  double _similarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final len = a.length > b.length ? a.length : b.length;
    final dist = _levenshtein(a, b);
    return 1.0 - (dist / len);
  }

  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final sLen = s.length;
    final tLen = t.length;
    var prev = List<int>.generate(tLen + 1, (i) => i);
    var curr = List<int>.filled(tLen + 1, 0);

    for (var i = 1; i <= sLen; i++) {
      curr[0] = i;
      for (var j = 1; j <= tLen; j++) {
        final cost = s[i - 1] == t[j - 1] ? 0 : 1;
        curr[j] = [
          prev[j] + 1, // deletion
          curr[j - 1] + 1, // insertion
          prev[j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[tLen];
  }

  /// Classify a product description.
  ///
  /// Returns (mainCategory, subCategory?) or null if no match.
  (String, String?)? classify(String description) {
    final normalized = _normalize(description);
    if (normalized.isEmpty) return null;

    // 1. Exact keyword match
    final exact = _keywordToCategory[normalized];
    if (exact != null) return exact;

    // 2. Substring/contains match (keyword in description)
    (String, String?)? bestContains;
    var bestContainsLen = 0;
    for (final entry in _keywordToCategory.entries) {
      final kw = entry.key;
      if (kw.length <= bestContainsLen) continue;
      if (normalized.contains(kw)) {
        bestContains = entry.value;
        bestContainsLen = kw.length;
      }
    }
    if (bestContains != null) return bestContains;

    // 3. Fuzzy match (for typos)
    (String, String?)? bestFuzzy;
    var bestFuzzyScore = 0.0;
    for (final entry in _keywordToCategory.entries) {
      final kw = entry.key;
      // Only fuzzy-match if lengths are somewhat similar
      if ((normalized.length - kw.length).abs() > 3) continue;
      final score = _similarity(normalized, kw);
      if (score > _fuzzyThreshold && score > bestFuzzyScore) {
        bestFuzzy = entry.value;
        bestFuzzyScore = score;
      }
    }
    if (bestFuzzy != null) return bestFuzzy;

    return null;
  }

  /// Check if a main category is valid in the given category options.
  bool isValidMainCategory(
    String main,
    Map<String, List<String>> categoryOptions,
  ) {
    return categoryOptions.containsKey(main);
  }

  /// Check if a sub category is valid for the given main category.
  bool isValidSubCategory(
    String main,
    String? sub,
    Map<String, List<String>> categoryOptions,
  ) {
    if (sub == null || sub.isEmpty) return true;
    final subs = categoryOptions[main];
    if (subs == null) return false;
    return subs.contains(sub);
  }
}
