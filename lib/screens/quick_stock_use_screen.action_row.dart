// ignore_for_file: invalid_use_of_protected_member
part of 'quick_stock_use_screen.dart';

/// Extension: primary action row (stock pill + ENT button).
extension QuickStockActionRow on _QuickStockUseBodyState {
  Widget _buildPrimaryActionRow() {
    final hasItem = _selectedItem != null;
    final stockText = hasItem
        ? '${_formatQty(_selectedItem!.currentStock)}${_selectedItem!.unit}'
        : '상품 선택';
    final pillRadius = BorderRadius.circular(8);
    const pillPadding = EdgeInsets.symmetric(vertical: 12, horizontal: 16);

    Widget buildPill({
      required Widget child,
      VoidCallback? onTap,
      EdgeInsetsGeometry? padding,
      bool isPrimary = false,
    }) {
      final enabled = onTap != null;
      final colorScheme = Theme.of(context).colorScheme;
      return Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: InkWell(
          onTap: onTap,
          borderRadius: pillRadius,
          child: Container(
            padding: padding ?? pillPadding,
            decoration: BoxDecoration(
              color: isPrimary
                  ? colorScheme.primary
                  : (enabled
                      ? colorScheme.surface
                      : colorScheme.surfaceContainerHighest),
              border: Border.all(
                width: 1.3,
                color: isPrimary ? colorScheme.primary : colorScheme.outline,
              ),
              borderRadius: pillRadius,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: child,
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: buildPill(
            onTap: hasItem
                ? () => _showStockInfo(stockText)
                : _showStockListBottomSheet,
            padding: pillPadding,
            child: Builder(
              builder: (context) {
                final colorScheme = Theme.of(context).colorScheme;
                return Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '현재고량 ',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface),
                      ),
                      TextSpan(
                        text: hasItem ? stockText : '상품 ...',
                        style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500,
                          color: hasItem
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant),
                      ),
                      if (hasItem)
                        TextSpan(
                          text: '  ⊖ ENT',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Focus(
            focusNode: _entButtonFocus,
            child: buildPill(
              onTap: hasItem ? _submit : null,
              padding: pillPadding,
              isPrimary: true,
              child: Builder(
                builder: (context) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return Center(
                    child: Text('ENT',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimary)),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
