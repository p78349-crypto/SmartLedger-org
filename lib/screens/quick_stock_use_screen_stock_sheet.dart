// ignore_for_file: invalid_use_of_protected_member
part of 'quick_stock_use_screen.dart';

/// Extension: stock-list bottom sheet, sorting, stock list tile.
extension QuickStockSheet on _QuickStockUseBodyState {
  /// 재고 목록 바텀시트 - 유통기한 임박순/자주 쓰는 순/재고 많은 순
  void _showStockListBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              final colorScheme = Theme.of(context).colorScheme;
              final items = ConsumableInventoryService.instance.items.value;

              // 정렬 옵션
              final sortOptions = ['유통기한 임박순', '자주 쓰는 순', '재고 많은 순', '이름순'];
              var selectedSort = '유통기한 임박순';

              // 정렬된 목록
              List<ConsumableInventoryItem> sortedItems = _sortItems(
                items,
                selectedSort,
              );

              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // 핸들
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    // 헤더
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            '재고 목록',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    // 정렬 옵션
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: sortOptions.map((option) {
                            final isSelected = selectedSort == option;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(option),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() {
                                      selectedSort = option;
                                      sortedItems = _sortItems(items, option);
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    // 목록
                    Expanded(
                      child: sortedItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 64,
                                    color: colorScheme.outline,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '등록된 재고가 없습니다',
                                    style: TextStyle(
                                      color: colorScheme.outline,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: sortedItems.length,
                              itemBuilder: (context, index) {
                                final item = sortedItems[index];
                                return _buildStockListTile(item, () {
                                  _selectItem(item);
                                  Navigator.pop(context);
                                });
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// 재고 목록 정렬
  List<ConsumableInventoryItem> _sortItems(
    List<ConsumableInventoryItem> items,
    String sortOption,
  ) {
    final now = DateTime.now();
    final sorted = [...items];

    switch (sortOption) {
      case '유통기한 임박순':
        // 생활용품은 유통기한이 없으므로 이름순 정렬
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case '자주 쓰는 순':
        sorted.sort((a, b) {
          // 최근 30일 사용 횟수 비교
          final thirtyDaysAgo = now.subtract(const Duration(days: 30));
          final aUsage = a.usageHistory
              .where((r) => r.timestamp.isAfter(thirtyDaysAgo))
              .length;
          final bUsage = b.usageHistory
              .where((r) => r.timestamp.isAfter(thirtyDaysAgo))
              .length;
          return bUsage.compareTo(aUsage);
        });
        break;
      case '재고 많은 순':
        sorted.sort((a, b) => b.currentStock.compareTo(a.currentStock));
        break;
      case '이름순':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return sorted;
  }

  /// 재고 목록 타일
  Widget _buildStockListTile(ConsumableInventoryItem item, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLow = item.currentStock <= item.threshold;
    final isEmpty = item.currentStock == 0;

    // 최근 사용 빈도
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentUsageCount = item.usageHistory
        .where((r) => r.timestamp.isAfter(thirtyDaysAgo))
        .length;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isEmpty
          ? Colors.red.shade50
          : null,
      child: ListTile(
        onTap: isEmpty ? null : onTap,
        leading: CircleAvatar(
          backgroundColor: isEmpty
              ? Colors.red
              : isLow
              ? Colors.orange
              : colorScheme.primaryContainer,
          child: isEmpty
              ? const Icon(Icons.warning, color: Colors.white, size: 18)
              : Text(
                  item.name.isNotEmpty ? item.name[0] : '?',
                  style: TextStyle(
                    color: isLow
                        ? Colors.white
                        : colorScheme.onPrimaryContainer,
                  ),
                ),
        ),
        title: Text(item.name),
        subtitle: Row(
          children: [
            Text(
              '재고: ${_formatQty(item.currentStock)}${item.unit}',
              style: TextStyle(
                color: isEmpty
                    ? Colors.red
                    : isLow
                    ? Colors.orange
                    : null,
                fontWeight: isEmpty || isLow ? FontWeight.bold : null,
              ),
            ),
            if (recentUsageCount > 0) ...[
              const SizedBox(width: 8),
              Icon(Icons.trending_up, size: 14, color: colorScheme.outline),
              Text(
                ' 최근 $recentUsageCount회',
                style: TextStyle(fontSize: 12, color: colorScheme.outline),
              ),
            ],
          ],
        ),
        trailing: isEmpty
            ? const Icon(Icons.block, color: Colors.red)
            : Icon(Icons.chevron_right, color: colorScheme.outline),
      ),
    );
  }
}
