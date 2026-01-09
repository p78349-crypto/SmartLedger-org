import 'package:flutter/material.dart';
import '../utils/number_formats.dart';

class ZeroQuickButtons extends StatelessWidget {
  const ZeroQuickButtons({
    super.key,
    required this.controller,
    this.formatThousands = false,
    this.onChanged,
  });

  final TextEditingController controller;

  /// When true, formats the integer part with thousand separators
  /// (e.g., 123400 -> 123,400). Decimal part (if any) is preserved.
  final bool formatThousands;

  /// Optional callback after the controller text is updated.
  final VoidCallback? onChanged;

  void _append(String toAppend) {
    final current = controller.text;
    final selection = controller.selection;
    final start = selection.start < 0 ? current.length : selection.start;
    final end = selection.end < 0 ? current.length : selection.end;
    final insertedAtEnd = start == current.length && end == current.length;

    var nextText = current.replaceRange(start, end, toAppend);

    if (formatThousands) {
      // Keep digits and optional single leading minus / decimal part.
      String cleaned = nextText.replaceAll(RegExp(r'[^0-9.-]'), '');

      bool isNegative = false;
      if (cleaned.contains('-')) {
        cleaned = cleaned.replaceAll('-', '');
        isNegative = nextText.trimLeft().startsWith('-');
      }

      final parts = cleaned.split('.');
      final integerPart = parts.first.isEmpty ? '0' : parts.first;
      final decimalPart = parts.length > 1 ? parts.skip(1).join() : '';

      final intValue = int.tryParse(integerPart) ?? 0;
      final formattedInteger = NumberFormats.custom('#,###').format(intValue);

      final buffer = StringBuffer();
      if (isNegative) buffer.write('-');
      buffer.write(formattedInteger);
      if (decimalPart.isNotEmpty) buffer.write('.$decimalPart');

      nextText = buffer.toString();
    }

    controller
      ..text = nextText
      ..selection = TextSelection.collapsed(
        offset: insertedAtEnd
            ? nextText.length
            : (start + toAppend.length).clamp(0, nextText.length),
      );

    onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _append('00'),
            child: const Text('+00'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _append('0'),
            child: const Text('+0'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _append('000'),
            child: const Text('+000'),
          ),
        ),
      ],
    );
  }
}
