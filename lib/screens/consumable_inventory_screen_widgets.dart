import 'package:flutter/material.dart';
import '../models/consumable_inventory_item.dart';
import 'consumable_inventory_widgets.dart';

/// 재사용 가능한 필터 칩 행
class ConsumableFilterChipRow extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsetsGeometry padding;

  const ConsumableFilterChipRow({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: options.map((opt) {
          final isSelected = selected == opt;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (_) => onSelected(opt),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 소모품 재고 항목 카드 위젯
class ConsumableItemCard extends StatelessWidget {
  final ConsumableInventoryItem item;
  final bool isCountLikeUnit;
  final String Function(double) formatQty;
  final VoidCallback? onQuickDecrement;
  final VoidCallback onUse;
  final VoidCallback onRefill;
  final VoidCallback onSendToCart;
  final VoidCallback onEdit;
  final bool isSelected;
  final ValueChanged<bool?>? onSelected;

  const ConsumableItemCard({
    super.key,
    required this.item,
    required this.isCountLikeUnit,
    required this.formatQty,
    this.onQuickDecrement,
    required this.onUse,
    required this.onRefill,
    required this.onSendToCart,
    required this.onEdit,
    this.isSelected = false,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isLow = item.currentStock <= item.threshold;
    final isEmpty = item.currentStock <= 0;
    final theme = Theme.of(context);
    final accentColor = isEmpty
        ? theme.colorScheme.error
        : (isLow ? theme.colorScheme.tertiary : theme.colorScheme.primary);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : (isEmpty || isLow
                  ? accentColor.withValues(alpha: 0.5)
                  : theme.colorScheme.outlineVariant),
          width: isSelected || isEmpty || isLow ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onSelected != null ? () => onSelected!(!isSelected) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, theme, isLow, isEmpty),
              const SizedBox(height: 8),
              _buildStockRow(theme, accentColor, isEmpty, isLow),
              const SizedBox(height: 16),
              _buildActionRow(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    bool isLow,
    bool isEmpty,
  ) {
    return Row(
      children: [
        if (onSelected != null) ...[
          Checkbox(
            value: isSelected,
            onChanged: onSelected,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '📍 ${item.location}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (isLow)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isEmpty
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isEmpty ? '재고 없음' : '재고 부족',
              style: TextStyle(
                color: isEmpty
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onTertiaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStockRow(
    ThemeData theme,
    Color accentColor,
    bool isEmpty,
    bool isLow,
  ) {
    return Row(
      children: [
        Text(
          '현재고: ${formatQty(item.currentStock)}${item.unit}',
          style: TextStyle(
            fontSize: 16,
            color: (isEmpty || isLow) ? accentColor : null,
          ),
        ),
        const Spacer(),
        Text(
          '알림 기준: ${formatQty(item.threshold)}${item.unit} 이하',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        if (isCountLikeUnit) ...[
          FilledButton.tonal(
            onPressed: onQuickDecrement,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.standard,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
            ),
            child: const Text(
              '-1',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
        ],
        ActionButton(
          icon: Icons.remove,
          label: '사용',
          onPressed: onUse,
        ),
        const SizedBox(width: 8),
        ActionButton(
          icon: Icons.add,
          label: '추가',
          onPressed: onRefill,
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: onSendToCart,
          icon: const Icon(Icons.shopping_cart_outlined, size: 18),
          label: const Text('장바구니'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: onEdit,
        ),
      ],
    );
  }
}
