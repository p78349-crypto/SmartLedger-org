// ignore_for_file: invalid_use_of_protected_member
part of 'shopping_cart_screen.dart';

/// Extension: portrait item tile, field helper, and checked summary bar.
extension ShoppingCartPortraitTile on _ShoppingCartScreenState {
  // ── Helper: reusable column with label + TextField ──
  Widget _portraitFieldColumn({
    required ThemeData theme,
    required String label,
    required double width,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ShoppingCartItem item,
    Key? fieldKey,
    TextInputType keyboardType = TextInputType.number,
    TextInputAction textInputAction = TextInputAction.next,
    bool useLargeStyle = false,
    VoidCallback? onFieldSubmitted,
    VoidCallback? onEditingCompleteOverride,
    VoidCallback? onTapOutsideAction,
  }) {
    final style = useLargeStyle
        ? theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: _inlineFieldHeight,
            child: TextField(
              key: fieldKey,
              controller: controller,
              focusNode: focusNode,
              textAlign: useLargeStyle ? TextAlign.start : TextAlign.center,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              style: style,
              decoration: _inlineFieldDecoration(theme, ''),
              onChanged: (_) => _previewInlineEdits(item),
              onTapOutside: onTapOutsideAction != null
                  ? (_) => onTapOutsideAction()
                  : null,
              onSubmitted: (_) => onFieldSubmitted?.call(),
              onEditingComplete: () =>
                  (onEditingCompleteOverride ?? onFieldSubmitted)?.call(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitItemTile({
    required BuildContext context,
    required ThemeData theme,
    required ShoppingCartItem item,
    required int index,
    required List<ShoppingCartItem> ordered,
    required TextEditingController qtyController,
    required TextEditingController bundleSizeController,
    required TextEditingController unitController,
    required FocusNode qtyFocusNode,
    required FocusNode bundleSizeFocusNode,
    required FocusNode unitFocusNode,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        child: Container(
          color: item.isChecked
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row: checkbox + name + delete ──
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Transform.scale(
                          scale: 0.85,
                          child: Checkbox(
                            value: item.isChecked,
                            onChanged: (_) => _toggleChecked(item),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '삭제',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: () => _deleteItemWithUndo(item),
                      icon: const Icon(IconCatalog.deleteOutline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ── Fields row: price / qty / bundleSize / stock ──
                Row(
                  children: [
                    _portraitFieldColumn(
                      theme: theme,
                      label: '가격',
                      width: 140,
                      controller: unitController,
                      focusNode: unitFocusNode,
                      item: item,
                      fieldKey: ValueKey('sc_price_${item.id}'),
                      useLargeStyle: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onTapOutsideAction: () {
                        FocusScope.of(context).unfocus();
                        _applyInlineEdits(item);
                      },
                      onFieldSubmitted: () {
                        _applyInlineEdits(item);
                        qtyFocusNode.requestFocus();
                      },
                    ),
                    const SizedBox(width: 8),
                    _portraitFieldColumn(
                      theme: theme,
                      label: '수량',
                      width: 56,
                      controller: qtyController,
                      focusNode: qtyFocusNode,
                      item: item,
                      fieldKey: ValueKey('sc_qty_${item.id}'),
                      onFieldSubmitted: () {
                        _applyInlineEdits(item);
                        bundleSizeFocusNode.requestFocus();
                      },
                    ),
                    const SizedBox(width: 8),
                    _portraitFieldColumn(
                      theme: theme,
                      label: '개수',
                      width: 56,
                      controller: bundleSizeController,
                      focusNode: bundleSizeFocusNode,
                      item: item,
                      fieldKey: ValueKey('sc_units_${item.id}'),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: () {
                        _applyInlineEdits(item);
                        FocusScope.of(context).unfocus();
                      },
                      onEditingCompleteOverride: () => _applyInlineEdits(item),
                    ),
                    const SizedBox(width: 8),
                    // Stock display
                    SizedBox(
                      width: 50,
                      child: Column(
                        children: [
                          Text(
                            '재고',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: _inlineFieldHeight,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.teal,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              _getStockQuantity(item.name),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
