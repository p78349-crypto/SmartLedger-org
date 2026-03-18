// ignore_for_file: invalid_use_of_protected_member

part of 'food_expiry_items_screen.dart';

/// Build helper for individual item list tiles.
extension FoodExpiryBuildItemTileExt on _FoodExpiryItemsScreenState {
  Widget buildItemTile(FoodExpiryItem it, ThemeData theme) {
    final displayName = it.name.trim().isEmpty ? '(이름 없음)' : it.name.trim();
    final left = it.daysLeft(DateTime.now());
    final leftText = left < 0
        ? '지남 ${-left}일'
        : '남음 $left'
              '일';
    final color = left < 0
        ? theme.colorScheme.error
        : (left <= 2 ? theme.colorScheme.tertiary : theme.colorScheme.primary);

    final isMatched =
        widget.initialIngredients?.any(
          (ing) =>
              it.name.contains(ing) ||
              ing.contains(it.name) ||
              it.category.contains(ing),
        ) ??
        false;

    final isItemUsageActive = _isUsageMode || _activeUsageItems.contains(it.id);

    return Container(
      color: isMatched
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
          : null,
      child: ListTile(
        onTap: () => _showItemDetail(context, it),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (it.category.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        it.category,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: !isItemUsageActive
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _adjustQuantity(context, it, -1.0),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: InkWell(
                            onTap: () => _editQuantity(context, it),
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                _formatQuantity(it),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                  decorationStyle: TextDecorationStyle.dotted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _adjustQuantity(context, it, 1.0),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '잔량: ${_formatQuantity(it)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        _UsageInput(
                          initialValue: _usageMap[it.id],
                          max: it.quantity,
                          unit: it.unit,
                          onChanged: (val) {
                            setState(() {
                              if (val == null || val <= 0) {
                                _usageMap.remove(it.id);
                              } else {
                                _usageMap[it.id] = val;
                              }
                            });
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
        subtitle: Text(
          _itemSubtitleText(it),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _isUsageMode
            ? null
            : SizedBox(
                width: 210,
                child: Row(
                  children: [
                    if (!isItemUsageActive)
                      Text(leftText, style: TextStyle(color: color)),
                    IconButton(
                      icon: Icon(
                        isItemUsageActive ? Icons.close : Icons.soup_kitchen,
                        size: 20,
                        color: isItemUsageActive
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                      tooltip: isItemUsageActive ? '입력 취소' : '사용량 입력',
                      onPressed: () => _toggleItemUsage(it.id),
                    ),
                    if (!isItemUsageActive) ...[
                      IconButton(
                        icon: const Icon(IconCatalog.shoppingCart),
                        tooltip: '장바구니 담기',
                        onPressed: () => _addToCart(context, it),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(
                          IconCatalog.deleteOutline,
                          color: theme.colorScheme.error,
                        ),
                        tooltip: '삭제',
                        onPressed: () => _confirmAndDeleteItem(it),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
