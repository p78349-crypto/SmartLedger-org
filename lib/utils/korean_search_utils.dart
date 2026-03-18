// Multilingual text matching utilities.
//
// Supports:
// - Korean: Hangul initial consonants (초성) matching
// - English: Prefix search and acronym matching
// - Japanese: 4-mora contraction (4文字熟語) and reading-based prefix

part 'korean_search_utils_constants_kr_en.dart';
part 'korean_search_utils_constants_jp.dart';
part 'korean_search_utils_constants_eu.dart';
part 'korean_search_utils_methods_core.dart';
part 'korean_search_utils_methods_advanced.dart';
part 'korean_search_utils_methods_match.dart';

class MultilingualSearchUtils {
  static String normalize(String input) => _normalize(input);

  static bool isChosungQuery(String query) => _isChosungQuery(query);

  static bool isEnglishQuery(String query) => _isEnglishQuery(query);

  static bool isAcronymQuery(String query) => _isAcronymQuery(query);

  static bool containsJapanese(String text) => _containsJapanese(text);

  static bool isHiragana(String text) => _isHiragana(text);

  static bool isKatakana(String text) => _isKatakana(text);

  static String extractChosung(String text) => _extractChosung(text);

  static String extractAcronym(String text) => _extractAcronym(text);

  static String hiraganaToKatakana(String text) => _hiraganaToKatakana(text);

  static String katakanaToHiragana(String text) => _katakanaToHiragana(text);

  static String normalizeJapanese(String text) => _normalizeJapanese(text);

  static List<String>? lookupJapaneseContraction(String query) =>
      _lookupJapaneseContraction(query);

  static String? lookupJapaneseFullForm(String fullForm) =>
      _lookupJapaneseFullForm(fullForm);

  static bool matchesPrefix(String text, String prefix) =>
      _matchesPrefix(text, prefix);

  static bool matchesAcronym(String text, String query) =>
      _matchesAcronym(text, query);

  static bool matchesJapanese(String text, String query) =>
      _matchesJapanese(text, query);

  static bool containsEuropeanAccents(String text) =>
      _containsEuropeanAccents(text);

  static String removeEuropeanArticles(String text, {String? language}) =>
      _removeEuropeanArticles(text, language: language);

  static List<String> decomposeGermanCompound(String word) =>
      _decomposeGermanCompound(word);

  static bool matchesGermanCompound(String text, String query) =>
      _matchesGermanCompound(text, query);

  static bool matchesEuropeanAbbreviation(String text, String query) =>
      _matchesEuropeanAbbreviation(text, query);

  static String? matchesGlobalEmergencyCode(String query) =>
      _matchesGlobalEmergencyCode(query);

  static List<String> getEmergencyCodeKeywords(
    String globalId, {
    String? language,
  }) => _getEmergencyCodeKeywords(globalId, language: language);

  static bool matchesEuropean(String text, String query) =>
      _matchesEuropean(text, query);

  static bool matches(String text, String query) => _matches(text, query);

  static int matchScore(String text, String query) => _matchScore(text, query);

  static List<T> sortByRelevance<T>(
    List<T> items,
    String query,
    String Function(T) textExtractor,
  ) => _sortByRelevance(items, query, textExtractor);
}

/// Backward-compatible alias for existing code.
/// @deprecated Use [MultilingualSearchUtils] instead.
typedef KoreanSearchUtils = MultilingualSearchUtils;
