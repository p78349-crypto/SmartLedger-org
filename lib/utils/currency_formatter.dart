import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_ledger/utils/pref_keys.dart';
import 'package:smart_ledger/utils/type_converters.dart';

/// 통화(금액) 포맷 관련 유틸리티 클래스
class CurrencyFormatter {
  // Private constructor to prevent instantiation
  CurrencyFormatter._();

  static String _locale() => Intl.getCurrentLocale();

  /// 통화 단위 맵
  static const Map<String, String> currencySymbols = {
    'KRW': '원',
    'USD': '\$',
    'EUR': '€',
    'JPY': '¥',
    'CNY': '¥',
    'GBP': '£',
  };

  /// 통화 코드별 한국어 이름
  static const Map<String, String> currencyNamesKo = {
    'KRW': '대한민국 원',
    'USD': '미국 달러',
    'EUR': '유로',
    'JPY': '일본 엔',
    'CNY': '중국 위안',
    'GBP': '영국 파운드',
  };

  /// 현재 설정된 통화 단위 가져오기 (동기)
  static String _cachedUnit = '원';

  /// 통화 단위 캐시 초기화
  static Future<void> initCurrencyUnit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currency = prefs.getString(PrefKeys.currency) ?? 'KRW';
      _cachedUnit = currencySymbols[currency] ?? '원';
    } catch (e) {
      _cachedUnit = '원';
    }
  }

  /// 기본 통화 포맷: #,##0 (로케일 그룹 구분자 적용)
  static NumberFormat _currency() => NumberFormat('#,##0', _locale());

  /// Backward-compatible accessor (do not cache; locale may change).
  static NumberFormat get currency => _currency();

  /// 소수점 포함 통화 포맷: #,##0.00 (로케일 적용)
  static NumberFormat _currencyWithDecimals() =>
      NumberFormat('#,##0.00', _locale());

  /// Backward-compatible accessor.
  static NumberFormat get currencyWithDecimals => _currencyWithDecimals();

  /// 간단한 숫자 포맷 (1K, 1M 등) - 로케일 적용
  static NumberFormat _compact() => NumberFormat.compact(locale: _locale());

  /// Backward-compatible accessor.
  static NumberFormat get compact => _compact();

  /// 금액을 통화 문자열로 포맷 (#,##0원)
  static String format(num amount, {bool showUnit = true}) {
    final formatted = _currency().format(amount);
    return showUnit ? '$formatted$_cachedUnit' : formatted;
  }

  /// 금액을 통화 문자열로 포맷 (소수점 포함)
  static String formatWithDecimals(num amount, {bool showUnit = true}) {
    final formatted = _currencyWithDecimals().format(amount);
    return showUnit ? '$formatted$_cachedUnit' : formatted;
  }

  /// 코드에 대응하는 한국어 통화명 반환 (없으면 코드 그대로 반환)
  static String nameKo(String code) => currencyNamesKo[code] ?? code;

  /// 금액을 부호와 함께 포맷 (+/-#,##0원)
  static String formatSigned(num amount, {bool showUnit = true}) {
    final formatted = _currency().format(amount.abs());
    final unit = showUnit ? _cachedUnit : '';

    if (amount > 0) {
      return '+$formatted$unit';
    } else if (amount < 0) {
      return '-$formatted$unit';
    } else {
      return '$formatted$unit';
    }
  }

  /// 지출액 포맷 (-#,##0원)
  static String formatOutflow(num amount, {bool showUnit = true}) {
    final formatted = _currency().format(amount.abs());
    final unit = showUnit ? _cachedUnit : '';
    return '-$formatted$unit';
  }

  /// 수입액 포맷 (+#,##0원)
  static String formatInflow(num amount, {bool showUnit = true}) {
    final formatted = _currency().format(amount.abs());
    final unit = showUnit ? _cachedUnit : '';
    return '+$formatted$unit';
  }

  /// 금액을 간단한 형식으로 포맷 (1.2만원, 3.5억원 등)
  static String formatCompact(num amount, {bool showUnit = true}) {
    final formatted = _compact().format(amount);
    return showUnit ? '$formatted$_cachedUnit' : formatted;
  }

  /// 문자열을 숫자로 파싱 (콤마 제거)
  static double? parse(String amountString) {
    return TypeConverters.parseCurrency(amountString);
  }

  /// 금액의 절대값 포맷
  static String formatAbs(num amount, {bool showUnit = true}) {
    return format(amount.abs(), showUnit: showUnit);
  }

  /// 천원 단위로 반올림하여 포맷
  static String formatRoundedToThousand(num amount, {bool showUnit = true}) {
    final rounded = (amount / 1000).round() * 1000;
    return format(rounded, showUnit: showUnit);
  }

  /// 만원 단위로 반올림하여 포맷
  static String formatRoundedToTenThousand(num amount, {bool showUnit = true}) {
    final rounded = (amount / 10000).round() * 10000;
    return format(rounded, showUnit: showUnit);
  }

  /// 퍼센트 포맷 (#.#%)
  static String formatPercent(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// 비율 계산 후 퍼센트 포맷
  static String formatRatio(
    num numerator,
    num denominator, {
    int decimals = 1,
  }) {
    if (denominator == 0) return '0%';
    final ratio = (numerator / denominator) * 100;
    return formatPercent(ratio, decimals: decimals);
  }

  /// 큰 금액을 읽기 쉽게 포맷 (한국어: 억/조 단위)
  /// 10억 미만은 천단위 콤마, 10억 이상은 한글 단위 사용
  static String formatLargeAmount(num value, {bool showUnit = false}) {
    final absValue = value.abs().toInt();

    String formatted;

    // 1조 이상
    if (absValue >= 1000000000000) {
      final jo = absValue ~/ 1000000000000; // 조
      final remainder = absValue % 1000000000000;
      final cheonEok = remainder ~/ 100000000000; // 천억

      if (cheonEok > 0) {
        formatted = '$jo조 $cheonEok천억';
      } else {
        formatted = '$jo조';
      }
    }
    // 10억 이상 1조 미만 - 한글 단위 사용
    else if (absValue >= 1000000000) {
      final eok = absValue ~/ 100000000; // 억
      final remainder = absValue % 100000000;
      final cheonman = remainder ~/ 10000000; // 천만

      if (cheonman > 0) {
        formatted = '$eok억 $cheonman천만';
      } else {
        formatted = '$eok억';
      }
    }
    // 10억 미만 - 천단위 콤마
    else {
      formatted = _currency().format(value);
    }

    return showUnit ? '$formatted$_cachedUnit' : formatted;
  }
}

