part of 'korean_search_utils.dart';

// ============================================================
// Normalization & Detection
// ============================================================

String _normalize(String input) => input.trim().toLowerCase();

bool _isChosungQuery(String query) {
  final q = _normalize(query);
  if (q.isEmpty) return false;

  for (final rune in q.runes) {
    final ch = String.fromCharCode(rune);
    if (ch == ' ') continue;
    if (!_compatChosungSet.contains(ch)) return false;
  }
  return true;
}

bool _isEnglishQuery(String query) {
  final q = _normalize(query);
  if (q.isEmpty) return false;
  return RegExp(r'^[a-z0-9\s\-&]+$').hasMatch(q);
}

bool _isAcronymQuery(String query) {
  final q = query.trim();
  if (q.isEmpty || q.length < 2 || q.length > 6) return false;
  return RegExp(r'^[A-Z&]+$').hasMatch(q);
}

bool _containsJapanese(String text) {
  for (final rune in text.runes) {
    if (rune >= 0x3040 && rune <= 0x309F) return true;
    if (rune >= 0x30A0 && rune <= 0x30FF) return true;
    if (rune >= 0x4E00 && rune <= 0x9FFF) return true;
    if (rune >= 0x31F0 && rune <= 0x31FF) return true;
    if (rune >= 0xFF65 && rune <= 0xFF9F) return true;
  }
  return false;
}

bool _isHiragana(String text) {
  if (text.isEmpty) return false;
  for (final rune in text.runes) {
    if (rune >= 0x3040 && rune <= 0x309F) continue;
    if (rune == 0x30FC) continue;
    if (rune == 0x0020) continue;
    return false;
  }
  return true;
}

bool _isKatakana(String text) {
  if (text.isEmpty) return false;
  for (final rune in text.runes) {
    if (rune >= 0x30A0 && rune <= 0x30FF) continue;
    if (rune == 0x0020) continue;
    return false;
  }
  return true;
}

// ============================================================
// Korean: 초성 Extraction
// ============================================================

String _extractChosung(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final code = rune;
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

// ============================================================
// English: Acronym Extraction
// ============================================================

String _extractAcronym(String text) {
  final words = _normalize(text).split(RegExp(r'\s+'));
  final buffer = StringBuffer();
  for (final word in words) {
    if (word.isNotEmpty) {
      if (_isStopWord(word)) continue;
      buffer.write(word[0]);
    }
  }
  return buffer.toString();
}

bool _isStopWord(String word) {
  const stopWords = {
    'a', 'an', 'the', 'of', 'and', 'or', 'to', 'for', 'in', 'on', 'at', 'by',
  };
  return stopWords.contains(word.toLowerCase());
}

// ============================================================
// Japanese: Kana Conversion & Thesaurus
// ============================================================

String _hiraganaToKatakana(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_hiraKataTable[ch] ?? ch);
  }
  return buffer.toString();
}

String _katakanaToHiragana(String text) {
  final buffer = StringBuffer();
  for (final rune in text.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_kataToHiraMap[ch] ?? ch);
  }
  return buffer.toString();
}

String _normalizeJapanese(String text) {
  return _katakanaToHiragana(text.trim());
}

List<String>? _lookupJapaneseContraction(String query) {
  if (_japaneseThesaurus.containsKey(query)) {
    return _japaneseThesaurus[query];
  }
  final katakana = _hiraganaToKatakana(query);
  if (_japaneseThesaurus.containsKey(katakana)) {
    return _japaneseThesaurus[katakana];
  }
  final hiragana = _katakanaToHiragana(query);
  for (final entry in _japaneseThesaurus.entries) {
    if (_katakanaToHiragana(entry.key) == hiragana) {
      return entry.value;
    }
  }
  return null;
}

String? _lookupJapaneseFullForm(String fullForm) {
  final normalized = fullForm.toLowerCase();
  return _japaneseReverseMap[normalized];
}

// ============================================================
// Matching Helpers
// ============================================================

bool _matchesPrefix(String text, String prefix) {
  final t = _normalize(text);
  final p = _normalize(prefix);
  if (p.isEmpty) return true;
  final words = t.split(RegExp(r'\s+'));
  for (final word in words) {
    if (word.startsWith(p)) return true;
  }
  return false;
}

bool _matchesAcronym(String text, String query) {
  final t = _normalize(text);
  final q = _normalize(query);
  if (q.isEmpty) return true;

  if (t.contains(q)) return true;

  if (_commonAcronyms.containsKey(q)) {
    final expansion = _commonAcronyms[q]!;
    if (t.contains(expansion)) return true;
  }

  for (final entry in _commonAcronyms.entries) {
    if (t.contains(entry.value) && entry.key == q) {
      return true;
    }
  }

  final textAcronym = _extractAcronym(t);
  if (textAcronym == q || textAcronym.contains(q)) return true;

  final words = t.split(RegExp(r'\s+'));
  if (words.length >= q.length) {
    final buffer = StringBuffer();
    for (var i = 0; i < words.length && buffer.length < q.length; i++) {
      if (words[i].isNotEmpty && !_isStopWord(words[i])) {
        buffer.write(words[i][0]);
      }
    }
    if (buffer.toString() == q) return true;
  }

  return false;
}
