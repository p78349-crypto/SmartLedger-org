// ignore_for_file: invalid_use_of_protected_member
part of 'shopping_cart_screen.dart';

/// Extension: landscape (wide) item tile widget.
extension ShoppingCartWideTile on _ShoppingCartScreenState {
  Widget _buildWideItemTile({
    required BuildContext context,
    required ShoppingCartItem item,
    required TextEditingController qtyController,
    required TextEditingController bundleSizeController,
    required TextEditingController unitController,
    required TextEditingController memoController,
    required FocusNode qtyFocusNode,
    required FocusNode bundleSizeFocusNode,
    required FocusNode unitFocusNode,
    required FocusNode memoFocusNode,
    required ThemeData theme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      color: item.isChecked
          ? theme.colorScheme.primaryContainer
          : Colors.transparent,
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Center(
              child: Transform.scale(
                scale: 0.85,
                child: Checkbox(
                  value: item.isChecked,
                  onChanged: (_) => _toggleChecked(item),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            height: _inlineFieldHeight,
            child: TextField(
              key: ValueKey('sc_price_${item.id}'),
              controller: unitController,
              focusNode: unitFocusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: _inlineFieldDecoration(theme, '가격'),
              onChanged: (_) => _previewInlineEdits(item),
              onSubmitted: (_) => _applyInlineEdits(item),
              onEditingComplete: () => _applyInlineEdits(item),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            height: _inlineFieldHeight,
            child: TextField(
              key: ValueKey('sc_qty_${item.id}'),
              controller: qtyController,
              focusNode: qtyFocusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: _inlineFieldDecoration(theme, '수량'),
              onChanged: (_) => _previewInlineEdits(item),
              onSubmitted: (_) => _applyInlineEdits(item),
              onEditingComplete: () => _applyInlineEdits(item),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            height: _inlineFieldHeight,
            child: TextField(
              key: ValueKey('sc_units_${item.id}'),
              controller: bundleSizeController,
              focusNode: bundleSizeFocusNode,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: _inlineFieldDecoration(theme, '개수'),
              onChanged: (_) => _previewInlineEdits(item),
              onSubmitted: (_) => _applyInlineEdits(item),
              onEditingComplete: () => _applyInlineEdits(item),
            ),
          ),
          const SizedBox(width: 8),
          // 재고수량 표시
          SizedBox(
            width: 60,
            height: _inlineFieldHeight,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.teal, width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '재고',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 8,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    _getStockQuantity(item.name),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 위치 버튼 추가
          Tooltip(
            message: item.storeLocation.isEmpty
                ? '위치 입력'
                : '위치: ${item.storeLocation}',
            child: InkWell(
              onTap: () => _editItemLocation(item),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: item.storeLocation.isEmpty
                      ? theme.colorScheme.surfaceContainerHighest
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: item.storeLocation.isEmpty
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.primary,
                    ),
                    if (item.storeLocation.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        item.storeLocation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              CurrencyFormatter.format(
                item.unitPrice * (item.quantity < 0 ? 0 : item.quantity),
              ),
              textAlign: TextAlign.end,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            tooltip: '삭제',
            onPressed: () => _deleteItemWithUndo(item),
            icon: const Icon(IconCatalog.deleteOutline),
          ),
        ],
      ),
    );
  }
}
