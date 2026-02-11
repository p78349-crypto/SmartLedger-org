// ignore_for_file: invalid_use_of_protected_member
part of 'shopping_cart_screen.dart';

/// Extension: inline editor helpers & apply/preview.
extension ShoppingCartInlineEdit on _ShoppingCartScreenState {
  String _unitPriceTextForInlineEditor(double unitPrice) {
    if (unitPrice <= 0) return '';
    return unitPrice == unitPrice.roundToDouble()
        ? CurrencyFormatter.format(unitPrice, showUnit: false)
        : CurrencyFormatter.formatWithDecimals(unitPrice, showUnit: false);
  }

  InputDecoration _inlineFieldDecoration(ThemeData theme, String hint) {
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    final borderColor = isDark
        ? scheme.outlineVariant.withValues(alpha: 0.6)
        : _inlineFieldBorderColor;
    final focusedBorderColor = isDark
        ? scheme.primary
        : _inlineFieldFocusedBorderColor;
    final fillColor = isDark
        ? scheme.surfaceContainerHighest.withValues(alpha: 0.6)
        : _inlineFieldFillColor;
    final hintColor = isDark
        ? scheme.onSurfaceVariant.withValues(alpha: 0.8)
        : scheme.onSurfaceVariant.withValues(alpha: 0.6);

    return InputDecoration(
      isDense: true,
      hintText: hint,
      filled: true,
      fillColor: fillColor,
      hintStyle: TextStyle(color: hintColor),
      border: OutlineInputBorder(
        borderRadius: _inlineFieldRadius,
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: _inlineFieldRadius,
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _inlineFieldRadius,
        borderSide: BorderSide(color: focusedBorderColor, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Future<void> _applyInlineEdits(ShoppingCartItem item) async {
    final bundleRaw = _qtyControllers[item.id]?.text.trim() ?? '';
    final perBundleRaw = _bundleSizeControllers[item.id]?.text.trim() ?? '';
    final unitRaw = _unitPriceControllers[item.id]?.text.trim() ?? '';
    final memoRaw = _memoControllers[item.id]?.text.trim() ?? item.memo;

    final parsedBundle = int.tryParse(bundleRaw);
    final parsedPerBundle = int.tryParse(perBundleRaw);
    final parsedUnit = CurrencyFormatter.parse(unitRaw);

    final nextBundle = (parsedBundle == null)
        ? item.bundleCount
        : (parsedBundle < 0 ? 0 : parsedBundle);
    final nextPerBundle = (parsedPerBundle == null)
        ? item.unitsPerBundle
        : (parsedPerBundle < 0 ? 0 : parsedPerBundle);
    final nextQty = nextBundle * nextPerBundle;
    final nextUnit = (parsedUnit == null) ? item.unitPrice : parsedUnit;
    final nextMemo = memoRaw;

    if (nextBundle == item.bundleCount &&
        nextPerBundle == item.unitsPerBundle &&
        nextUnit == item.unitPrice &&
        nextMemo == item.memo) {
      return;
    }

    final updated = item.copyWith(
      bundleCount: nextBundle,
      unitsPerBundle: nextPerBundle,
      quantity: nextQty,
      unitPrice: nextUnit,
      memo: nextMemo,
      updatedAt: DateTime.now(),
    );

    final next = _items.map((i) => i.id == item.id ? updated : i).toList();
    await _save(next);
  }

  void _previewInlineEdits(ShoppingCartItem item) {
    final bundleRaw = _qtyControllers[item.id]?.text.trim() ?? '';
    final perBundleRaw = _bundleSizeControllers[item.id]?.text.trim() ?? '';
    final unitRaw = _unitPriceControllers[item.id]?.text.trim() ?? '';
    final memoRaw = _memoControllers[item.id]?.text.trim() ?? item.memo;

    final parsedBundle = int.tryParse(bundleRaw);
    final parsedPerBundle = int.tryParse(perBundleRaw);
    final parsedUnit = CurrencyFormatter.parse(unitRaw);

    final nextBundle = (parsedBundle == null)
        ? item.bundleCount
        : (parsedBundle < 0 ? 0 : parsedBundle);
    final nextPerBundle = (parsedPerBundle == null)
        ? item.unitsPerBundle
        : (parsedPerBundle < 0 ? 0 : parsedPerBundle);
    final nextQty = nextBundle * nextPerBundle;
    final nextUnit = (parsedUnit == null) ? item.unitPrice : parsedUnit;
    final nextMemo = memoRaw;

    if (nextBundle == item.bundleCount &&
        nextPerBundle == item.unitsPerBundle &&
        nextUnit == item.unitPrice &&
        nextMemo == item.memo) {
      return;
    }

    final updated = item.copyWith(
      bundleCount: nextBundle,
      unitsPerBundle: nextPerBundle,
      quantity: nextQty,
      unitPrice: nextUnit,
      memo: nextMemo,
      updatedAt: DateTime.now(),
    );

    setState(() {
      _items = _items.map((i) => i.id == item.id ? updated : i).toList();
    });
  }
}
