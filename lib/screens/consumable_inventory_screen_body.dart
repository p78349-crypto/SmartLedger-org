// ignore_for_file: invalid_use_of_protected_member
part of 'consumable_inventory_screen.dart';

extension _BodyExt on _ConsumableInventoryScreenState {
  Widget _buildBody() {
    return ValueListenableBuilder<List<ConsumableInventoryItem>>(
      valueListenable: ConsumableInventoryService.instance.items,
      builder: (context, items, _) {
        final filteredItems = _locationFilter == '전체'
            ? items
            : items.where((e) => e.location == _locationFilter).toList();

        final expiryFilteredItems = _expiryFilter == '전체'
            ? filteredItems
            : _expiryFilter == '임박'
                ? filteredItems.where((e) => e.isExpiringWithin()).toList()
                : filteredItems.where((e) => e.isExpired()).toList();

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: _locationOptions.map((loc) {
                  final isSelected = _locationFilter == loc;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(loc),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _locationFilter = loc);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: _expiryOptions.map((opt) {
                  final isSelected = _expiryFilter == opt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(opt),
                      selected: isSelected,
                      onSelected: (_) {
                        setState(() => _expiryFilter = opt);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: expiryFilteredItems.isEmpty
                  ? Center(
                      child: Text(
                        _locationFilter == '전체'
                            ? _expiryFilter == '전체'
                                ? '등록된 항목이 없습니다.\n우측 상단 + 버튼으로 추가하세요.'
                                : '$_expiryFilter 항목이 없습니다.'
                            : '$_locationFilter에 등록된 항목이 없습니다.',
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: expiryFilteredItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildItemCard(expiryFilteredItems[index]);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildItemCard(ConsumableInventoryItem item) {
    final theme = Theme.of(context);
    final isLow = item.currentStock <= item.threshold;
    final isEmpty = item.currentStock <= 0;
    final accentColor = isEmpty
        ? theme.colorScheme.error
        : (isLow ? theme.colorScheme.tertiary : theme.colorScheme.primary);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isEmpty || isLow
              ? accentColor.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant,
          width: (isEmpty || isLow) ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
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
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '현재고: ${_formatQty(item.currentStock)}${item.unit}',
                  style: TextStyle(
                    fontSize: 16,
                    color: (isEmpty || isLow) ? accentColor : null,
                  ),
                ),
                const Spacer(),
                Text(
                  '알림 기준: ${_formatQty(item.threshold)}${item.unit} 이하',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (_isCountLikeUnit(item.unit)) ...[
                  FilledButton.tonal(
                    onPressed: () => _quickDecrementOne(item),
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
                  onPressed: () => _useItem(item),
                ),
                const SizedBox(width: 8),
                ActionButton(
                  icon: Icons.add,
                  label: '추가',
                  onPressed: () => _refillItem(item),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _sendToCart(item),
                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                  label: const Text('장바구니'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showEditItemDialog(item),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
