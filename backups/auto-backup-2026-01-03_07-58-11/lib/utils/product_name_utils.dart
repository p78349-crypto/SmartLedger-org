import 'package:flutter/foundation.dart';

@immutable
class ProductNameUtils {
  const ProductNameUtils._();

  /// Builds a conservative normalization key for product grouping.
  ///
  /// Goal: reduce fragmentation caused by spacing/punctuation variations.
  /// Non-goal: aggressive synonym merging (risking wrong grouping).
  static String normalizeKey(String raw) {
    var text = raw.trim().toLowerCase();
    if (text.isEmpty) return '';

    // Remove parenthetical notes which frequently vary.
    text = text.replaceAll(RegExp(r'\([^)]*\)'), '');
    text = text.replaceAll(RegExp(r'\[[^\]]*\]'), '');

    // Keep only letters/digits (Korean/English) to avoid punctuation splits.
    final sb = StringBuffer();
    for (final codeUnit in text.runes) {
      final ch = String.fromCharCode(codeUnit);
      if (RegExp(r'[0-9a-z\uAC00-\uD7A3]').hasMatch(ch)) {
        sb.write(ch);
      }
    }

    return sb.toString();
  }
}

