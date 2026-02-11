part of 'korean_search_utils.dart';

// ============================================================
// Main Matching Functions
// ============================================================

bool _matches(String text, String query) {
  final q = _normalize(query);
  if (q.isEmpty) return true;

  final t = _normalize(text);

  if (t.contains(q)) return true;

  if (_isChosungQuery(q)) {
    final qNoSpace = q.replaceAll(RegExp(r'\s+'), '');
    final chosungNoSpace = _extractChosung(t).replaceAll(RegExp(r'\s+'), '');
    if (chosungNoSpace.contains(qNoSpace)) return true;
  }

  if (_isEnglishQuery(q) && _matchesPrefix(t, q)) {
    return true;
  }

  if (_isAcronymQuery(query) || _commonAcronyms.containsKey(q)) {
    if (_matchesAcronym(t, q)) return true;
  }

  if (_containsJapanese(query) || _containsJapanese(text)) {
    if (_matchesJapanese(text, query)) return true;
  }

  if (_matchesEuropean(text, query)) return true;

  return false;
}

int _matchScore(String text, String query) {
  final q = _normalize(query);
  if (q.isEmpty) return 100;

  final t = _normalize(text);

  if (t == q) return 100;

  if (t.startsWith(q)) return 90;

  if (_isEnglishQuery(q) && _matchesPrefix(t, q)) return 80;

  if (_matchesGermanCompound(t, q) && !t.contains(q)) return 78;

  if (_europeanAbbreviations.containsKey(q)) {
    if (_matchesEuropeanAbbreviation(t, q)) return 76;
  }

  if (_containsJapanese(query) || _containsJapanese(text)) {
    final fullForms = _lookupJapaneseContraction(query);
    if (fullForms != null) {
      for (final form in fullForms) {
        if (t.contains(form.toLowerCase()) ||
            _normalizeJapanese(text).contains(_normalizeJapanese(form))) {
          return 75;
        }
      }
    }
    final tNorm = _normalizeJapanese(text);
    final qNorm = _normalizeJapanese(query);
    if (tNorm.startsWith(qNorm)) return 75;
    if (_isHiragana(query.trim()) && _matchesJapanese(text, query)) return 55;
  }

  final emergencyId = _matchesGlobalEmergencyCode(q);
  if (emergencyId != null) {
    final allKeywords = _getEmergencyCodeKeywords(emergencyId);
    for (final keyword in allKeywords) {
      if (t.contains(keyword)) return 74;
    }
  }

  if ((_isAcronymQuery(query) || _commonAcronyms.containsKey(q)) &&
      _matchesAcronym(t, q)) {
    return 70;
  }

  if (_isChosungQuery(q)) {
    final qNoSpace = q.replaceAll(RegExp(r'\s+'), '');
    final chosungNoSpace = _extractChosung(t).replaceAll(RegExp(r'\s+'), '');
    if (chosungNoSpace.contains(qNoSpace)) return 60;
  }

  final tNoArticles = _removeEuropeanArticles(text);
  if (tNoArticles.contains(q) && !t.contains(q)) return 52;

  if (t.contains(q)) return 50;

  if (_containsJapanese(query) || _containsJapanese(text)) {
    if (_normalizeJapanese(text).contains(_normalizeJapanese(query))) return 50;
  }

  if (_matchesEuropean(text, query)) return 45;

  return 0;
}

List<T> _sortByRelevance<T>(
  List<T> items,
  String query,
  String Function(T) textExtractor,
) {
  if (query.trim().isEmpty) return items;

  final scored =
      items
          .map(
            (item) => MapEntry(item, _matchScore(textExtractor(item), query)),
          )
          .where((entry) => entry.value > 0)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

  return scored.map((e) => e.key).toList();
}
