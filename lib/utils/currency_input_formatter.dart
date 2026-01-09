import 'package:flutter/services.dart';
import 'number_formats.dart';

/// TextInputFormatter that adds thousand separators while typing currency.
class CurrencyInputFormatter extends TextInputFormatter {
  CurrencyInputFormatter({this.allowNegative = false});

  /// Whether to allow a leading negative sign.
  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text;
    if (rawText.isEmpty) {
      return const TextEditingValue();
    }

    // Keep digits and optional single leading minus / decimal part.
    String cleaned = rawText.replaceAll(RegExp(r'[^0-9.-]'), '');

    // Normalize minus sign usage.
    bool isNegative = false;
    if (cleaned.contains('-')) {
      cleaned = cleaned.replaceAll('-', '');
      if (allowNegative) {
        isNegative = rawText.trimLeft().startsWith('-');
      }
    }

    // Split integer/decimal and discard extra dots beyond the first.
    final parts = cleaned.split('.');
    final integerPart = parts.first.isEmpty ? '0' : parts.first;
    final decimalPart = parts.length > 1 ? parts.skip(1).join() : '';

    final intValue = int.tryParse(integerPart) ?? 0;
    final formattedInteger = NumberFormats.custom('#,###').format(intValue);

    final buffer = StringBuffer();
    if (isNegative) buffer.write('-');
    buffer.write(formattedInteger);
    if (decimalPart.isNotEmpty) buffer.write('.$decimalPart');

    final formatted = buffer.toString();

    // Keep cursor position relative to the end of the string.
    final selectionFromEnd = rawText.length - newValue.selection.end;
    final offset = (formatted.length - selectionFromEnd).clamp(
      0,
      formatted.length,
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
