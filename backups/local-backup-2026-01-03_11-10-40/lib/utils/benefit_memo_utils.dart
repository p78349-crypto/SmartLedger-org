import 'dart:convert';

/// Parses/encodes benefit info used for stats.
///
/// A) Memo rule (MVP): put one of the following anywhere in memo:
/// - "혜택:카드=1200, 배송=3000"
/// - "혜택: 카드:1200 배송:3000" (separators are flexible)
///
/// Keys are kept as-is (trimmed). Amounts accept commas.
class BenefitMemoUtils {
  BenefitMemoUtils._();

  static const String prefix = '혜택:';

  /// Extracts benefit map from memo.
  /// Returns empty map if none found.
  static Map<String, double> parseBenefitByType(String? memo) {
    final text = (memo ?? '').trim();
    if (text.isEmpty) return const <String, double>{};

    final lines = text.split(RegExp(r'\r?\n'));
    final result = <String, double>{};

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final idx = line.indexOf(prefix);
      if (idx < 0) continue;

      final tail = line.substring(idx + prefix.length).trim();
      if (tail.isEmpty) continue;

      _parsePairsInto(result, tail);
    }

    return result;
  }

  /// Encodes a benefit map as JSON (B: structured storage).
  static String encodeBenefitJson(Map<String, double> byType) {
    final cleaned = <String, double>{};
    for (final e in byType.entries) {
      final key = e.key.trim();
      final value = e.value;
      if (key.isEmpty) continue;
      if (value.isNaN || value.isInfinite) continue;
      if (value <= 0) continue;
      cleaned[key] = value;
    }
    return jsonEncode(cleaned);
  }

  /// Decodes structured JSON into benefit map.
  static Map<String, double> decodeBenefitJson(String? json) {
    final raw = (json ?? '').trim();
    if (raw.isEmpty) return const <String, double>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const <String, double>{};

      final result = <String, double>{};
      for (final entry in decoded.entries) {
        final k = entry.key;
        final v = entry.value;
        if (k is! String) continue;
        final key = k.trim();
        if (key.isEmpty) continue;

        double? value;
        if (v is num) {
          value = v.toDouble();
        } else if (v is String) {
          value = double.tryParse(v.trim().replaceAll(',', ''));
        }

        if (value == null || value <= 0) continue;
        result[key] = value;
      }

      return result;
    } catch (_) {
      return const <String, double>{};
    }
  }

  static void _parsePairsInto(Map<String, double> target, String raw) {
    // Split by comma or multiple spaces.
    final tokens = raw
        .split(RegExp(r'\s*,\s*|\s{2,}'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    for (final token in tokens) {
      // Allow multiple pairs inside one token (single-space separated).
      final parts = token
          .split(RegExp(r'\s+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(growable: false);

      for (final part in parts) {
        final sepIndex = part.contains('=')
            ? part.indexOf('=')
            : part.indexOf(':');
        if (sepIndex <= 0) continue;

        final key = part.substring(0, sepIndex).trim();
        final valueText = part.substring(sepIndex + 1).trim();
        if (key.isEmpty || valueText.isEmpty) continue;

        final parsed = double.tryParse(valueText.replaceAll(',', ''));
        if (parsed == null || parsed <= 0) continue;

        target[key] = (target[key] ?? 0) + parsed;
      }
    }
  }
}
