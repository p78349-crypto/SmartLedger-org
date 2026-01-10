/// Korean text matching utilities.
///
/// Adds support for matching by Hangul initial consonants (초성).
/// Example: query `ㄱㅊ` matches `김치`.
class KoreanSearchUtils {
  static const List<String> _chosung = <String>[
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
    'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  ];

  static const Set<String> _compatChosungSet = <String>{
    'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ', 'ㅅ',
    'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ',
  };

  /// Returns a normalized string for matching (trim + lower-case).
  static String normalize(String input) => input.trim().toLowerCase();

  /// Returns true if [query] looks like a 초성 query (only compat jamo + spaces).
  static bool isChosungQuery(String query) {
    final q = normalize(query);
    if (q.isEmpty) return false;

    for (final rune in q.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == ' ') continue;
      if (!_compatChosungSet.contains(ch)) return false;
    }
    return true;
  }

  /// Extracts a 초성 string from Hangul syllables in [text].
  ///
  /// Non-Hangul characters are preserved as-is (lowercased by caller if desired).
  static String extractChosung(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final code = rune;
      // Hangul syllables: AC00-D7A3
      if (code >= 0xAC00 && code <= 0xD7A3) {
        final sIndex = code - 0xAC00;
        final lIndex = sIndex ~/ (21 * 28);
        buffer.write(_chosung[lIndex]);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Flexible match:
  /// - Normal substring match (case-insensitive)
  /// - If query is 초성-only, also matches against [text]'s extracted 초성.
  static bool matches(String text, String query) {
    final q = normalize(query);
    if (q.isEmpty) return true;

    final t = normalize(text);
    if (t.contains(q)) return true;

    if (isChosungQuery(q)) {
      final qNoSpace = q.replaceAll(RegExp(r'\s+'), '');
      final chosungNoSpace = extractChosung(t).replaceAll(RegExp(r'\s+'), '');
      return chosungNoSpace.contains(qNoSpace);
    }

    return false;
  }
}
