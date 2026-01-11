import '../models/transaction.dart';

class RoiUtils {
  /// Compute a heuristic ROI summary over a date range.
  ///
  /// Matching rules (in order):
  /// 1) income.originalTransactionId == expense.id
  /// 2) store equality (if enabled)
  /// 3) supplier equality (if enabled)
  /// 4) keyword overlap between expense and income (if enabled)
  ///
  /// Returns a map with keys: `overallRoi`, `totalSpent`, `totalReturn`, `byCategory`.
  static Map<String, dynamic> computeOverallRoi(
    List<Transaction> txs, {
    required DateTime start,
    required DateTime end,
    int lookaheadMonths = 3,
    bool matchByStore = true,
    bool matchBySupplier = true,
    bool matchByKeywords = true,
    int minKeywordLength = 3,
    int minKeywordMatches = 1,
  }) {
    final expenses = txs.where((t) {
      if (t.type != TransactionType.expense) return false;
      final d = t.date;
      return !d.isBefore(start) && d.isBefore(end);
    }).toList();

    double totalSpent = 0.0;
    double totalReturn = 0.0;
    final Map<String, Map<String, double>> byCategory = {};

    // basic stopword list (English + common Korean particles); can be extended
    final Set<String> stopwords = {
      'the',
      'and',
      'for',
      'with',
      'from',
      'paid',
      'using',
      'card',
      'cash',
      '을',
      '를',
      '에',
      '의',
      '로',
      '에서',
      '과',
      '와',
      '및',
      '등',
      '에선',
      '로서',
    };

    Set<String> tokenize(String? raw) {
      if (raw == null || raw.trim().isEmpty) return {};
      final cleaned = raw
          .replaceAll(RegExp(r'[^0-9a-zA-Zㄱ-ㅎ가-힣\s]'), ' ')
          .toLowerCase();
      final parts = cleaned.split(RegExp(r'\s+'));
      return parts
          .where((p) => p.length >= minKeywordLength && !stopwords.contains(p))
          .toSet();
    }

    for (final e in expenses) {
      final spent = e.amount.abs();
      totalSpent += spent;
      final lookEnd = DateTime(e.date.year, e.date.month + lookaheadMonths + 1);

      final eTokens = <String>{};
      eTokens.addAll(tokenize(e.description));
      eTokens.addAll(tokenize(e.memo));
      eTokens.addAll(tokenize(e.store));
      eTokens.addAll(tokenize(e.supplier));

      double returns = 0.0;

      for (final t in txs) {
        if (t.type != TransactionType.income) continue;
        if (t.date.isBefore(e.date) || !t.date.isBefore(lookEnd)) continue;

        var matched = false;

        if (t.originalTransactionId != null &&
            t.originalTransactionId == e.id) {
          matched = true;
        }

        if (!matched && matchByStore && e.store != null && t.store == e.store) {
          matched = true;
        }

        if (!matched &&
            matchBySupplier &&
            e.supplier != null &&
            t.supplier == e.supplier) {
          matched = true;
        }

        if (!matched && matchByKeywords) {
          final tTokens = <String>{};
          tTokens.addAll(tokenize(t.description));
          tTokens.addAll(tokenize(t.memo));
          tTokens.addAll(tokenize(t.store));
          tTokens.addAll(tokenize(t.supplier));
          final common = eTokens.intersection(tTokens);
          if (common.length >= minKeywordMatches) matched = true;
        }

        if (matched) {
          // assign weight by match strength
          double weight = 0.0;
          if (t.originalTransactionId != null &&
              t.originalTransactionId == e.id) {
            weight = 1.0;
          } else if (matchByStore && e.store != null && t.store == e.store) {
            weight = 0.9;
          } else if (matchBySupplier &&
              e.supplier != null &&
              t.supplier == e.supplier) {
            weight = 0.8;
          } else if (matchByKeywords) {
            final tTokens = <String>{};
            tTokens.addAll(tokenize(t.description));
            tTokens.addAll(tokenize(t.memo));
            tTokens.addAll(tokenize(t.store));
            tTokens.addAll(tokenize(t.supplier));
            final common = eTokens.intersection(tTokens);
            weight = 0.3 + (common.length * 0.1);
            if (weight > 0.95) weight = 0.95;
          }

          returns += t.amount.abs() * weight;
        }
      }

      totalReturn += returns;

      final cat = e.mainCategory;
      final entry = byCategory.putIfAbsent(
        cat,
        () => {'spent': 0.0, 'return': 0.0},
      );
      entry['spent'] = entry['spent']! + spent;
      entry['return'] = entry['return']! + returns;
    }

    double? overallRoi;
    if (totalSpent > 0) {
      overallRoi = (totalReturn - totalSpent) / totalSpent;
    }

    final Map<String, Map<String, dynamic>> perCat = {};
    for (final kv in byCategory.entries) {
      final s = kv.value['spent'] ?? 0.0;
      final r = kv.value['return'] ?? 0.0;
      double? roi;
      if (s > 0) roi = (r - s) / s;
      perCat[kv.key] = {'spent': s, 'return': r, 'roi': roi};
    }

    return {
      'overallRoi': overallRoi,
      'totalSpent': totalSpent,
      'totalReturn': totalReturn,
      'byCategory': perCat,
    };
  }
}
