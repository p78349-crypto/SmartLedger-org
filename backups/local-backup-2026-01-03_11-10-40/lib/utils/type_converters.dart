/// Utility class for type conversions and parsing
class TypeConverters {
  TypeConverters._(); // Private constructor to prevent instantiation

  /// Parse a string to double, returning null if parsing fails
  static double? parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // Remove commas if present
      final cleaned = value.replaceAll(',', '').trim();
      try {
        return double.parse(cleaned);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Parse a currency-like string to double, handling both comma/dot
  /// grouping and decimal conventions. Removes non-numeric symbols.
  static double? parseCurrency(String? amountString) {
    if (amountString == null) return null;
    try {
      final raw = amountString.trim();

      // Remove any non-digit, non-separator, non-sign characters
      var cleaned = raw.replaceAll(RegExp(r'[^0-9,\.\-]'), '');
      if (cleaned.isEmpty) return null;

      final hasComma = cleaned.contains(',');
      final hasDot = cleaned.contains('.');

      if (hasComma && hasDot) {
        final lastComma = cleaned.lastIndexOf(',');
        final lastDot = cleaned.lastIndexOf('.');
        final decimalSep = (lastComma > lastDot) ? ',' : '.';
        final groupSep = (decimalSep == ',') ? '.' : ',';
        cleaned = cleaned.replaceAll(groupSep, '');
        cleaned = cleaned.replaceAll(decimalSep, '.');
      } else if (hasComma || hasDot) {
        final sep = hasComma ? ',' : '.';
        final parts = cleaned.split(sep);
        if (parts.length > 2) {
          // Multiple separators of the same kind: assume grouping
          cleaned = cleaned.replaceAll(sep, '');
        } else if (parts.length == 2) {
          final fracLen = parts[1].length;
          if (fracLen >= 1 && fracLen <= 2) {
            final integerPart = parts[0].replaceAll(sep, '');
            cleaned = '$integerPart.${parts[1]}';
          } else {
            cleaned = cleaned.replaceAll(sep, '');
          }
        }
      }

      return double.parse(cleaned);
    } catch (e) {
      return null;
    }
  }

  /// Parse a string to int, returning null if parsing fails
  static int? parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Remove commas if present
      final cleaned = value.replaceAll(',', '').trim();
      try {
        return int.parse(cleaned);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Parse a dynamic value to string safely
  static String parseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  /// Parse a dynamic value to bool safely
  static bool parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    if (value is int) return value != 0;
    return defaultValue;
  }

  /// Parse a dynamic value to DateTime safely
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Format a number as string with commas
  static String formatNumber(num value) {
    final formatter = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    return value.toString().replaceAllMapped(
      formatter,
      (match) => '${match.group(1)},',
    );
  }

  /// Convert list of strings to list of doubles, filtering nulls
  static List<double> parseDoubleList(List<dynamic> values) {
    return values
        .map(parseDouble)
        .where((v) => v != null)
        .cast<double>()
        .toList();
  }

  /// Convert list of strings to list of ints, filtering nulls
  static List<int> parseIntList(List<dynamic> values) {
    return values.map(parseInt).where((v) => v != null).cast<int>().toList();
  }

  /// Safely convert map values to specific types
  static Map<String, T> parseMap<T>(
    Map<dynamic, dynamic> source,
    T Function(dynamic) converter, {
    Map<String, T>? defaultValue,
  }) {
    try {
      final result = <String, T>{};
      source.forEach((key, value) {
        result[key.toString()] = converter(value);
      });
      return result;
    } catch (e) {
      return defaultValue ?? {};
    }
  }
}
