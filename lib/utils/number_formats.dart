import 'package:intl/intl.dart';
import 'currency_formatter.dart';

/// 공용 숫자/통화 포매터 모음.
class NumberFormats {
  NumberFormats._();

  /// Delegate to `CurrencyFormatter`'s NumberFormat to centralize
  /// locale-aware currency formatting.
  static NumberFormat get currency => CurrencyFormatter.currency;

  static NumberFormat get currencyCompactKo =>
      NumberFormat.compact(locale: 'ko');

  static NumberFormat custom(String pattern) => NumberFormat(pattern);
}
