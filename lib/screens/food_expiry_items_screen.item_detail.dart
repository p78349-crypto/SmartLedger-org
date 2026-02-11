// ignore_for_file: invalid_use_of_protected_member

part of 'food_expiry_items_screen.dart';

/// Item detail dialog, UI state toggles, and delete confirmation.
extension FoodExpiryItemDetailExt on _FoodExpiryItemsScreenState {
  void _showItemDetail(BuildContext context, FoodExpiryItem item) {
    final theme = Theme.of(context);
    final left = item.daysLeft(DateTime.now());
    final leftColor = left < 0
        ? theme.colorScheme.error
        : (left <= 2 ? theme.colorScheme.tertiary : theme.colorScheme.primary);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(item.name)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('카테고리', item.category, Icons.category_outlined, theme),
            _detailRow(
              '보관위치',
              item.location,
              Icons.location_on_outlined,
              theme,
            ),
            _detailRow(
              '수량',
              '${_formatQuantity(item)} ${item.unit}',
              Icons.inventory_2_outlined,
              theme,
            ),
            _detailRow(
              '가격',
              '${CurrencyFormatter.format(item.price)}원',
              Icons.payments_outlined,
              theme,
            ),
            _detailRow(
              '구매처',
              item.supplier.isEmpty ? '-' : item.supplier,
              Icons.storefront_outlined,
              theme,
            ),
            const Divider(),
            _detailRow(
              '구매일',
              DateFormat('yyyy-MM-dd').format(item.purchaseDate),
              Icons.calendar_today_outlined,
              theme,
            ),
            _detailRow(
              '유통기한',
              '${DateFormat('yyyy-MM-dd').format(item.expiryDate)} ($left일 남음)',
              Icons.event_available_outlined,
              theme,
              valueColor: leftColor,
            ),
            if (item.memo.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '메모',
                style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(item.memo, style: theme.textTheme.bodyMedium),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onUpsert?.call(context, existing: item);
            },
            child: const Text('수정'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    IconData icon,
    ThemeData theme, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleUsageMode() {
    setState(() {
      _isUsageMode = !_isUsageMode;
      _usageMap.clear();
      _activeUsageItems.clear();
      _activeRecipeName = null;
    });
  }

  void _toggleItemUsage(String id) {
    setState(() {
      if (_activeUsageItems.contains(id)) {
        _activeUsageItems.remove(id);
        _usageMap.remove(id);
      } else {
        _activeUsageItems.add(id);
      }
    });
  }

  Future<void> _confirmAndDeleteItem(FoodExpiryItem item) async {
    final name = item.name.trim().isEmpty ? '(이름 없음)' : item.name.trim();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text("'$name' 항목을 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              '삭제',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FoodExpiryService.instance.deleteById(item.id);
    }
  }
}
