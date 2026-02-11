part of 'korean_search_utils.dart';

// ============================================================
// Japanese Matching
// ============================================================

bool _matchesJapanese(String text, String query) {
  final t = text.trim();
  final q = query.trim();
  if (q.isEmpty) return true;

  if (t.toLowerCase().contains(q.toLowerCase())) return true;

  final tNorm = _normalizeJapanese(t);
  final qNorm = _normalizeJapanese(q);
  if (tNorm.contains(qNorm)) return true;

  final fullForms = _lookupJapaneseContraction(q);
  if (fullForms != null) {
    for (final form in fullForms) {
      if (t.toLowerCase().contains(form.toLowerCase())) return true;
      if (tNorm.contains(_normalizeJapanese(form))) return true;
    }
  }

  final contraction = _lookupJapaneseFullForm(q);
  if (contraction != null) {
    if (t.contains(contraction)) return true;
    if (tNorm.contains(_normalizeJapanese(contraction))) return true;
  }

  for (final entry in _japaneseThesaurus.entries) {
    for (final form in entry.value) {
      if (qNorm == _normalizeJapanese(form) ||
          q.toLowerCase() == form.toLowerCase()) {
        if (t.contains(entry.key) ||
            tNorm.contains(_normalizeJapanese(entry.key))) {
          return true;
        }
      }
    }
  }

  if (_isHiragana(q)) {
    for (final entry in _japaneseThesaurus.entries) {
      for (final form in entry.value) {
        final formHira = _normalizeJapanese(form);
        if (formHira.startsWith(qNorm)) {
          if (t.contains(entry.key)) return true;
          for (final f in entry.value) {
            if (t.contains(f)) return true;
          }
        }
      }
      if (_normalizeJapanese(entry.key).startsWith(qNorm) &&
          t.contains(entry.key)) {
        return true;
      }
    }
  }

  return false;
}

// ============================================================
// European Languages: Compound Decomposition & Matching
// ============================================================

bool _containsEuropeanAccents(String text) {
  return RegExp(
    r'[àáâãäåæçèéêëìíîïñòóôõöøùúûüýÿßœ]',
    caseSensitive: false,
  ).hasMatch(text);
}

String _removeEuropeanArticles(String text, {String? language}) {
  final result = _normalize(text);

  Set<String> stopWords;
  if (language != null && _europeanStopWords.containsKey(language)) {
    stopWords = _europeanStopWords[language]!;
  } else {
    stopWords = _europeanStopWords.values.expand((s) => s).toSet();
  }

  final words = result.split(RegExp(r'\s+'));
  final filtered = words.where((w) => !stopWords.contains(w)).toList();
  return filtered.join(' ');
}

List<String> _decomposeGermanCompound(String word) {
  final w = _normalize(word);
  final components = <String>[];

  for (final entry in _germanCompoundPrefixes.entries) {
    if (w.startsWith(entry.key) || w.contains(entry.key)) {
      components.add(entry.key);
    }
  }

  if (components.isEmpty && w.length > 6) {
    final patterns = [
      RegExp(r'(ungs?)(?=[a-zäöü])'),
      RegExp(r'(heit|keit)(?=[a-zäöü])'),
      RegExp(r'(schaft)(?=[a-zäöü])'),
      RegExp(r'(stelle|platz|haus|amt|hof)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(w);
      if (match != null) {
        if (match.start > 2) {
          components.add(w.substring(0, match.start));
        }
      }
    }
  }

  if (w.length >= 4) {
    final shortPrefix = w.substring(0, 4);
    if (!components.contains(shortPrefix)) {
      components.insert(0, shortPrefix);
    }
  }

  return components;
}

bool _matchesGermanCompound(String text, String query) {
  final t = _normalize(text);
  final q = _normalize(query);
  if (q.isEmpty) return true;

  if (t.contains(q)) return true;

  final words = t.split(RegExp(r'\s+'));
  for (final word in words) {
    for (final entry in _germanCompoundPrefixes.entries) {
      if (q == entry.key || q.startsWith(entry.key)) {
        for (final compound in entry.value) {
          if (word.contains(compound) || compound.contains(word)) {
            return true;
          }
        }
      }
    }

    if (word.startsWith(q)) return true;

    final components = _decomposeGermanCompound(word);
    for (final comp in components) {
      if (comp.startsWith(q) || q.startsWith(comp)) return true;
    }
  }

  return false;
}

bool _matchesEuropeanAbbreviation(String text, String query) {
  final t = _normalize(text);
  final q = _normalize(query);
  if (q.isEmpty) return true;

  if (t.contains(q)) return true;

  if (_europeanAbbreviations.containsKey(q)) {
    final expansions = _europeanAbbreviations[q]!;
    for (final expansion in expansions.values) {
      if (t.contains(expansion)) return true;
      final words = expansion.split(' ');
      if (words.every(t.contains)) return true;
    }
  }

  for (final entry in _europeanAbbreviations.entries) {
    for (final expansion in entry.value.values) {
      if (expansion.contains(q) && t.contains(entry.key)) {
        return true;
      }
    }
  }

  return false;
}

String? _matchesGlobalEmergencyCode(String query) {
  final q = _normalize(query);
  if (q.isEmpty) return null;

  for (final entry in _globalEmergencyCodes.entries) {
    final keywords = entry.value['keywords'] as Map<String, List<String>>;
    for (final langKeywords in keywords.values) {
      for (final keyword in langKeywords) {
        if (keyword.startsWith(q) || q.startsWith(keyword) || keyword == q) {
          return entry.key;
        }
      }
    }
  }

  return null;
}

List<String> _getEmergencyCodeKeywords(
  String globalId, {
  String? language,
}) {
  if (!_globalEmergencyCodes.containsKey(globalId)) return [];

  final keywords =
      _globalEmergencyCodes[globalId]!['keywords']
          as Map<String, List<String>>;

  if (language != null && keywords.containsKey(language)) {
    return keywords[language]!;
  }

  return keywords.values.expand((list) => list).toList();
}

bool _matchesEuropean(String text, String query) {
  final t = _normalize(text);
  final q = _normalize(query);
  if (q.isEmpty) return true;

  if (t.contains(q)) return true;

  final tNoArticles = _removeEuropeanArticles(text);
  if (tNoArticles.contains(q)) return true;

  if (_matchesGermanCompound(t, q)) return true;

  if (_matchesEuropeanAbbreviation(t, q)) return true;

  final emergencyId = _matchesGlobalEmergencyCode(q);
  if (emergencyId != null) {
    final allKeywords = _getEmergencyCodeKeywords(emergencyId);
    for (final keyword in allKeywords) {
      if (t.contains(keyword)) return true;
    }
  }

  final words = t.split(RegExp(r'\s+'));
  for (final word in words) {
    if (word.startsWith(q)) return true;
  }

  return false;
}
