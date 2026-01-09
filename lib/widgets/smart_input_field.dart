import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Smart style input field - lightweight prototype.
class SmartInputField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final bool enabled;
  final bool readOnly;
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
  final FloatingLabelBehavior? floatingLabelBehavior;
  final TextAlign textAlign;

  const SmartInputField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
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
    this.floatingLabelBehavior,
    this.textAlign = TextAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final contentPadding = EdgeInsets.symmetric(
      horizontal: 16,
      vertical: compact ? (isLandscape ? 10 : 12) : (isLandscape ? 14 : 16),
    );

    final fillColor = scheme.brightness == Brightness.light
        ? scheme.surfaceContainerLow
        : scheme.surfaceContainerHighest.withValues(alpha: 0.5);

    final borderRadius = BorderRadius.circular(16);
    final subtleBorderColor = scheme.outlineVariant.withValues(
      alpha: scheme.brightness == Brightness.dark ? 0.7 : 0.5,
    );

    OutlineInputBorder subtleBorder({double width = 0.5}) => OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: subtleBorderColor, width: width),
    );

    final textColor = scheme.onSurface;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      validator: validator,
      enabled: enabled,
      readOnly: readOnly,
      textAlign: textAlign,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      maxLines: maxLines ?? 1,
      obscureText: obscureText,
      style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: fillColor,
        contentPadding: contentPadding,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        suffixText: suffixText,
        floatingLabelBehavior:
            floatingLabelBehavior ?? FloatingLabelBehavior.always,
        labelStyle: TextStyle(
          color: scheme.brightness == Brightness.dark
              ? scheme.onSurfaceVariant
              : scheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        border: subtleBorder(),
        enabledBorder: subtleBorder(),
        disabledBorder: subtleBorder(),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: scheme.error, width: 1.2),
        ),
      ),
    );
  }
}
