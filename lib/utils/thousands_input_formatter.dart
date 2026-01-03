import 'package:flutter/services.dart';
import 'package:smart_ledger/utils/currency_input_formatter.dart';

/// 숫자만 허용하며 천 단위 콤마를 추가하는 입력 포매터.
///
/// 내부적으로 `CurrencyInputFormatter`의 정수형 포맷 로직을 재사용합니다.
class ThousandsInputFormatter extends TextInputFormatter {
  const ThousandsInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Delegate to CurrencyInputFormatter but ensure decimals are removed
    final delegate = CurrencyInputFormatter();
    final formatted = delegate.formatEditUpdate(oldValue, newValue);

    // Remove decimal part if any (ThousandsInputFormatter is integer-only)
    final text = formatted.text;
    final dotIndex = text.indexOf('.');
    final integerOnly = dotIndex >= 0 ? text.substring(0, dotIndex) : text;

    return TextEditingValue(
      text: integerOnly,
      selection: TextSelection.collapsed(offset: integerOnly.length),
    );
  }
}
