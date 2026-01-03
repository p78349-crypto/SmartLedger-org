import 'package:flutter/foundation.dart';

@immutable
class StoreMemoUtils {
  const StoreMemoUtils._();

  /// Extracts a store key from a memo-like text.
  ///
  /// Rules (kept intentionally conservative):
  /// - Use only the first line.
  /// - Stop at common separators (/ | ,).
  /// - Trim surrounding brackets/quotes.
  /// - Collapse whitespace.
  static String? extractStoreKey(String? raw) {
    var text = (raw ?? '').trim();
    if (text.isEmpty) return null;

    text = text.split(RegExp(r'[\r\n]+')).first.trim();
    text = text.split(RegExp(r'\s*[\/|,]')).first.trim();

    text = _stripWrapping(text);
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text.isEmpty ? null : text;
  }

  /// Normalizes memo for matching (lowercase, first line, collapsed spaces).
  static String normalizeMemoForMatch(String raw) {
    var text = raw.trim().toLowerCase();
    if (text.isEmpty) return '';

    text = text.split(RegExp(r'[\r\n]+')).first.trim();
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text;
  }

  static String _stripWrapping(String text) {
    var t = text.trim();
    if (t.isEmpty) return t;

    // Repeat a few times to handle nested wrapping like "[대형마트]".
    for (var i = 0; i < 3; i++) {
      final before = t;
      t = _stripOnce(t);
      if (t == before) break;
    }

    return t.trim();
  }

  static String _stripOnce(String text) {
    final t = text.trim();
    if (t.length < 2) return t;

    final first = t.substring(0, 1);
    final last = t.substring(t.length - 1);

    const pairs = <String, String>{
      '[': ']',
      '(': ')',
      '{': '}',
      '<': '>',
      '"': '"',
      "'": "'",
      '“': '”',
      '‘': '’',
    };

    final expectedLast = pairs[first];
    if (expectedLast != null && last == expectedLast) {
      return t.substring(1, t.length - 1).trim();
    }

    return t;
  }
}
