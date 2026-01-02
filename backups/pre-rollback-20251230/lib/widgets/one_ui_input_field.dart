import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One UI style input field - lightweight prototype.
class OneUiInputField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? suffixText;
  final bool obscureText;
  final bool autofocus;
  final bool compact;

  const OneUiInputField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.onFieldSubmitted,
    this.onChanged,
    this.maxLines,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.suffixText,
    this.obscureText = false,
    this.autofocus = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact && label != null) ...[
          Text(
            label!,
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F4F8), // Surface
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E3E7)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.04),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              if (prefixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: prefixIcon,
                ),
              ],
              Expanded(
                child: TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: autofocus,
                  validator: validator,
                  enabled: enabled,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  textInputAction: textInputAction,
                  onFieldSubmitted: onFieldSubmitted,
                  onChanged: onChanged,
                  maxLines: maxLines ?? 1,
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    hintText: hint,
                    suffixText: suffixText,
                    prefixIcon: prefixIcon == null ? null : Padding(
                      padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                      child: prefixIcon,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
              if (suffixIcon != null) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: suffixIcon,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

